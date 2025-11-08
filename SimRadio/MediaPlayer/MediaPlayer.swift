//
//  MediaPlayer.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 30.11.2024.
//

import Combine
import UIKit

enum MediaPlayerState: Equatable, Hashable {
    case playing(media: MediaID, mode: MediaPlaybackMode.ID?)
    case paused(media: MediaID?, mode: MediaPlaybackMode.ID?)
}

@MainActor
class MediaPlayer {
    enum Const {
        static let frequencyBands = 5
    }

    struct MediaMode {
        let media: MediaID
        let mode: MediaPlaybackMode.ID?
    }

    var simPlayer: SimRadioMediaPlayer?
    var realPlayer: RealRadioMediaPlayer?

    weak var mediaState: MediaState?
    private(set) var items: [MediaID] = []

    @Published private(set) var progress: NowPlayingInfo.Progress?
    @Published private(set) var state: MediaPlayerState
    @Published private(set) var commandProfile: CommandProfile?
    @Published private(set) var playIndicatorSpectrum: [Float]
    @Published private(set) var playbackModes: [MediaPlaybackMode] = []
    @Published private(set) var nowPlayingMeta: MediaMeta?

    private var audioSession: AudioSession
    private var systemMediaInterface: SystemMediaInterface
    // For handling interruptions
    private var interruptedMedia: MediaMode?

    init() {
        audioSession = AudioSession()
        systemMediaInterface = SystemMediaInterface()
        state = .paused(media: .none, mode: .none)
        commandProfile = CommandProfile(isLiveStream: false, isSwitchTrackEnabled: false)
        playIndicatorSpectrum = .init(repeating: 0, count: Const.frequencyBands)
        systemMediaInterface.setRemoteCommandProfile(commandProfile!)
        audioSession.delegate = self
        systemMediaInterface.delegate = self
    }

    // MARK: - Public Playback Controls

    func togglePlayPause() {
        if state.isPlaying {
            pause()
        } else {
            play(mode: state.currentMediaMode)
        }
    }

    func play(mode: MediaPlaybackMode.ID?) {
        guard !state.isPlaying || state.currentMediaMode != mode else { return }
        if let mediaID = state.currentMediaID {
            guard let index = items.firstIndex(of: mediaID) else {
                print("MediaPlayer Error: there is no mediaID \(mediaID) in items.")
                return
            }
            playItem(at: index, mode: mode)
        } else if let playItems = mediaState?.defaultPlayItems {
            play(playItems.media, of: playItems.items, mode: mode)
        }
    }

    func play(_ mediaID: MediaID, of items: [MediaID], mode: MediaPlaybackMode.ID? = nil) {
        guard let index = items.firstIndex(of: mediaID) else {
            print("MediaPlayer Error: there is no mediaID \(mediaID) in items.")
            return
        }
        self.items = items
        playItem(at: index, mode: mode)
    }

    func pause() {
        guard case let .playing(mediaID, mode) = state else {
            print("MediaPlayer: Not playing, cannot pause.")
            return
        }
        stopCurrentPlayerActivity()
        state = .paused(media: mediaID, mode: mode)
        updateMeta()
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
        guard let newMedia = items[safe: index] else {
            fatalError("MediaPlayer Error: Invalid index \(index)")
        }
        switch state {
        case let .playing(media, _):
            if newMedia != media {
                playItem(at: index, mode: nil)
            }
        case let .paused(media, _):
            if newMedia != media {
                state = .paused(media: items[index], mode: nil)
                updateMeta()
                updatePlaybackModes()
            }
        }
    }

    func playItem(at index: Int, mode: MediaPlaybackMode.ID?) {
        guard let mediaID = items[safe: index] else {
            fatalError("MediaPlayer Error: Invalid index \(index)")
        }

        if case let .playing(currentID, currentMode) = state,
           currentID == mediaID, currentMode == mode
        {
            print("MediaPlayer: Already playing \(mediaID).")
            return
        }

        if state.isPlaying {
            stopCurrentPlayerActivity()
        }

        audioSession.setActive(true)
        switch mediaID {
        case let .realRadio(id):
            realPlayer?.playStation(withID: id)
        case .simRadio:
            simPlayer?.playStation(withID: mediaID, mode: mode)
        }

        state = .playing(media: mediaID, mode: mode)
        let profile = CommandProfile(isLiveStream: true, isSwitchTrackEnabled: items.count > 1)
        setCommandProfile(profile)
        updateMeta()
        updatePlaybackModes()
    }

