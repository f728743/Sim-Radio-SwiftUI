//
//  SimRadioMediaState.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 21.04.2025.
//

@MainActor
protocol SimRadioMediaState: AnyObject, Sendable {
    var legacySimRadio: LegacySimRadioMedia { get }
    var legacySimDownloadStatus: [LegacySimStation.ID: MediaDownloadStatus] { get }

    var simRadio: SimRadioMedia { get }
    var simDownloadStatus: [SimStation.ID: MediaDownloadStatus] { get }
}

struct SimRadioStationData {
    let station: LegacySimStation
    let fileGroups: [LegacySimFileGroup]
    let isDownloaded: Bool
}

extension LegacySimRadioMedia {
    func stationData(
        for stationID: LegacySimStation.ID
    ) -> (station: LegacySimStation, fileGroups: [LegacySimFileGroup])? {
        guard let station = stations[stationID] else { return nil }
        let fileGroups: [LegacySimFileGroup] = station.fileGroupIDs.compactMap { self.fileGroups[$0] }
        guard fileGroups.count == station.fileGroupIDs.count else { return nil }
        return (station, fileGroups)
    }
}

extension MediaState: SimRadioMediaState {
    var simDownloadStatus: [SimStation.ID: MediaDownloadStatus] {
        Dictionary(uniqueKeysWithValues: downloadStatus.compactMap {
            if case let .simRadio(id) = $0.key {
                return (id, $0.value)
            }
            return nil
        })
    }

    var legacySimDownloadStatus: [LegacySimStation.ID: MediaDownloadStatus] {
        Dictionary(uniqueKeysWithValues: downloadStatus.compactMap {
            if case let .legacySimRadio(id) = $0.key {
                return (id, $0.value)
            }
            return nil
        })
    }
}

extension SimRadioMediaState {
    func stationData(for stationID: LegacySimStation.ID) -> SimRadioStationData? {
        guard let stationData = legacySimRadio.stationData(for: stationID) else { return nil }
        return .init(
            station: stationData.station,
            fileGroups: stationData.fileGroups,
            isDownloaded: legacySimDownloadStatus[stationID]?.state == .completed
        )
    }
}
