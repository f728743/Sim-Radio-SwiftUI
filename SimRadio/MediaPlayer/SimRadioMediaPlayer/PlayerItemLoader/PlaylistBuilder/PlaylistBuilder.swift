//
//  PlaylistBuilder.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 07.07.2025.
//

// swiftlint:disable file_length

import AVFoundation

typealias DrawPools = [DrawPoolID: NonRepeatingRandomizer<DereferencedTruck>]
enum DrawPoolID: Hashable {
    case fragment(SimRadioDTO.Fragment.ID)
    case voiceOver(SimRadioDTO.VoiceOver.ID)
}

class PlaylistBuilder {
    enum PlaylistMode {
        case alternate(TimeInterval)
        case option(SimRadioDTO.SourceOption.ID)
    }

    var drawPools: DrawPools = [:]
    var trackLists: [TrackList.ID: TrackList] = [:]
    var fragments: [SimRadioDTO.Fragment.ID: SimRadioDTO.Fragment] = [:]
    let stationData: SimRadioStationData
    var playlistСache: [Date: [PlaylistItem]] = [:]

    init(stationData: SimRadioStationData) {
        self.stationData = stationData
    }

    /// Generates a single `PlaylistItem` starting at the specified date and time offset within that day.
    /// - Parameters:
    ///   - playlistStartDate: The date on which the playlist item should start.
    ///   - timeOffsetInFirstDay: The time offset within the start date's day, in seconds, where the item begins.
    /// - Returns: A `PlaylistItem` representing the audio segment and its associated mixes,
    /// adjusted to start at the specified offset.
    /// - Throws: `PlaylistGenerationError.makeDailyPlaylistError` if no valid item is found
    /// for the given date and time or if the item's duration is invalid.
    func makePlaylistItem(
        startingOn playlistStartDate: Date,
        at timeOffsetInFirstDay: CMTime,
        mode: PlaylistMode?
    ) async throws -> PlaylistItem {
        let currentDate = playlistStartDate.startOfDay
        let dailyItems = try await makeDailyPlaylist(for: currentDate, mode: mode)
        print(dailyItems.description)

        // Find the first item that is relevant (i.e., its playing end time is after the timeOffsetInFirstDay)
        guard let relevantItem = dailyItems.first(where: { $0.track.playing.end > timeOffsetInFirstDay }) else {
            throw PlaylistGenerationError.makeDailyPlaylistError(date: currentDate)
        }

        throw PlaylistGenerationError.makePlaylistError
    }
}

extension SimRadioStationData {
    func tracks(trackListIDs: [TrackList.ID]) throws -> [DereferencedTruck] {
        let tracks = try trackListIDs.flatMap { trackListID in
            guard let selectedTrackLists = trackLists.first(where: { $0.id == trackListID }) else {
                throw PlaylistGenerationError.trackListNotFound(id: trackListID)
            }
            return selectedTrackLists.tracks
        }
        var truckIntros: [Track.ID: [Track.ID]] = [:]
        for track in tracks where track.intro?.isEmpty == false {
            truckIntros[track.id, default: []].append(contentsOf: track.intro ?? [])
        }
        let trackListDictionary = Dictionary(uniqueKeysWithValues: trackLists.map { ($0.id, $0) })
        var dereferencedTruckIDs: Set<Track.ID> = []
        var dereferencedTrucks: [DereferencedTruck] = []
        for truck in tracks {
            if dereferencedTruckIDs.contains(truck.id) { continue }
            let truckIntros = (truckIntros[truck.id] ?? []).unique()
            let dereferencedTruck = try truck.dereference(
                trackLists: trackListDictionary,
                referenceIntro: truckIntros.isEmpty ? nil : truckIntros
            )
            dereferencedTrucks.append(dereferencedTruck)
            dereferencedTruckIDs.insert(truck.id)
        }
        return dereferencedTrucks
    }
}

private extension PlaylistBuilder {
    var station: SimStation { stationData.station }

    func makeDailyPlaylist(
        for date: Date,
        mode: PlaylistMode?
    ) async throws -> [PlaylistItem] {
        if let cached = playlistСache[date] {
            return cached
        }
        var generator: any RandomNumberGenerator = SplitMix64(seed: UInt64(date.startOfDay.timeIntervalSince1970))
        let playlist = try await makePlaylist(
            duration: .init(seconds: .fullDayDuration),
            mode: mode,
            generator: &generator
        )
        return playlist
    }

