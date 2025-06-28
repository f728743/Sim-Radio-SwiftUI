//
//  LegacySimRadioMedia.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.03.2025.
//

import Foundation

struct LegacySimRadioMedia {
    let series: [LegacySimGameSeries.ID: LegacySimGameSeries]
    let fileGroups: [LegacySimFileGroup.ID: LegacySimFileGroup]
    let stations: [LegacySimStation.ID: LegacySimStation]
}

struct LegacySimGameSeries {
    struct ID: Hashable { let value: String }
    var id: ID
    let meta: MediaList.Meta
    let stationsIDs: [LegacySimStation.ID]
}

struct LegacySimFileGroup {
    struct ID: Hashable { let value: String }
    let id: ID
    let files: [LegacySimFile]
}

struct LegacySimFile: Sendable {
    let url: URL
    let tag: String?
    let duration: Double
    let attaches: [LegacySimFile]
}

struct LegacySimStation {
    struct ID: Hashable { let value: String }
    var id: ID
    let meta: SimStationMeta
    let fileGroupIDs: [LegacySimFileGroup.ID]
    let playlistRules: LegacySimRadioDTO.Playlist
}

extension LegacySimRadioMedia {
    static let empty: LegacySimRadioMedia = .init(
        series: [:],
        fileGroups: [:],
        stations: [:]
    )
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
}

extension URL {
    var nonCryptoHash: UInt64 {
        absoluteString.nonCryptoHash
    }
}

extension LegacySimRadioDTO.GameSeries {
    func simFileGroups(origin: URL) -> [LegacySimFileGroup.ID: LegacySimFileGroup] {
        let common = common.fileGroups.map { LegacySimFileGroup(dto: $0, origin: origin) }
        let stations: [LegacySimFileGroup] = stations.flatMap { station in
            let stationGroups: [LegacySimFileGroup] = station.fileGroups.flatMap {
                let groups: [LegacySimFileGroup] = [
                    LegacySimFileGroup(dto: $0, origin: origin, pathTag: station.tag),
                    attachesGroup(
                        origin: origin,
                        files: $0.files
                            .flatMap { $0.attaches?.files ?? [] }
                            .map {
                                .init(dto: $0, baseUrl: origin.simRadioBaseURL, pathTag: "\(station.tag)")
                            },
                        pathTag: station.tag,
                        groupTag: LegacySimRadioMedia.attachesGroupTag
                    )
                ].compactMap(\.self)
                return groups
            }
            return stationGroups
        }
        return Dictionary(
            uniqueKeysWithValues: (common + stations).map { ($0.id, $0) }
        )
    }

    func attachesGroup(
        origin: URL,
        files: [LegacySimFile],
        pathTag: String? = nil,
        groupTag: String
    ) -> LegacySimFileGroup? {
        guard !files.isEmpty else { return nil }
        return .init(id: .init(origin: origin, pathTag: pathTag, groupTag: groupTag), files: files)
    }
}

extension LegacySimRadioMedia {
    init(origin: URL, dto: LegacySimRadioDTO.GameSeries) {
        let series = LegacySimGameSeries(dto: dto, origin: origin)
        let stations = dto.stations.map {
            LegacySimStation(dto: $0, common: dto.common, origin: origin)
        }
        self.init(
            series: Dictionary(uniqueKeysWithValues: [(series.id, series)]),
            fileGroups: dto.simFileGroups(origin: origin),
            stations: Dictionary(uniqueKeysWithValues: stations.map { ($0.id, $0) })
        )
    }

    static let attachesGroupTag: String = "intro"

    enum StationLocalStatus {
        case completed
        case partial(missing: [LegacySimFileGroup.ID: [URL]])
        case missing
    }

    func stationFileGroups(_ id: LegacySimStation.ID) -> [LegacySimFileGroup] {
        stations[id]?.fileGroupIDs.compactMap { fileGroups[$0] } ?? []
    }

