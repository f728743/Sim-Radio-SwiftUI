//
//  SimRadioMedia.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 24.06.2025.
//

import Foundation

struct SimRadioMedia {
    let series: [SimGameSeries.ID: SimGameSeries]
    let trackLists: [TrackList.ID: TrackList]
    let stations: [SimStation.ID: SimStation]
}

extension SimRadioMedia {
    static let empty: SimRadioMedia = .init(
        series: [:],
        trackLists: [:],
        stations: [:]
    )
}

struct SimGameSeries {
    struct ID: Codable, Hashable {
        let origin: URL
    }

    let id: ID
//    let meta: MediaList.Meta
    let stationsIDs: [SimStation.ID]
}

struct SimStationMeta: Codable {
    let title: String
    let artwork: URL?
    let genre: String
    let host: String?
}

struct SimStation {
    struct ID: Hashable {
        let series: SimGameSeries.ID
        let value: String
    }

    let id: ID
    let meta: SimStationMeta
    let trackLists: [TrackList.ID]
    let playlistRules: SimRadioDTO.Playlist
}

struct TrackList {
    struct ID: Hashable {
        let series: SimGameSeries.ID
        let value: String
    }

    let id: ID
    let tracks: [Track]
}

struct Track: Hashable {
    struct ID: Hashable {
        let series: SimGameSeries.ID
        let value: String
    }

    let id: ID
    let path: String?
    let start: Double?
    let duration: Double?
    let intro: [Track.ID]?
    let markers: SimRadioDTO.TrackMarkers?
    let trackList: TrackList.ID?
}

struct DereferencedTruck {
    let id: Track.ID
    let path: String
    let start: Double?
    let duration: Double
    let intro: [Track.ID]?
    let markers: SimRadioDTO.TrackMarkers?
}

extension SimStationMeta {
    var detailsSubtitle: String {
        host.map { "Hosted by \($0) – \(genre)" } ?? genre
    }
}

extension DereferencedTruck {
    var url: URL { Track.url(seriesID: id.series, path: path) }
    var localFileURL: URL { Track.localFileURL(seriesID: id.series, path: path) }
    func url(local: Bool) -> URL {
        local ? localFileURL : url
    }
}

extension Track {
    fileprivate static func filePath(path: String) -> String {
        path + Const.mediaExtension
    }

    fileprivate static func url(seriesID: SimGameSeries.ID, path: String) -> URL {
        seriesID
            .origin
            .deletingLastPathComponent()
            .appendingPathComponent(filePath(path: path))
    }

    fileprivate static func localFilePath(seriesID: SimGameSeries.ID, path: String) -> String {
        ["\(seriesID.origin.nonCryptoHash)", filePath(path: path)].joined(separator: "/")
    }

    fileprivate static func localFileURL(seriesID: SimGameSeries.ID, path: String) -> URL {
        .documentsDirectory
            .appending(
                path: localFilePath(seriesID: seriesID, path: path),
                directoryHint: .notDirectory
            )
    }

    enum Const {
        static let mediaExtension = ".m4a"
    }

    var filePath: String? { path.map { Self.filePath(path: $0) } }

    var url: URL? { path.map { Self.url(seriesID: id.series, path: $0) } }

    var localFilePath: String? { path.map { Self.localFilePath(seriesID: id.series, path: $0) } }

    var localFileURL: URL? { path.map { Self.localFileURL(seriesID: id.series, path: $0) } }

    var destinationDirectoryPath: String? {
        localFilePath?.deletingLastPathComponent()
    }

    func dereference(
        trackLists: [TrackList.ID: TrackList],
        referenceIntro: [Track.ID]? = nil
    ) throws -> DereferencedTruck {
        // If this is the final track (doesn't reference another track list)
        guard let nextTrackListID = trackList else {
            // Validate required fields
            guard let path, let duration else {
                throw DereferenceError.missingPathOrDuration(trackID: id)
            }
            return DereferencedTruck(
                id: id,
                path: path,
                start: start,
                duration: duration,
                intro: referenceIntro ?? intro,
                markers: markers
            )
        }

        // Find the next track list in the chain
        guard let nextTrackList = trackLists[nextTrackListID] else {
            throw DereferenceError.trackListNotFound(nextTrackListID)
        }

        // Find a track in the next list with matching id.value
        guard let nextTrack = nextTrackList.tracks.first(where: { $0.id.value == self.id.value }) else {
            throw DereferenceError.trackNotFoundInTrackList(
                trackListID: nextTrackListID,
                trackValue: id.value
            )
        }

        // Recursively dereference the found track
        return try nextTrack.dereference(trackLists: trackLists, referenceIntro: referenceIntro ?? intro)
    }
}