    func populateHelperDictionaries() throws {
        try populateDrawPools()
        trackLists = Dictionary(uniqueKeysWithValues: stationData.trackLists.map { ($0.id, $0) })
        let fragments = stationData.station.playlistRules?.fragments ?? []
        guard !fragments.isEmpty else {
            throw PlaylistGenerationError.makePlaylistError
        }
        self.fragments = Dictionary(uniqueKeysWithValues: fragments.map { ($0.id, $0) })
    }

    func populateDrawPools() throws {
        guard drawPools.isEmpty, let rules = station.playlistRules else { return }
        let fragments: [(DrawPoolID, [SimRadioDTO.TrackList.ID])] = rules.fragments.compactMap {
            guard let trackLists = $0.src.trackLists else { return nil }
            return (.fragment($0.id), trackLists)
        }
        let voiceOveres: [(DrawPoolID, [SimRadioDTO.TrackList.ID])] = rules
            .fragments
            .compactMap(\.voiceOver)
            .flatMap(\.self)
            .compactMap {
                guard let trackLists = $0.src.trackLists else { return nil }
                return (.voiceOver($0.id), trackLists)
            }

        let drawPoolTuples: [(DrawPoolID, NonRepeatingRandomizer<DereferencedTruck>)] = try (fragments + voiceOveres)
            .compactMap { id, trackListIDs in
                let tracks = try stationData.tracks(
                    trackListIDs: trackListIDs.map {
                        TrackList.ID(series: stationData.station.id.series, value: $0.value)
                    }
                )
                if tracks.count < 2 {
                    return nil
                }
                guard let drawPool = NonRepeatingRandomizer(
                    elements: tracks,
                    avoidRepeatsRatio: 3.0 / 7.0
                ) else {
                    throw PlaylistGenerationError.invalidDrawPool(trackListIDs: trackListIDs)
                }
                return (id, drawPool)
            }
        drawPools = Dictionary(uniqueKeysWithValues: drawPoolTuples)
    }

    func firstOption(for mode: PlaylistMode?) -> SimRadioDTO.SourceOption.ID? {
        switch mode {
        case .alternate:
            if let firstOption = station.playlistRules?.options?.available.first {
                firstOption.id
            } else {
                nil
            }
        case let .option(optionID):
            optionID
        case .none:
            nil
        }
    }

    func option(at moment: CMTime, for mode: PlaylistMode?) -> SimRadioDTO.SourceOption.ID? {
        guard let mode else { return nil }

        switch mode {
        case let .option(optionID):
            return optionID

        case let .alternate(interval):
            guard let options = station.playlistRules?.options, !options.available.isEmpty else {
                return nil
            }
            guard interval > 0 else {
                return options.available.first?.id
            }
            let intervalCount = Int(moment.seconds / interval)
            let optionIndex = intervalCount % options.available.count
            return options.available[optionIndex].id
        }
    }

    func makePlaylist(
        duration: CMTime,
        mode: PlaylistMode?,
        generator: inout RandomNumberGenerator
    ) async throws -> [PlaylistItem] {
        try populateHelperDictionaries()
        var result: [PlaylistItem] = []
        var moment: CMTime = .zero
        var fragmentID = try firstFragmentID(mode: mode)

        var next = try await nextFragmentID(
            after: fragmentID,
            option: firstOption(for: mode),
            generator: &generator
        )
        while moment < duration {
            let playlistItem = try await makePlaylistItem(
                fragmentID: fragmentID,
                nextTag: next,
                starts: moment,
                generator: &generator
            )
            result.append(playlistItem)
            moment += playlistItem.track.playing.duration
            fragmentID = next
            next = try await nextFragmentID(
                after: fragmentID,
                option: option(at: moment, for: mode),
                generator: &generator
            )
        }
        return result
    }

