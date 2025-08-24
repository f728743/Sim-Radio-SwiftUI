//
//  SimRadioMediaPlayerStub.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 01.05.2025.
//

class SimRadioMediaPlayerStub: SimRadioMediaPlayer {
    func playStation(withID stationID: MediaID, mode _: MediaPlaybackMode.ID?) {
        print("Play \(stationID)")
    }

    func stop() {
        print("Stop")
    }

    func availableModes(stationID _: MediaID) -> [MediaPlaybackMode] {
        []
    }
}