    func stopCurrentPlayerActivity() {
        if state.isPlaying, let mediaID = state.currentMediaID {
            switch mediaID {
            case .realRadio:
                realPlayer?.stop()
            case .simRadio:
                simPlayer?.stop()
            }
        }
        audioSession.setActive(false)
    }

    func setCommandProfile(_ profile: CommandProfile) {
        systemMediaInterface.setRemoteCommandProfile(profile)
        commandProfile = profile
    }

    func setSytemMediaInterfaceNowPlayingInfo() {
        guard let mediaID = state.currentMediaID,
              let mediaIndex = items.firstIndex(of: mediaID)
        else { return }
        Task {
            guard let nowPlayingMeta else { return }
            let artwork = await nowPlayingMeta.artwork?.image ?? UIImage()
            systemMediaInterface.setNowPlayingInfo(
                .init(
                    meta: nowPlayingMeta,
                    artwork: artwork,
                    isPlaying: state.isPlaying,
                    queue: .init(index: mediaIndex, count: items.count),
                    progress: progress
                )
            )
        }
    }

    func updatePlaybackModes() {
        guard let mediaID = state.currentMediaID else {
            playbackModes = []
            return
        }
        if mediaID.isSimRadio {
            playbackModes = simPlayer?.availableModes(stationID: mediaID) ?? []
        } else {
            playbackModes = []
        }
    }

    func updateMeta(trackMarker marker: AudioFragmentMarker? = nil) {
        Task {
            guard
                let mediaID = state.currentMediaID,
                let newNowPlayingMeta = await mediaState?.nowPlayingMetaOfMedia(
                    withID: mediaID,
                    marker: marker?.value
                )
            else { return }
            nowPlayingMeta = newNowPlayingMeta
            setSytemMediaInterfaceNowPlayingInfo()
        }
    }
}

extension MediaPlayerState {
    var currentMediaID: MediaID? {
        switch self {
        case let .paused(mediaID, _): mediaID
        case let .playing(mediaID, _): mediaID
        }
    }

    var currentMediaMode: MediaPlaybackMode.ID? {
        switch self {
        case let .paused(_, mode): mode
        case let .playing(_, mode): mode
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
        guard case let .playing(mediaID, mode) = state else { return }
        interruptedMedia = .init(media: mediaID, mode: mode)
        pause()
    }

    func audioSessionInterruptionEnded(shouldResume: Bool) {
        audioSession.setActive(true)
        guard let mediaToResume = interruptedMedia else { return }
        interruptedMedia = nil
        if shouldResume, let resumeIndex = items.firstIndex(of: mediaToResume.media) {
            playItem(at: resumeIndex, mode: mediaToResume.mode)
        }
    }
}

// MARK: - SystemMediaInterfaceDelegate Implementation

extension MediaPlayer: SystemMediaInterfaceDelegate {
    func systemMediaInterface(_: SystemMediaInterface, didReceiveRemoteCommand command: RemoteCommand) {
        print("MediaPlayer: Received remote command: \(command)")
        switch command {
        case .play:
            play(mode: state.currentMediaMode)
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
        playIndicatorSpectrum = spectrum
    }

    func simRadioMediaPlayer(_: SimRadioMediaPlayer, didCrossTrackMarker marker: AudioFragmentMarker?) {
        updateMeta(trackMarker: marker)
    }
}

extension MediaPlayer: RealRadioMediaPlayerDelegate {
    func realRadioMediaPlayer(_: any RealRadioMediaPlayer, didUpdateSpectrum spectrum: [Float]) {
        playIndicatorSpectrum = spectrum
    }
}

extension MediaState {
    func nowPlayingMetaOfMedia(
        withID id: MediaID,
        marker: AudioFragmentMarkerValue?
    ) async -> MediaMeta? {
        guard let meta = metaOfMedia(withID: id) else {
            return nil
        }

        return .init(
            artwork: meta.artwork,
            title: marker?.title ?? meta.title,
            subtitle: meta.subtitle,
            description: marker?.artist ?? meta.description,
            artist: marker?.artist ?? meta.artist,
            genre: marker != nil ? nil : meta.genre,
            isLiveStream: meta.isLiveStream,
            timestamp: meta.timestamp
        )
    }
}
