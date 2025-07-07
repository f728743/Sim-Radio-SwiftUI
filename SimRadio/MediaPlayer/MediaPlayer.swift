//
//  MediaPlayer.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 30.11.2024.
//

import Combine
import UIKit

enum MediaPlayerState: Equatable, Hashable {
    case playing(MediaID)
    case paused(MediaID?)
}

@MainActor
class MediaPlayer {
    enum Const {
        static let frequencyBands = 5
    }

    var simRadio: SimRadioMediaPlayer?
    weak var mediaState: SimRadioMediaState?
    private(set) var items: [MediaID] = []

    @Published private(set) var progress: NowPlayingInfo.Progress?
    @Published private(set) var state: MediaPlayerState
    @Published private(set) var commandProfile: CommandProfile?
    @Published private(set) var palyIndicatorSpectrum: [Float]

    private var nowPlayingMeta: NowPlayingInfo.Meta?
    private var audioSession: AudioSession
    private var systemMediaInterface: SystemMediaInterface
    // For handling interruptions
    private var interruptedMediaID: MediaID?

    init() {
        audioSession = AudioSession()
        systemMediaInterface = SystemMediaInterface()
        state = .paused(.none)
        commandProfile = CommandProfile(isLiveStream: false, isSwitchTrackEnabled: false)
        palyIndicatorSpectrum = .init(repeating: 0, count: Const.frequencyBands)
        systemMediaInterface.setRemoteCommandProfile(commandProfile!)
        audioSession.delegate = self
        systemMediaInterface.delegate = self
    }

    // MARK: - Public Playback Controls

    func togglePlayPause() {
        if state.isPlaying {
            pause()
        } else {
            play()
        }
    }

    func play() {
        guard !state.isPlaying else { return }
        if let mediaID = state.currentMediaID {
            guard let index = items.firstIndex(of: mediaID) else {
                print("MediaPlayer Error: there is no mediaID \(mediaID) in items.")
                return
            }
            playItem(at: index)
        } else if let playItems = mediaState?.defaultPlayItems {
            play(playItems.media, of: playItems.items)
        }
    }

    func play(_ mediaID: MediaID, of items: [MediaID]) {
        guard let index = items.firstIndex(of: mediaID) else {
            print("MediaPlayer Error: there is no mediaID \(mediaID) in items.")
            return
        }
        self.items = items
        playItem(at: index)
    }

    func pause() {
        guard case let .playing(mediaID) = state else {
            print("MediaPlayer: Not playing, cannot pause.")
            return
        }
        stopCurrentPlayerActivity()
        state = .paused(mediaID)
        setStemMediaInterfaceNowPlayingInfo()
    }

    func forward() {
        guard items.count > 1,
              let mediaID = state.currentMediaID,
              let index = items.firstIndex(of: mediaID)
        else {
            return
        }
        let nextIndex = items.indices.contains(index + 1) ? index + 1 : 0
        goToItem(at: nextIndex)
    }

    func backward() {
        guard items.count > 1,
              let mediaID = state.currentMediaID,
              let index = items.firstIndex(of: mediaID)
        else {
            return
        }
        let nextIndex = items.indices.contains(index - 1) ? index - 1 : items.count - 1
        goToItem(at: nextIndex)
    }
}

private extension MediaPlayer {
    func goToItem(at index: Int) {
        if state.isPlaying {
            playItem(at: index)
        } else {
            state = .paused(items[index])
            setStemMediaInterfaceNowPlayingInfo()
        }
    }

    func playItem(at index: Int) {
        guard items.indices.contains(index) else {
            print("MediaPlayer Error: Index out of bounds for items queue.")
            return
        }

        let mediaID = items[index]

        if case let .playing(currentID) = state, currentID == mediaID {
            print("MediaPlayer: Already playing \(mediaID).")
            // TODO: check if actualy playing
            return
        }

        if state.isPlaying {
            stopCurrentPlayerActivity()
        }

        switch mediaID {
        case let .legacySimRadio(stationID):
            simRadio?.playStation(withID: stationID)
        case let .simRadio(stationID):
            simRadio?.playStation(withID: stationID)
        }
        state = .playing(mediaID)
        let profile = CommandProfile(isLiveStream: true, isSwitchTrackEnabled: items.count > 1)
        setCommandProfile(profile)
        setStemMediaInterfaceNowPlayingInfo()
    }

