//
//  Dependencies.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 13.05.2025.
//

import Observation

@MainActor
class Dependencies: Observable {
    let mediaState: MediaState
    let mediaPlayer: MediaPlayer

    init(
        mediaState: MediaState,
        mediaPlayer: MediaPlayer
    ) {
        self.mediaState = mediaState
        self.mediaPlayer = mediaPlayer
    }
}

extension Dependencies {
    static var stub: Dependencies = {
        let mediaPlayer = MediaPlayer()
        return Dependencies(
            mediaState: .stub,
            mediaPlayer: mediaPlayer
        )
    }()
}
