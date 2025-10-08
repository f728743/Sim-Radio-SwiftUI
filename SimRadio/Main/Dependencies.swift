//
//  Dependencies.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 13.05.2025.
//

import Observation

@MainActor
class Dependencies: Observable {
    let dataController: DataController
    let mediaState: DefaultMediaState
    let mediaPlayer: MediaPlayer
    let playerController: PlayerController

    init(
        dataController: DataController,
        mediaState: DefaultMediaState,
        mediaPlayer: MediaPlayer,
        playerController: PlayerController
    ) {
        self.dataController = dataController
        self.mediaState = mediaState
        self.mediaPlayer = mediaPlayer
        self.playerController = playerController
    }
}

extension Dependencies {
    static var stub: Dependencies = {
        let mediaPlayer = MediaPlayer()
        return Dependencies(
            dataController: DataController(),
            mediaState: .stub,
            mediaPlayer: mediaPlayer,
            playerController: PlayerController(),            
        )
    }()
}
