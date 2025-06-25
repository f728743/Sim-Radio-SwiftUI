//
//  NewModelSimRadioMedia.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 24.06.2025.
//

import Foundation

struct NewModelSimRadioMedia {
    let series: [NewModelSimGameSeries.ID: NewModelSimGameSeries]
    let trackLists: [NewModelTrackList.ID: NewModelTrackList]
    let stations: [NewModelSimStation.ID: NewModelSimStation]
}

extension NewModelSimRadioMedia {
    static let empty: NewModelSimRadioMedia = .init(
        series: [:],
        trackLists: [:],
        stations: [:]
    )
}

struct NewModelSimGameSeries {
    struct ID: Codable, Hashable {
        let origin: URL
    }

    let id: ID
//    let meta: MediaList.Meta
    let stationsIDs: [NewModelSimStation.ID]
}

struct NewModelSimStation {
    struct ID: Hashable {
        let series: NewModelSimGameSeries.ID
        let value: String
    }

    let id: ID
//    let meta: MediaList.Meta
    let trackLists: [NewModelTrackList.ID]
}

struct NewModelTrackList {
    struct ID: Hashable {
        let series: NewModelSimGameSeries.ID
        let value: String
    }

    let id: ID
    let tracks: [NewModelTrack]
}

struct NewModelTrack: Hashable {
    struct ID: Hashable {
        let series: NewModelSimGameSeries.ID
        let value: String
    }

    let id: ID
    let path: String?
    let duration: Double?
    let intro: [NewModelTrack.ID]?
    let markers: NewModelSimRadioDTO.TrackMarkers?
    let trackList: NewModelTrackList.ID?
}

extension NewModelTrack {
    enum Const {
        static let mediaExtension = ".m4a"
    }

    var filePath: String? {
        path.map { $0 + Const.mediaExtension }
    }

    var url: URL? {
        guard let filePath else { return nil }
        return id.series
            .origin
            .deletingLastPathComponent()
            .appendingPathComponent(filePath)
    }

    var localFilePath: String? {
        filePath.map { ["\(id.series.origin.nonCryptoHash)", $0].joined(separator: "/") }
    }

    var localFileURL: URL? {
        // TODO:
        nil
    }
}

extension NewModelSimRadioMedia {
    enum StationLocalStatus {
        case completed
        case partial(missing: [NewModelTrackList.ID: [URL]])
        case missing
    }

    init(origin: URL, dto: NewModelSimRadioDTO.GameSeries) {
        let series = NewModelSimGameSeries(origin: origin, dto: dto)
        let trackLists: [NewModelTrackList] = dto.trackLists.map { trackListDTO in
            .init(
                id: .init(series: .init(origin: origin), value: trackListDTO.id.value),
                tracks: trackListDTO.tracks.map { trackDTO in
                    let intro: [NewModelTrack.ID]? = trackDTO.intro.map {
                        $0.map { .init(series: .init(origin: origin), value: $0.value) }
                    }
                    return .init(
                        id: .init(series: .init(origin: origin), value: trackDTO.id.value),
                        path: trackDTO.path,
                        duration: trackDTO.duration,
                        intro: intro,
                        markers: trackDTO.markers,
                        trackList: trackDTO.trackList.map { .init(series: .init(origin: origin), value: $0.value) }
                    )
                }
            )
        }
        let stations: [NewModelSimStation] = dto.stations.map {
            .init(
                id: .init(series: .init(origin: origin), value: $0.id.value),
                trackLists: $0.trackLists.map {
                    .init(series: .init(origin: origin), value: $0.value)
                }
            )
        }

        self.init(
            series: Dictionary(uniqueKeysWithValues: [(series.id, series)]),
            trackLists: Dictionary(uniqueKeysWithValues: trackLists.map { ($0.id, $0) }),
            stations: Dictionary(uniqueKeysWithValues: stations.map { ($0.id, $0) })
        )
    }

    func stationTrackLists(_ id: NewModelSimStation.ID) -> [NewModelTrackList] {
        stations[id]?.trackLists.compactMap { self.trackLists[$0] } ?? []
    }

    func calculateStationLocalStatus(_ id: NewModelSimStation.ID) async throws -> StationLocalStatus {
        var missing: [NewModelTrackList.ID: [URL]] = [:]
        var haveAny = false
        for trackList in stationTrackLists(id) {
            let missingTracks = trackList
                .tracks
                .compactMap(\.localFileURL)
                .filter { !$0.isFileExists }

            if trackList.tracks.count > missingTracks.count {
                haveAny = true
            }
            if !missingTracks.isEmpty {
                missing[trackList.id] = missingTracks
            }
        }

        if haveAny {
            return missing.isEmpty ? .completed : .partial(missing: missing)
        }
        return .missing
    }
}

extension NewModelSimGameSeries {
    init(origin: URL, dto: NewModelSimRadioDTO.GameSeries) {
        self.init(
            id: .init(origin: origin),
            stationsIDs: dto.stations.map { .init(series: .init(origin: origin), value: $0.id.value) }
        )
    }

    static let defaultFileName: String = "new_sim_radio_stations.json"
}

extension NewModelSimGameSeries.ID {
    var directoryURL: URL {
        .documentsDirectory.appending(path: path, directoryHint: .isDirectory)
    }

    var jsonFileURL: URL {
        directoryURL.appending(path: SimGameSeries.defaultFileName)
    }

    var path: String {
        "\(origin.nonCryptoHash)"
    }
}

extension [NewModelTrackList.ID: NewModelTrackList] {
    func findAllUsedTrackLists(usedIDs: [NewModelTrackList.ID]) -> [NewModelTrackList] {
        var result = [NewModelTrackList]()
        var idsToProcess = usedIDs
        var processedIDs = Set<NewModelTrackList.ID>()

        while let id = idsToProcess.popLast() {
            // Skip if already processed or if the tracklist doesn't exist
            guard !processedIDs.contains(id), let trackList = self[id] else { continue }

            processedIDs.insert(id)
            result.append(trackList)

            // Find all references to other tracklists in the current tracklist's tracks
            let referencedTrackListIDs = trackList.tracks.compactMap(\.trackList)
            idsToProcess.append(contentsOf: referencedTrackListIDs.filter { !processedIDs.contains($0) })
        }

        return result
    }
}
