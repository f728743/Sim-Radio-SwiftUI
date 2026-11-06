//
//  PlaylistBuilder.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 07.07.2025.
//

import AVFoundation
import MediaLibrary
import SharedUtilities

@MainActor
final class PlaylistBuilder {
    enum PlaylistMode: Hashable {
        case alternate(TimeInterval)
        case option(SimRadioDTO.SourceOption.ID)
    }

    var drawPools: DrawPools = [:]
    var trackLists: [TrackList.ID: TrackList] = [:]
    var fragments: [SimRadioDTO.Fragment.ID: SimRadioDTO.Fragment] = [:]
    let stationData: SimRadioStationData

    var station: SimStation {
        stationData.station
    }

    private struct CacheKey: Hashable {
        let date: Date
        let mode: PlaylistMode?
    }

    private var playlistCache: [CacheKey: [PlaylistItem]] = [:]

    init(stationData: SimRadioStationData) {
        self.stationData = stationData
    }

    /// Generates a single `PlaylistItem` starting at the specified date and time offset within that day.
    /// - Parameters:
    ///   - playlistStartDate: The date on which the playlist item should start.
    ///   - timeOffsetInFirstDay: The time offset within the start date's day, in seconds, where the item begins.
    /// - Returns: A `PlaylistItem` representing the audio fragment and its associated mixes,
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
        // Find the first item that is relevant (i.e., its playing end time is after the timeOffsetInFirstDay)
        guard let relevantItem = dailyItems.first(where: { $0.track.playing.end > timeOffsetInFirstDay }) else {
            throw PlaylistGenerationError.makeDailyPlaylistError(date: currentDate)
        }
        let itemFileTimeRange = trimmedTimeRange(for: relevantItem.track, at: timeOffsetInFirstDay)
        let parentOriginalStartTimeInDay = relevantItem.track.startTime
        let itemStartTimeInOutput: CMTime = .zero // Single item, start at 0 in output

        let parentActualStartTimeInDay = parentOriginalStartTimeInDay +
            (itemFileTimeRange.start - relevantItem.track.timeRange.start)
        let parentActualEndTimeInDay = parentActualStartTimeInDay + itemFileTimeRange.duration

        // Adjust mixes to align with the trimmed track
        let adjustedMixes: [AudioFragment] = relevantItem.mixes.compactMap { originalMix in
            originalMix.adjustedMix(
                parentActualStartTimeInDay: parentActualStartTimeInDay,
                parentActualEndTimeInDay: parentActualEndTimeInDay,
                itemStartTimeInOutput: itemStartTimeInOutput
            )
        }
        let markers = relevantItem.track.markers.map {
            adjustMarkers(for: itemFileTimeRange, from: $0)
        }
        return PlaylistItem(
            track: AudioFragment(
                url: relevantItem.track.url,
                timeRange: itemFileTimeRange,
                startTime: itemStartTimeInOutput,
                markers: markers,
            ),
            mixes: adjustedMixes
        )
    }
}

private extension PlaylistBuilder {
    func trimmedTimeRange(for track: AudioFragment, at timeOffsetInFirstDay: CMTime) -> CMTimeRange {
        var itemFileTimeRange = track.timeRange
        var itemPlayableDuration = track.timeRange.duration
        let parentOriginalStartTimeInDay = track.startTime

        // Adjust for the time offset within the item
        if timeOffsetInFirstDay > parentOriginalStartTimeInDay {
            let offsetIntoItem = timeOffsetInFirstDay - parentOriginalStartTimeInDay
            let newDuration = max(.zero, track.timeRange.duration - offsetIntoItem)
            itemPlayableDuration = newDuration
            itemFileTimeRange = CMTimeRange(
                start: track.timeRange.start + offsetIntoItem,
                duration: itemPlayableDuration
            )
        }
        let remainingInDayDuration = max(
            .zero,
            .fullDayDuration - parentOriginalStartTimeInDay - itemFileTimeRange.start
        )
        let actualDurationToAdd = min(itemPlayableDuration, remainingInDayDuration)
        if actualDurationToAdd < itemPlayableDuration {
            itemFileTimeRange = CMTimeRange(
                start: itemFileTimeRange.start,
                duration: actualDurationToAdd
            )
        }
        return itemFileTimeRange
    }

