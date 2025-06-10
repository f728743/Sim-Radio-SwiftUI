//
//  SimRadioMediaState.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 21.04.2025.
//

@MainActor
protocol SimRadioMediaState: AnyObject, Sendable {
    var simRadio: SimRadioMedia { get }
    var simDownloadStatus: [SimStation.ID: MediaDownloadStatus] { get }
}

struct SimRadioStationData {
    let station: SimStation
    let fileGroups: [SimFileGroup]
    let isDownloaded: Bool
}

extension SimRadioMedia {
    func stationData(for stationID: SimStation.ID) -> (station: SimStation, fileGroups: [SimFileGroup])? {
        guard let station = stations[stationID] else { return nil }
        let fileGroups: [SimFileGroup] = station.fileGroupIDs.compactMap { self.fileGroups[$0] }
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
}

extension SimRadioMediaState {
    func stationData(for stationID: SimStation.ID) -> SimRadioStationData? {
        guard let stationData = simRadio.stationData(for: stationID) else { return nil }
        return .init(
            station: stationData.station,
            fileGroups: stationData.fileGroups,
            isDownloaded: simDownloadStatus[stationID]?.state == .completed
        )
    }
}
