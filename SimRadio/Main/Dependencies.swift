//
//  Dependencies.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 13.05.2025.
//

import Observation

@MainActor
class Dependencies: Observable {
    let apiService: APIService
    let dataController: DataController
    let mediaState: DefaultMediaState
    let mediaPlayer: MediaPlayer
    let playerController: PlayerController

    init(
        apiService: APIService,
        dataController: DataController,
        mediaState: DefaultMediaState,
        mediaPlayer: MediaPlayer,
        playerController: PlayerController
    ) {
        self.apiService = apiService
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
            apiService: APIService(baseURL: ""),
            dataController: DataController(),
            mediaState: .stub,
            mediaPlayer: mediaPlayer,
            playerController: PlayerController(),
        )
    }()
}
