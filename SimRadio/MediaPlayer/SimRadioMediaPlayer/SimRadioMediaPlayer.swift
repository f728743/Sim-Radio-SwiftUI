//
//  SimRadioMediaPlayer.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 01.05.2025.
//

import Foundation

@MainActor
protocol SimRadioMediaPlayer {
    func playStation(withID stationID: MediaID)
    func stop()
}

@MainActor
protocol SimRadioMediaPlayerDelegate: AnyObject {
    func simRadioMediaPlayer(_ player: SimRadioMediaPlayer, didUpdateSpectrum spectrum: [Float])
}
