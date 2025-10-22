//
//  AppDelegate.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 15.05.2025.
//

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    var dependencies: Dependencies?

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        setupDependencies()
        return true
    }
}

private extension AppDelegate {
    func setupDependencies() {
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

        dependencies = Dependencies(
            apiService: apiService,
            dataController: dataController,
            mediaState: mediaState,
            mediaPlayer: mediaPlayer,
            playerController: playerController
        )

        Task {
            await mediaState.load()
        }
    }
}
