//
//  RealRadioMediaPlayer.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.10.2025.
//

import MediaLibrary

@MainActor
protocol RealRadioMediaPlayer {
    func playStation(withID stationID: RealStation.ID)
    func stop()
}

@MainActor
protocol RealRadioMediaPlayerDelegate: AnyObject {
    func realRadioMediaPlayer(_ player: RealRadioMediaPlayer, didUpdateSpectrum spectrum: [Float])
}