    func adjustMarkers(for timeRange: CMTimeRange, from markers: [AudioFragmentMarker]) -> [AudioFragmentMarker] {
        guard !markers.isEmpty else { return [] }
        let startIndex = markers.lastIndex(where: { $0.offset <= timeRange.start }) ?? 0
        let relevantMarkers = markers.suffix(from: startIndex)
        return relevantMarkers.map { marker in
            let offset = marker.offset - timeRange.start
            return .init(
                offset: offset < .zero ? .zero : offset,
                value: marker.value
            )
        }
    }

    func makeDailyPlaylist(
        for date: Date,
        mode: PlaylistMode?
    ) async throws -> [PlaylistItem] {
        try Task.checkCancellation()
        let key = CacheKey(date: date, mode: mode)
        if let cached = playlistCache[key] {
            return cached
        }
        var generator: any RandomNumberGenerator = SplitMix64(seed: UInt64(date.startOfDay.timeIntervalSince1970))
        drawPools.removeAll()
        let playlist = try await makePlaylist(
            duration: .init(seconds: .fullDayDuration),
            mode: mode,
            generator: &generator
        )
        if playlistCache.count >= 2 {
            playlistCache.removeAll()
        }
        playlistCache[key] = playlist
        return playlist
    }

    func populateHelperDictionaries() throws {
        try populateDrawPools()
        trackLists = Dictionary(uniqueKeysWithValues: stationData.trackLists.map { ($0.id, $0) })
        let fragments = stationData.station.playlistRules.fragments
        guard !fragments.isEmpty else {
            throw PlaylistGenerationError.makePlaylistError
        }
        self.fragments = Dictionary(uniqueKeysWithValues: fragments.map { ($0.id, $0) })
    }

    func firstOption(for mode: PlaylistMode?) -> SimRadioDTO.SourceOption.ID? {
        switch mode {
        case .alternate:
            if let firstOption = station.playlistRules.options?.available.first {
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
            guard let options = station.playlistRules.options, !options.available.isEmpty else {
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
            try Task.checkCancellation()
            let playlistItem = try await makePlaylistItem(
                fragmentID: fragmentID,
                nextTag: next,
                starts: moment,
                generator: &generator
            )
            guard playlistItem.track.playing.duration.seconds.isFinite,
                  playlistItem.track.playing.duration > .zero
            else {
                throw PlaylistGenerationError.invalidFragment(id: fragmentID)
            }
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
            generator: &generator
        )

        let url = stationData.isDownloaded ? track.localFileURL : track.url
        return PlaylistItem(
            track: AudioFragment(
                url: url,
                timeRange: .init(
                    start: .init(seconds: track.start ?? 0),
                    duration: .init(seconds: track.duration)
                ),
                startTime: sec,
                markers: (track.markers?.track).map { trackMarkers in
                    trackMarkers.map { .init(dto: $0) }
                }
            ),
            mixes: mixes
        )
    }

    func firstFragmentID(mode: PlaylistMode?) throws -> SimRadioDTO.Fragment.ID {
        let rules = station.playlistRules
        guard let firstFragment = rules.firstFragment.first?.fragment
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
            if let option, let nextOption = next.option, option != nextOption {
                continue
            }
            p += next.probability ?? 1.0
            if rnd <= p {
                return next.fragment
            }
        }
        throw PlaylistGenerationError.notExhaustiveFragment(id: fragmentID)
    }

    func makeMixes(
        fragment: SimRadioDTO.Fragment,
        track: DereferencedTruck,
        nextFragmentID: SimRadioDTO.Fragment.ID,
        starts sec: CMTime,
        generator: inout RandomNumberGenerator
    ) async throws -> [AudioFragment] {
        let positions = station.playlistRules.positions ?? []
        var usedPositions: Set<SimRadioDTO.VoiceOverPosition.ID> = []
        var res: [AudioFragment] = []
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
                    res.append(AudioFragment(
                        url: mixTrack.url(local: stationData.isDownloaded),
                        timeRange: .init(
                            start: .init(seconds: mixTrack.start ?? 0),
                            duration: .init(seconds: mixTrack.duration)
                        ),
                        startTime: mixStartsSec,
                        markers: nil
                    ))
                    usedPositions.insert(pos.id)
                    break
                }
            }
        }
        return res.sorted { $0.playing.start < $1.playing.start }
    }
}
