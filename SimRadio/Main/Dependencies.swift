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

    static func make() -> Dependencies {
        let simRadioDownload = DefaultSimRadioDownload()

        let simRadioLibrary = DefaultSimRadioLibrary(
            storage: UserDefaultsRadioStorage(),
            simRadioDownload: simRadioDownload
        )

        let mediaState = DefaultMediaState(simRadioLibrary: simRadioLibrary)

        simRadioDownload.mediaState = mediaState
        simRadioLibrary.delegate = mediaState
        simRadioLibrary.mediaState = mediaState

        let simRadioPlayer = DefaultSimRadioMediaPlayer()
        simRadioPlayer.mediaState = mediaState

        let mediaPlayer = MediaPlayer()
        mediaPlayer.simRadio = simRadioPlayer
        simRadioPlayer.delegate = mediaPlayer
        mediaPlayer.mediaState = mediaState

        let playerController = PlayerController()
        playerController.player = mediaPlayer
        playerController.mediaState = mediaState

        let dataController = DataController()

        let apiService = APIService(baseURL: "https://sim-radio.ru")

        return Dependencies(
            apiService: apiService,
            dataController: dataController,
            mediaState: mediaState,
            mediaPlayer: mediaPlayer,
            playerController: playerController
        )
    }
}
