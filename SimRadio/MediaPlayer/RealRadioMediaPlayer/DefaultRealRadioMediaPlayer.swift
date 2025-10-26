//
//  DefaultRealRadioMediaPlayer.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.10.2025.
//

import Foundation

@MainActor
class DefaultRealRadioMediaPlayer {
    weak var mediaState: RealRadioMediaState?
    weak var delegate: RealRadioMediaPlayerDelegate?
}

extension DefaultRealRadioMediaPlayer: RealRadioMediaPlayer {
    func playStation(withID stationID: RealStation.ID) {
        guard let mediaState, let station = mediaState.realRadio.stations[stationID] else { return }
        print("playing station \(station.title)")
    }

    func stop() {
        print("stopping")
    }
}