    func calculateStationLocalStatus(_ id: LegacySimStation.ID) async throws -> StationLocalStatus {
        var missing: [LegacySimFileGroup.ID: [URL]] = [:]
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

    func sharedFileGroups(
        of stationID: LegacySimStation.ID,
        among stationIDs: [LegacySimStation.ID]
    ) -> [LegacySimFileGroup.ID] {
        guard let targetStation = stations[stationID], !targetStation.fileGroupIDs.isEmpty else {
            return []
        }

        let frequencyPairs = stations
            .filter { stationIDs.contains($0.key) }
            .values
            .flatMap(\.fileGroupIDs).map { ($0, 1) }
        let allFileGroupCounts = Dictionary(frequencyPairs, uniquingKeysWith: +)
        let sharedGroupsForTarget = targetStation.fileGroupIDs.filter { fileGroupID in
            (allFileGroupCounts[fileGroupID] ?? 0) > 0
        }
        return Array(sharedGroupsForTarget)
    }
}

extension LegacySimGameSeries {
    init(dto: LegacySimRadioDTO.GameSeries, origin: URL) {
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

extension LegacySimStation {
    init(dto: LegacySimRadioDTO.Station, common: LegacySimRadioDTO.GameSeriesCommon, origin: URL) {
        let artwork = origin.simRadioBaseURL
            .appendingPathComponent(dto.tag)
            .appendingPathComponent(dto.info.logo)
        let fullFileGroupSet = Set(dto.playlist.fileGroupTags)
        let commonFileGroupSet = Set(common.fileGroups.map(\.tag))
        let stationFileGroupIDs = fullFileGroupSet
            .subtracting(commonFileGroupSet)
            .map { LegacySimFileGroup.ID(origin: origin, pathTag: dto.tag, groupTag: $0) }
        let usedCommonFileGroupSet = fullFileGroupSet.intersection(commonFileGroupSet)
        let usedCommonFileGroupIDs = usedCommonFileGroupSet.map {
            LegacySimFileGroup.ID(origin: origin, groupTag: $0)
        }
        self.init(
            id: .init(origin: origin, stationTag: dto.tag),
            meta: .init(
                title: dto.info.title,
                artwork: artwork,
                genre: dto.info.genre,
                host: dto.info.dj
            ),
            fileGroupIDs: stationFileGroupIDs + usedCommonFileGroupIDs,
            playlistRules: dto.playlist
        )
    }
}

extension LegacySimGameSeries.ID {
    var directoryURL: URL {
        .documentsDirectory.appending(path: value, directoryHint: .isDirectory)
    }

    var jsonFileURL: URL {
        directoryURL.appending(path: LegacySimGameSeries.defaultFileName)
    }

    init(origin: URL) {
        self.init(value: "\(origin.nonCryptoHash)")
    }
}

extension LegacySimRadioDTO.Playlist {
    var fileGroupTags: [String] {
        let sources = fragments.flatMap { [$0.src] + ($0.mixins?.mix ?? []).map(\.src) }
        let attachGroupTags: [String] =
            sources.contains { $0.type == .attach } ? [LegacySimRadioMedia.attachesGroupTag] : []
        return sources
            .filter { $0.type == .group || $0.type == .file }
            .compactMap(\.groupTag)
            + attachGroupTags
    }
}

extension LegacySimStation.ID {
    init(origin: URL, stationTag: String) {
        self.init(value: "\(LegacySimGameSeries.ID(origin: origin).value)/\(stationTag)")
    }

    var directoryURL: URL {
        .documentsDirectory.appending(path: value, directoryHint: .isDirectory)
    }

    var seriesID: LegacySimGameSeries.ID {
        .init(value: String(value.split(separator: "/").first ?? ""))
    }
}

extension LegacySimFileGroup.ID {
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

extension LegacySimFileGroup {
    init(dto: LegacySimRadioDTO.FileGroup, origin: URL, pathTag: String? = nil) {
        self.init(
            id: .init(origin: origin, pathTag: pathTag, groupTag: dto.tag),
            files: dto.files.map { .init(dto: $0, baseUrl: origin.simRadioBaseURL, pathTag: pathTag) }
        )
    }
}

extension LegacySimFile {
    init(dto: LegacySimRadioDTO.File, baseUrl: URL, pathTag: String?) {
        let url = [pathTag, dto.path].compactMap(\.self).reduce(baseUrl) { $0.appendingPathComponent($1) }
        self.init(
            url: url,
            tag: dto.tag,
            duration: dto.audibleDuration ?? dto.duration,
            attaches: (dto.attaches?.files ?? []).map { .init(dto: $0, baseUrl: baseUrl, pathTag: pathTag) }
        )
    }
}