enum DereferenceError: Error {
    case trackListNotFound(TrackList.ID)
    case trackNotFoundInTrackList(trackListID: TrackList.ID, trackValue: String)
    case missingPathOrDuration(trackID: Track.ID)
}

extension SimRadioMedia {
    enum StationLocalStatus {
        case completed
        case partial(missing: [TrackList.ID: [URL]])
        case missing
    }

    init(origin: URL, dto: SimRadioDTO.GameSeries) {
        let series = SimGameSeries(origin: origin, dto: dto)
        let trackLists: [TrackList] = dto.trackLists.map { trackListDTO in
            .init(
                id: .init(series: .init(origin: origin), value: trackListDTO.id.value),
                tracks: trackListDTO.tracks.map { trackDTO in
                    let intro: [Track.ID]? = trackDTO.intro.map {
                        $0.map { .init(series: .init(origin: origin), value: $0.value) }
                    }
                    return .init(
                        id: .init(series: .init(origin: origin), value: trackDTO.id.value),
                        path: trackDTO.path,
                        start: trackDTO.start,
                        duration: trackDTO.duration,
                        intro: intro,
                        markers: trackDTO.markers,
                        trackList: trackDTO.trackList.map { .init(series: .init(origin: origin), value: $0.value) }
                    )
                }
            )
        }
        let stations: [SimStation] = dto.stations.filter { $0.isHidden != true }.map {
            .init(
                id: .init(series: .init(origin: origin), value: $0.id.value),
                meta: .init(origin: origin, data: $0.meta),
                trackLists: $0.trackLists.map {
                    .init(series: .init(origin: origin), value: $0.value)
                },
                playlistRules: $0.playlist
            )
        }

        self.init(
            series: Dictionary(uniqueKeysWithValues: [(series.id, series)]),
            trackLists: Dictionary(uniqueKeysWithValues: trackLists.map { ($0.id, $0) }),
            stations: Dictionary(uniqueKeysWithValues: stations.map { ($0.id, $0) })
        )
    }

    func stationTrackLists(_ id: SimStation.ID) -> [TrackList] {
        trackLists.findAllUsedTrackLists(usedIDs: stations[id]?.trackLists ?? [])
    }

    func calculateStationLocalStatus(_ id: SimStation.ID) async throws -> StationLocalStatus {
        var missing: [TrackList.ID: [URL]] = [:]
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

extension SimRadioMedia {
    func findAllUsedTrackLists(stationID: SimStation.ID) -> [TrackList] {
        guard let station = stations[stationID] else { return [] }
        return trackLists.findAllUsedTrackLists(usedIDs: station.trackLists)
    }

    func commonTrackLists(
        of stationID: SimStation.ID,
        among stationIDs: [SimStation.ID]
    ) -> [TrackList.ID] {
        // Get all track lists for the target station (including nested ones)
        let targetTrackLists = findAllUsedTrackLists(stationID: stationID).map(\.id)

        // Return empty array if no track lists or comparison stations provided
        guard !targetTrackLists.isEmpty, !stationIDs.isEmpty else { return [] }

        // Collect all track lists from stations in 'among' parameter
        let otherStationsTrackLists = stationIDs.reduce(into: Set<TrackList.ID>()) { result, id in
            let lists = findAllUsedTrackLists(stationID: id).map(\.id)
            result.formUnion(lists)
        }

        // Find intersection between target station's track lists and other stations'
        let intersection = targetTrackLists.filter { otherStationsTrackLists.contains($0) }

        return intersection
    }
}

extension SimGameSeries {
    init(origin: URL, dto: SimRadioDTO.GameSeries) {
        self.init(
            id: .init(origin: origin),
            stationsIDs: dto.stations.map { .init(series: .init(origin: origin), value: $0.id.value) }
        )
    }

    static let defaultFileName: String = "new_sim_radio_stations.json"
}

extension SimGameSeries.ID {
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

extension [TrackList.ID: TrackList] {
    func findAllUsedTrackLists(usedIDs: [TrackList.ID]) -> [TrackList] {
        var result = [TrackList]()
        var idsToProcess = usedIDs
        var processedIDs = Set<TrackList.ID>()

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
