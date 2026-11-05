//
//  MediaPlayer.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 30.11.2024.
//

import Combine
import MediaLibrary
import UIKit

public enum PlaybackStatus: Equatable, Sendable {
    case loading
    case playing
    case failed(String)
}

public enum MediaPlayerState: Equatable, Hashable {
    case loading(media: MediaID, mode: MediaPlaybackMode.ID?)
    case failed(media: MediaID, mode: MediaPlaybackMode.ID?, message: String)
    case playing(media: MediaID, mode: MediaPlaybackMode.ID?)
    case paused(media: MediaID?, mode: MediaPlaybackMode.ID?)
}

@MainActor
public final class MediaPlayer {
    public enum Const {
        public static let frequencyBands = 5
    }

    struct MediaMode {
        let media: MediaID
        let mode: MediaPlaybackMode.ID?
    }

    public var simPlayer: SimRadioMediaPlayer?
    public var realPlayer: RealRadioMediaPlayer?

    public weak var mediaState: MediaState?
    private(set) var items: [MediaID] = []

    @Published private(set) var progress: NowPlayingInfo.Progress?
    @Published public private(set) var state: MediaPlayerState
    @Published public private(set) var commandProfile: CommandProfile?
    @Published public private(set) var playIndicatorSpectrum: [Float]
    @Published public private(set) var playbackModes: [MediaPlaybackMode] = []
    @Published public private(set) var nowPlayingMeta: MediaMeta?

    private var audioSession: AudioSession
    private var systemMediaInterface: SystemMediaInterface
    /// For handling interruptions
    private var interruptedMedia: MediaMode?

    public init() {
        audioSession = AudioSession()
        systemMediaInterface = SystemMediaInterface()
        state = .paused(media: .none, mode: .none)
        commandProfile = CommandProfile(isLiveStream: true, isSwitchTrackEnabled: false)
        playIndicatorSpectrum = .init(repeating: 0, count: Const.frequencyBands)
        systemMediaInterface.setRemoteCommandProfile(commandProfile!)
        audioSession.delegate = self
        systemMediaInterface.delegate = self
    }

    // MARK: - Public Playback Controls

    public func togglePlayPause() {
        if state.isActive {
            pause()
        } else {
            play(mode: state.currentMediaMode)
        }
    }

    public func play(mode: MediaPlaybackMode.ID?) {
        guard !state.isActive || state.currentMediaMode != mode else { return }
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

    public func play(_ mediaID: MediaID, of items: [MediaID], mode: MediaPlaybackMode.ID? = nil) {
        guard let index = items.firstIndex(of: mediaID) else {
            print("MediaPlayer Error: there is no mediaID \(mediaID) in items.")
            return
        }
        self.items = items
        playItem(at: index, mode: mode)
    }

    func pause() {
        guard state.isActive, let mediaID = state.currentMediaID else {
            print("MediaPlayer: Not playing, cannot pause.")
            return
        }
        stopCurrentPlayerActivity()
        state = .paused(media: mediaID, mode: state.currentMediaMode)
        updateMeta()
    }

    public func forward() {
        guard items.count > 1,
              let mediaID = state.currentMediaID,
              let index = items.firstIndex(of: mediaID)
        else {
            return
        }
        let nextIndex = items.indices.contains(index + 1) ? index + 1 : 0
        goToItem(at: nextIndex)
    }

    public func backward() {
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
    func receive(_ status: PlaybackStatus, for mediaID: MediaID) {
        guard state.isActive, state.currentMediaID == mediaID else { return }
        let mode = state.currentMediaMode
        switch status {
        case .loading:
            state = .loading(media: mediaID, mode: mode)
        case .playing:
            state = .playing(media: mediaID, mode: mode)
        case let .failed(message):
            stopCurrentPlayerActivity()
            state = .failed(media: mediaID, mode: mode, message: message)
            playIndicatorSpectrum = .init(repeating: 0, count: Const.frequencyBands)
        }
        updateMeta()
    }

    func goToItem(at index: Int) {
        guard let newMedia = items[safe: index] else {
            fatalError("MediaPlayer Error: Invalid index \(index)")
        }
        switch state {
        case let .playing(media, _), let .loading(media, _):
            if newMedia != media {
                playItem(at: index, mode: nil)
            }
        case .paused, .failed:
            if newMedia != state.currentMediaID {
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

        if state.isActive, state.currentMediaID == mediaID, state.currentMediaMode == mode {
            print("MediaPlayer: Already playing \(mediaID).")
            return
        }

        if state.isActive {
            stopCurrentPlayerActivity()
        }

        state = .loading(media: mediaID, mode: mode)
        audioSession.setActive(true)
        switch mediaID {
        case let .realRadio(id):
            realPlayer?.playStation(withID: id)
        case .simRadio:
            simPlayer?.playStation(withID: mediaID, mode: mode)
        }

        let profile = CommandProfile(isLiveStream: true, isSwitchTrackEnabled: items.count > 1)
        setCommandProfile(profile)
        updateMeta()
        updatePlaybackModes()
    }

    func stopCurrentPlayerActivity() {
        if state.isActive, let mediaID = state.currentMediaID {
            switch mediaID {
            case .realRadio:
                realPlayer?.stop()
            case .simRadio:
                simPlayer?.stop()
            }
        }
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

public extension MediaPlayerState {
    var currentMediaID: MediaID? {
        switch self {
        case let .paused(mediaID, _): mediaID
        case let .playing(mediaID, _), let .loading(mediaID, _), let .failed(mediaID, _, _): mediaID
        }
    }

    var currentMediaMode: MediaPlaybackMode.ID? {
        switch self {
        case let .paused(_, mode): mode
        case let .playing(_, mode), let .loading(_, mode), let .failed(_, mode, _): mode
        }
    }

    var isActive: Bool {
        switch self {
        case .playing, .loading: true
        case .paused, .failed: false
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
        guard state.isActive, let mediaID = state.currentMediaID else { return }
        interruptedMedia = .init(media: mediaID, mode: state.currentMediaMode)
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
    public func simRadioMediaPlayer(_: SimRadioMediaPlayer, stationID: MediaID,
                                    didChangeStatus status: PlaybackStatus)
    {
        receive(status, for: stationID)
    }

    public func simRadioMediaPlayer(_: any SimRadioMediaPlayer, didUpdateSpectrum spectrum: [Float]) {
        playIndicatorSpectrum = spectrum
    }

    public func simRadioMediaPlayer(_: SimRadioMediaPlayer, didCrossTrackMarker marker: AudioFragmentMarker?) {
        updateMeta(trackMarker: marker)
    }
}

extension MediaPlayer: RealRadioMediaPlayerDelegate {
    public func realRadioMediaPlayer(
        _: RealRadioMediaPlayer,
        stationID: RealStation.ID,
        didChangeStatus status: PlaybackStatus
    ) {
        receive(status, for: .realRadio(stationID))
    }

    public func realRadioMediaPlayer(_: any RealRadioMediaPlayer, didUpdateSpectrum spectrum: [Float]) {
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