    func stopCurrentPlayerActivity() {
        if state.isPlaying, let mediaID = state.currentMediaID {
            switch mediaID {
            case .legacySimRadio:
                simRadio?.stop()
            case let .simRadio(stationID):
                print("stop", stationID.value)
            }
        }
    }

    func setCommandProfile(_ profile: CommandProfile) {
        systemMediaInterface.setRemoteCommandProfile(profile)
        commandProfile = profile
    }

    func setStemMediaInterfaceNowPlayingInfo() {
        guard let mediaID = state.currentMediaID,
              let mediaIndex = items.firstIndex(of: mediaID)
        else { return }
        Task {
            nowPlayingMeta = await mediaState?.nowPlayingMetaOfMedia(withID: mediaID)
            guard let nowPlayingMeta else { return }
            systemMediaInterface.setNowPlayingInfo(
                .init(
                    meta: nowPlayingMeta,
                    isPlaying: state.isPlaying,
                    queue: .init(index: mediaIndex, count: items.count),
                    progress: progress
                )
            )
        }
    }
}

extension MediaPlayerState {
    var currentMediaID: MediaID? {
        switch self {
        case let .paused(mediaID): mediaID
        case let .playing(mediaID): mediaID
        }
    }

    var isPlaying: Bool {
        if case .playing = self {
            return true
        }
        return false
    }
}

// MARK: - AudioSessionDelegate Implementation

extension MediaPlayer: AudioSessionDelegate {
    func audioSessionInterruptionBegan() {
        audioSession.setActive(false)
        guard case let .playing(mediaID) = state else { return }
        interruptedMediaID = mediaID
        pause()
    }

    func audioSessionInterruptionEnded(shouldResume: Bool) {
        audioSession.setActive(true)
        guard let mediaToResume = interruptedMediaID else { return }
        interruptedMediaID = nil
        if shouldResume, let resumeIndex = items.firstIndex(of: mediaToResume) {
            playItem(at: resumeIndex)
        }
    }
}

// MARK: - SystemMediaInterfaceDelegate Implementation

extension MediaPlayer: SystemMediaInterfaceDelegate {
    func systemMediaInterface(_: SystemMediaInterface, didReceiveRemoteCommand command: RemoteCommand) {
        print("MediaPlayer: Received remote command: \(command)")
        switch command {
        case .play:
            play()
        case .stop, .pause:
            pause()
        case .togglePausePlay:
            togglePlayPause()
        case .nextTrack:
            forward()
        case .previousTrack:
            backward()
        }
    }
}

extension MediaPlayer: SimRadioMediaPlayerDelegate {
    func simRadioMediaPlayer(_: any SimRadioMediaPlayer, didUpdateSpectrum spectrum: [Float]) {
        palyIndicatorSpectrum = spectrum
    }
}

extension SimRadioMediaState {
    func nowPlayingMetaOfMedia(withID id: MediaID) async -> NowPlayingInfo.Meta? {
        switch id {
        case let .legacySimRadio(id):
            await legacySimRadio.stations[id]?.meta.nowPlayingMeta
        case let .simRadio(id):
            await simRadio.stations[id]?.meta.nowPlayingMeta
        }
    }
}

extension SimRadioMediaState {
    var defaultPlayItems: (media: MediaID, items: [MediaID])? {
        let items = legacySimRadio.stations.keys.map { MediaID.legacySimRadio($0) }
        guard !items.isEmpty,
              let media = items.randomElement() else { return nil }
        return (media, items)
    }
}

extension SimStationMeta {
    var nowPlayingMeta: NowPlayingInfo.Meta {
        get async {
            let image: UIImage = await artwork?.image ?? UIImage()
            return .init(
                title: title,
                artwork: image,
                artist: host,
                genre: genre,
                isLiveStream: true
            )
        }
    }
}
