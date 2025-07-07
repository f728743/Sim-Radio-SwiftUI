//
//  SimRadioMediaPlayerStub.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 01.05.2025.
//

class SimRadioMediaPlayerStub: SimRadioMediaPlayer {
    func playStation(withID stationID: SimStation.ID) {
        print("Play \(stationID)")
    }
    
    func playStation(withID stationID: LegacySimStation.ID) {
        print("Play \(stationID)")
    }

    func stop() {
        print("Stop")
    }
}
