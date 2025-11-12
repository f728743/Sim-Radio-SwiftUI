//
//  RealRadioMediaPlayer.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.10.2025.
//

import MediaLibrary

@MainActor
public protocol RealRadioMediaPlayer {
    func playStation(withID stationID: RealStation.ID)
    func stop()
}

@MainActor
public protocol RealRadioMediaPlayerDelegate: AnyObject {
    func realRadioMediaPlayer(_ player: RealRadioMediaPlayer, didUpdateSpectrum spectrum: [Float])
}
