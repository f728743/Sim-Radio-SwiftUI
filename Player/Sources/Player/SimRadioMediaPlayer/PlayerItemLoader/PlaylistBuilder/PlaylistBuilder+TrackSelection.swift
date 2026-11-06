//
//  PlaylistBuilder+TrackSelection.swift
//  Player
//

import MediaLibrary
import SharedUtilities

typealias DrawPools = [DrawPoolID: NonRepeatingRandomizer<DereferencedTruck>]
enum DrawPoolID: Hashable {
    case fragment(SimRadioDTO.Fragment.ID)
    case voiceOver(SimRadioDTO.VoiceOver.ID)
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
            if dereferencedTruckIDs.contains(truck.id) {
                continue
            }
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

extension PlaylistBuilder {
    func populateDrawPools() throws {
        guard drawPools.isEmpty else { return }
        let rules = station.playlistRules
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

    private func pickTrack(
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
            return try pickTrack(
                from: introIDs,
                among: introTrackLists,
                generator: &generator
            ).dereference(trackLists: trackLists)
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

    private func pickTrack(
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
