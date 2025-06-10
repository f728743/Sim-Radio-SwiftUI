//
//  SimRadioMedia.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.03.2025.
//

import Foundation

struct SimRadioMedia {
    let series: [SimGameSeries.ID: SimGameSeries]
    let fileGroups: [SimFileGroup.ID: SimFileGroup]
    let stations: [SimStation.ID: SimStation]
}

struct SimGameSeries {
    struct ID: Hashable { let value: String }
    var id: ID
    let meta: MediaList.Meta
    let stationsIDs: [SimStation.ID]
}

struct SimFileGroup {
    struct ID: Hashable { let value: String }
    let id: ID
    let files: [SimFile]
}

struct SimFile: Sendable {
    let url: URL
    let tag: String?
    let duration: Double
    let attaches: [SimFile]
}

struct SimStationMeta: Codable {
    let title: String
    let artwork: URL?
    let genre: String
    let host: String?
}

struct SimStation {
    struct ID: Hashable { let value: String }
    var id: ID
    let meta: SimStationMeta
    let fileGroupIDs: [SimFileGroup.ID]
    let playlistRules: SimRadioDTO.Playlist
}

extension SimRadioMedia {
    static let empty: SimRadioMedia = .init(
        series: [:],
        fileGroups: [:],
        stations: [:]
    )
}

extension SimStationMeta {
    var detailsSubtitle: String {
        host.map { "Hosted by \($0) – \(genre)" } ?? genre
    }
}

extension Media.Meta {
    init(_ meta: SimStationMeta) {
        self.init(
            artwork: meta.artwork,
            title: meta.title,
            listSubtitle: meta.genre,
            detailsSubtitle: meta.detailsSubtitle,
            isLiveStream: true
        )
    }
}

private extension URL {
    var simRadioBaseURL: URL {
        deletingLastPathComponent()
    }

    var nonCryptoHash: UInt64 {
        absoluteString.nonCryptoHash
    }
}

extension SimRadioDTO.GameSeries {
    func simFileGroups(origin: URL) -> [SimFileGroup.ID: SimFileGroup] {
        let shared = gameSeriesShared.fileGroups.map { SimFileGroup(dto: $0, origin: origin) }
        let stations: [SimFileGroup] = stations.flatMap { station in
            let stationGroups: [SimFileGroup] = station.fileGroups.flatMap {
                let groups: [SimFileGroup] = [
                    SimFileGroup(dto: $0, origin: origin, pathTag: station.tag),
                    attachesGroup(
                        origin: origin,
                        files: $0.files
                            .flatMap { $0.attaches?.files ?? [] }
                            .map {
                                .init(dto: $0, baseUrl: origin.simRadioBaseURL, pathTag: "\(station.tag)")
                            },
                        pathTag: station.tag,
                        groupTag: SimRadioMedia.attachesGroupTag
                    )
                ].compactMap(\.self)
                return groups
            }
            return stationGroups
        }
        return Dictionary(
            uniqueKeysWithValues: (shared + stations).map { ($0.id, $0) }
        )
    }

    func attachesGroup(origin: URL, files: [SimFile], pathTag: String? = nil, groupTag: String) -> SimFileGroup? {
        guard !files.isEmpty else { return nil }
        return .init(id: .init(origin: origin, pathTag: pathTag, groupTag: groupTag), files: files)
    }
}

extension SimRadioMedia {
    init(dto: SimRadioDTO.GameSeries, origin: URL) {
        let series = SimGameSeries(dto: dto, origin: origin)
        let stations = dto.stations.map { SimStation(dto: $0, gameSeriesShared: dto.gameSeriesShared, origin: origin) }
        self.init(
            series: Dictionary(uniqueKeysWithValues: [(series.id, series)]),
            fileGroups: dto.simFileGroups(origin: origin),
            stations: Dictionary(uniqueKeysWithValues: stations.map { ($0.id, $0) })
        )
    }

    static let attachesGroupTag: String = "intro"

    enum StationLocalStatus {
        case completed
        case partial(missing: [SimFileGroup.ID: [URL]])
        case missing
    }

    func stationFileGroups(_ id: SimStation.ID) -> [SimFileGroup] {
        stations[id]?.fileGroupIDs.compactMap { fileGroups[$0] } ?? []
    }

    func calculateStationLocalStatus(_ id: SimStation.ID) async throws -> StationLocalStatus {
        var missing: [SimFileGroup.ID: [URL]] = [:]
        var haveAny = false
        for fileGroup in stationFileGroups(id) {
            let missingFiles = fileGroup
                .files
                .map(\.url)
                .filter { !fileGroup.id.localFileURL(for: $0).isFileExists }
            if fileGroup.files.count > missingFiles.count {
                haveAny = true
            }
            if !missingFiles.isEmpty {
                missing[fileGroup.id] = missingFiles
            }
        }

        if haveAny {
            return missing.isEmpty ? .completed : .partial(missing: missing)
        }
        return .missing
    }

