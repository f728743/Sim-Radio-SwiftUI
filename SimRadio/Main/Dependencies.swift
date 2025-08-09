//
//  Dependencies.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 13.05.2025.
//

import Observation

@MainActor
class Dependencies: Observable {
    let mediaState: DefaultMediaState
    let mediaPlayer: MediaPlayer
    let playerController: PlayerController

    init(
        mediaState: DefaultMediaState,
        mediaPlayer: MediaPlayer,
        playerController: PlayerController
    ) {
        self.mediaState = mediaState
        self.mediaPlayer = mediaPlayer
        self.playerController = playerController
    }
}

extension Dependencies {
    static var stub: Dependencies = {
        let mediaPlayer = MediaPlayer()
        return Dependencies(
            mediaState: .stub,
            mediaPlayer: mediaPlayer,
            playerController: PlayerController()
        )
    }()
}