    func makePlaylistItem(
        fragmentID: SimRadioDTO.Fragment.ID,
        nextTag: SimRadioDTO.Fragment.ID,
        starts sec: CMTime,
        generator: inout RandomNumberGenerator
    ) async throws -> PlaylistItem {
        guard let fragment = fragments[fragmentID] else {
            throw PlaylistGenerationError.fragmentNotFound(id: fragmentID)
        }

        guard let track = try pickTrack(fragment: fragment, generator: &generator)
        else {
            throw PlaylistGenerationError.wrongSource
        }
        let mixes = try await makeMixes(
            fragment: fragment,
            track: track,
            nextFragmentID: nextTag,
            starts: sec,
            positions: station.playlistRules?.positions ?? [],
            generator: &generator
        )

        let url = stationData.isDownloaded ? track.localFileURL : track.url
        return PlaylistItem(
            track: AudioSegment(
                url: url,
                timeRange: .init(
                    start: .init(seconds: track.start ?? 0),
                    duration: .init(seconds: track.duration)
                ),
                startTime: sec
            ),
            mixes: mixes
        )
    }

    func firstFragmentID(mode: PlaylistMode?) throws -> SimRadioDTO.Fragment.ID {
        guard let rules = station.playlistRules,
              let firstFragment = rules.firstFragment.first?.fragment
        else {
            throw PlaylistGenerationError.firstFragmentNotFound
        }
        switch mode {
        case .alternate:
            return firstFragment
        case let .option(optionID):
            guard let transition = rules.firstFragment.first(where: { $0.option == optionID }) else {
                throw PlaylistGenerationError.firstFragmentNotFound
            }
            return transition.fragment
        case .none:
            return firstFragment
        }
    }

    func nextFragmentID(
        after fragmentID: SimRadioDTO.Fragment.ID,
        option: SimRadioDTO.SourceOption.ID?,
        generator: inout RandomNumberGenerator
    ) async throws -> SimRadioDTO.Fragment.ID {
        guard let fragment = fragments[fragmentID] else {
            throw PlaylistGenerationError.fragmentNotFound(id: fragmentID)
        }
        let rnd = Double.random(in: 0 ... 1, using: &generator)
        var p = 0.0
        for next in fragment.next {
            if let option, let nextOption = next.option, option != nextOption { continue }
            p += next.probability ?? 1.0
            if rnd <= p {
                return next.fragment
            }
        }
        throw PlaylistGenerationError.notExhaustiveFragment(id: fragmentID)
    }

    // swiftlint:disable:next function_parameter_count
    func makeMixes(
        fragment: SimRadioDTO.Fragment,
        track: DereferencedTruck,
        nextFragmentID: SimRadioDTO.Fragment.ID,
        starts sec: CMTime,
        positions: [SimRadioDTO.VoiceOverPosition],
        generator: inout RandomNumberGenerator
    ) async throws -> [AudioSegment] {
        var usedPositions: Set<SimRadioDTO.VoiceOverPosition.ID> = []
        var res: [AudioSegment] = []
        for mix in fragment.voiceOver ?? [] where try mix.condition.isSatisfied(
            nextFragmentID: nextFragmentID,
            startingFrom: sec,
            generator: &generator
        ) {
            for positionID in mix.positions {
                if usedPositions.contains(positionID) {
                    continue
                }

                guard let pos = positions.first(where: { $0.id == positionID }) else {
                    throw PlaylistGenerationError.invalidPosition(id: positionID)
                }

                let mixTrack = try pickTrack(
                    parentTrack: track,
                    voiceOver: mix,
                    generator: &generator
                )

                if let mixTrack {
                    let t = track.duration - mixTrack.duration
                    let mixStartsSec = sec + .init(seconds: t * pos.relativeOffset)
                    res.append(AudioSegment(
                        url: mixTrack.url(local: stationData.isDownloaded),
                        timeRange: .init(
                            start: .init(seconds: mixTrack.start ?? 0),
                            duration: .init(seconds: mixTrack.duration)),
                        startTime: mixStartsSec
                    ))
                    usedPositions.insert(pos.id)
                    break
                }
            }
        }
        return res.sorted { $0.playing.start < $1.playing.start }
    }

    func pickTrack(
        fragment: SimRadioDTO.Fragment,
        generator: inout RandomNumberGenerator
    ) throws -> DereferencedTruck? {
        try pickTrack(
            src: fragment.src,
            parentTrack: nil,
            drawPoolID: .fragment(fragment.id),
            generator: &generator
        )
    }

