//
//  SimRadioMediaPlayer.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 01.05.2025.
//

import MediaLibrary

@MainActor
protocol SimRadioMediaPlayer {
    func playStation(withID stationID: MediaID, mode: MediaPlaybackMode.ID?) // TODO: replace MediaID with SimStation.ID
    func availableModes(stationID: MediaID) -> [MediaPlaybackMode]
    func stop()
}

@MainActor
protocol SimRadioMediaPlayerDelegate: AnyObject {
    func simRadioMediaPlayer(_ player: SimRadioMediaPlayer, didUpdateSpectrum spectrum: [Float])
    func simRadioMediaPlayer(_ player: SimRadioMediaPlayer, didCrossTrackMarker marker: AudioFragmentMarker?)
}