    func sharedFileGroups(of stationID: SimStation.ID, among stationIDs: [SimStation.ID]? = nil) -> [SimFileGroup.ID] {
        guard let targetStation = stations[stationID], !targetStation.fileGroupIDs.isEmpty else {
            return []
        }

        let frequencyPairs = stations
            .filter { stationIDs?.contains($0.key) ?? true }
            .values
            .flatMap(\.fileGroupIDs).map { ($0, 1) }
        let allFileGroupCounts = Dictionary(frequencyPairs, uniquingKeysWith: +)
        let sharedGroupsForTarget = targetStation.fileGroupIDs.filter { fileGroupID in
            (allFileGroupCounts[fileGroupID] ?? 0) > 0
        }
        return Array(sharedGroupsForTarget)
    }
}

extension Collection<URL> {}

extension SimGameSeries {
    init(dto: SimRadioDTO.GameSeries, origin: URL) {
        self.init(
            id: .init(origin: origin),
            meta: .init(
                artwork: origin.simRadioBaseURL.appendingPathComponent(dto.info.logo),
                title: dto.info.title,
                subtitle: nil
            ),
            stationsIDs: dto.stations.map { .init(origin: origin, stationTag: $0.tag) }
        )
    }

    static let defaultFileName: String = "sim_radio_stations.json"
    static let userDefaultsKey: String = "sim_series_ids"
}

extension SimStation {
    init(dto: SimRadioDTO.Station, gameSeriesShared: SimRadioDTO.GameSeriesShared, origin: URL) {
        let artwork = origin.simRadioBaseURL
            .appendingPathComponent(dto.tag)
            .appendingPathComponent(dto.info.logo)
        let fullFileGroupSet = Set(dto.playlist.fileGroupTags)
        let gameSeriesSharedFileGroupSet = Set(gameSeriesShared.fileGroups.map(\.tag))
        let stationFileGroupIDs = fullFileGroupSet
            .subtracting(gameSeriesSharedFileGroupSet)
            .map { SimFileGroup.ID(origin: origin, pathTag: dto.tag, groupTag: $0) }
        let usedGameSeriesSharedFileGroupSet = fullFileGroupSet.intersection(gameSeriesSharedFileGroupSet)
        let usedGameSeriesSharedFileGroupIDs = usedGameSeriesSharedFileGroupSet.map {
            SimFileGroup.ID(origin: origin, groupTag: $0)
        }
        self.init(
            id: .init(origin: origin, stationTag: dto.tag),
            meta: .init(
                title: dto.info.title,
                artwork: artwork,
                genre: dto.info.genre,
                host: dto.info.dj
            ),
            fileGroupIDs: stationFileGroupIDs + usedGameSeriesSharedFileGroupIDs,
            playlistRules: dto.playlist
        )
    }
}

extension SimGameSeries.ID {
    var directoryURL: URL {
        .documentsDirectory.appending(path: value, directoryHint: .isDirectory)
    }

    var jsonFileURL: URL {
        directoryURL.appending(path: SimGameSeries.defaultFileName)
    }

    init(origin: URL) {
        self.init(value: "\(origin.nonCryptoHash)")
    }
}

extension SimRadioDTO.Playlist {
    var fileGroupTags: [String] {
        let sources = fragments.flatMap { [$0.src] + ($0.mixins?.mix ?? []).map(\.src) }
        let attachGroupTags: [String] = sources.contains { $0.type == .attach } ? [SimRadioMedia.attachesGroupTag] : []
        return sources
            .filter { $0.type == .group || $0.type == .file }
            .compactMap(\.groupTag)
            + attachGroupTags
    }
}

extension SimStation.ID {
    init(origin: URL, stationTag: String) {
        self.init(value: "\(SimGameSeries.ID(origin: origin).value)/\(stationTag)")
    }

    var directoryURL: URL {
        .documentsDirectory.appending(path: value, directoryHint: .isDirectory)
    }

    var seriesID: SimGameSeries.ID {
        .init(value: String(value.split(separator: "/").first ?? ""))
    }
}

extension SimFileGroup.ID {
    init(origin: URL, pathTag: String? = nil, groupTag: String) {
        let path = pathTag.map { "/\($0)" } ?? ""
        self.init(value: "\(origin.nonCryptoHash)\(path)/\(groupTag)")
    }

    var directoryURL: URL {
        .documentsDirectory.appending(path: value, directoryHint: .isDirectory)
    }

    func localFileURL(for url: URL) -> URL {
        directoryURL.appending(path: url.lastPathComponent, directoryHint: .notDirectory)
    }
}

extension SimFileGroup {
    init(dto: SimRadioDTO.FileGroup, origin: URL, pathTag: String? = nil) {
        self.init(
            id: .init(origin: origin, pathTag: pathTag, groupTag: dto.tag),
            files: dto.files.map { .init(dto: $0, baseUrl: origin.simRadioBaseURL, pathTag: pathTag) }
        )
    }
}

extension SimFile {
    init(dto: SimRadioDTO.File, baseUrl: URL, pathTag: String?) {
        let url = [pathTag, dto.path].compactMap(\.self).reduce(baseUrl) { $0.appendingPathComponent($1) }
        self.init(
            url: url,
            tag: dto.tag,
            duration: dto.audibleDuration ?? dto.duration,
            attaches: (dto.attaches?.files ?? []).map { .init(dto: $0, baseUrl: baseUrl, pathTag: pathTag) }
        )
    }
}