    func pickTrack(
        parentTrack: DereferencedTruck,
        voiceOver: SimRadioDTO.VoiceOver,
        generator: inout RandomNumberGenerator
    ) throws -> DereferencedTruck? {
        try pickTrack(
            src: voiceOver.src,
            parentTrack: parentTrack,
            drawPoolID: .voiceOver(voiceOver.id),
            generator: &generator
        )
    }

    func pickTrack(
        src: SimRadioDTO.FragmentSource,
        parentTrack: DereferencedTruck?,
        drawPoolID: DrawPoolID,
        generator: inout RandomNumberGenerator
    ) throws -> DereferencedTruck? {
        switch src.type {
        case .trackLists:
            return drawPools[drawPoolID]?.next(generator: &generator)
        case .intro:
            if parentTrack?.intro?.isEmpty ?? true {
                return nil
            }
            guard let parentTrack,
                  let introIDs = parentTrack.intro,
                  let introTrackListsIDs = src.introTrackLists,
                  !introTrackListsIDs.isEmpty,
                  !introIDs.isEmpty
            else {
                throw PlaylistGenerationError.invalidSource(src: src)
            }
            let introTrackLists = introTrackListsIDs.map {
                TrackList.ID(
                    series: parentTrack.id.series,
                    value: $0.value
                )
            }
            let result = try pickTrack(
                from: introIDs,
                among: introTrackLists,
                generator: &generator
            ).dereference(trackLists: trackLists)
            return result
        case .track:
            let seriesID = station.id.series
            guard let trackListsID = src.trackLists?.first,
                  let trackID = src.track,
                  let trackList = trackLists[.init(series: seriesID, value: trackListsID.value)],
                  let track = trackList.tracks.first(where: { $0.id == .init(series: seriesID, value: trackID.value) })
            else {
                throw PlaylistGenerationError.invalidSource(src: src)
            }
            return try track.dereference(trackLists: trackLists)
        default:
            return nil
        }
    }

    func pickTrack(
        from trackIDs: [Track.ID],
        among trackListsIDs: [TrackList.ID],
        generator: inout RandomNumberGenerator
    ) throws -> Track {
        let trackID = trackIDs[Int.random(in: 0 ..< trackIDs.count, using: &generator)]
        for trackListsID in trackListsIDs {
            if let track = trackLists[trackListsID]?.tracks.first(where: { $0.id == trackID }) {
                return track
            }
        }
        throw PlaylistGenerationError.trackIntroNotFound(trackIDs: trackIDs, trackListsIDs: trackListsIDs)
    }
}

extension SimRadioDTO.Condition {
    func isSatisfied(
        nextFragmentID: SimRadioDTO.Fragment.ID,
        startingFrom second: CMTime,
        generator: inout RandomNumberGenerator
    ) throws -> Bool {
        let nextFragmentSatisfied = nextFragment == nil ?
            true : nextFragment == nextFragmentID

        let probabilitySatisfied = probability == nil ?
            true : Double.random(in: 0 ... 1, using: &generator) >= probability!

        let timeIntervalSatisfied = timeInterval == nil ?
            true : try timeInterval!.contains(second)

        return nextFragmentSatisfied && probabilitySatisfied && timeIntervalSatisfied
    }
}

extension SimRadioDTO.TimeInterval {
    func contains(_ second: CMTime) throws -> Bool {
        guard let from = secOfDay(hhmm: from),
              let to = secOfDay(hhmm: to)
        else {
            throw PlaylistGenerationError.invalidTimeInterval(from: from, to: to)
        }
        return CMTime(seconds: from) <= second && second <= CMTime(seconds: to)
    }
}

enum SourceType {
    case trackLists
    case intro
    case track
}

extension SimRadioDTO.FragmentSource {
    var type: SourceType? {
        if trackLists != nil, track == nil, introTrackLists == nil {
            .trackLists
        } else if trackLists != nil, track != nil, introTrackLists == nil {
            .track
        } else if trackLists == nil, track == nil, introTrackLists != nil {
            .intro
        } else {
            nil
        }
    }
}

extension SimRadioDTO.Playlist {
    var defaultMode: PlaylistBuilder.PlaylistMode? {
        guard let options, options.available.isEmpty == false else { return nil }
        if let interval = options.alternateInterval {
            return .alternate(interval)
        }
        return options.available.first.map { .option($0.id) }
    }
}

// swiftlint:enable file_length
