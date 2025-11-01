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
    let mediaState: MediaState
    let mediaPlayer: MediaPlayer
    let playerController: PlayerController

    init(
        apiService: APIService,
        dataController: DataController,
        mediaState: MediaState,
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
            mediaState: DefaultMediaState.stub,
            mediaPlayer: mediaPlayer,
            playerController: PlayerController(),
        )
    }()

    static func make() -> Dependencies {
        let simRadioDownload = DefaultSimRadioDownload()
        let dataController = DataController()

        let simRadioLibrary = DefaultSimRadioLibrary(
            storage: UserDefaultsRadioStorage(),
            simRadioDownload: simRadioDownload
        )

        let realRadioLibrary = DefaultRealRadioLibrary()

        let mediaState = DefaultMediaState(
            simRadioLibrary: simRadioLibrary,
            realRadioLibrary: realRadioLibrary
        )

        simRadioDownload.mediaState = mediaState
        simRadioLibrary.delegate = mediaState
        simRadioLibrary.mediaState = mediaState

        realRadioLibrary.delegate = mediaState
        realRadioLibrary.mediaState = mediaState
        realRadioLibrary.dataController = dataController

        let simPlayer = DefaultSimRadioMediaPlayer()
        simPlayer.mediaState = mediaState

        let realPlayer = DefaultRealRadioMediaPlayer()
        realPlayer.mediaState = mediaState

        let mediaPlayer = MediaPlayer()
        mediaPlayer.simPlayer = simPlayer
        simPlayer.delegate = mediaPlayer
        mediaPlayer.realPlayer = realPlayer
        realPlayer.delegate = mediaPlayer
        mediaPlayer.mediaState = mediaState

        let playerController = PlayerController()
        playerController.player = mediaPlayer
        playerController.mediaState = mediaState

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
