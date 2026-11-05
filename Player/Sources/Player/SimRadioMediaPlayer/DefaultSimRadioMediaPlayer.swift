//
//  DefaultSimRadioMediaPlayer.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 01.05.2025.
//

import AVFoundation
import MediaLibrary

@MainActor
public final class DefaultSimRadioMediaPlayer {
    public weak var mediaState: SimRadioMediaState?
    public weak var delegate: SimRadioMediaPlayerDelegate?
    private let queuePlayer = AVQueuePlayer()
    private let audioTapProcessor: AudioTapProcessor
    private var nextPlayableItem: NextPlayableItem?
    private var playToEndTask: Task<Void, Never>?
    private var playTask: Task<Void, Never>?
    private var advanceTask: Task<Void, Never>?
    private var playbackObservation: NSKeyValueObservation?
    private var currentItemObservation: NSKeyValueObservation?
    private var itemStatusObservation: NSKeyValueObservation?
    private var generation = UUID()
    private var playlistBuilder: PlaylistBuilder?

    private var currentRequestedStationID: MediaID?
    private var currentRequestedMode: MediaPlaybackMode.ID?

    private var timeObserverToken: Any?
    private var currentMarkers: [AudioFragmentMarker]?
    private var lastBroadcastedMarker: AudioFragmentMarker?
    private var forceMarkerUpdate: Bool = false

    public init() {
        audioTapProcessor = AudioTapProcessor(
            frequencyBands: MediaPlayer.Const.frequencyBands
        )
        audioTapProcessor.delegate = self
    }
}

extension DefaultSimRadioMediaPlayer: SimRadioMediaPlayer {
    public func playStation(withID stationID: MediaID, mode: MediaPlaybackMode.ID?) {
        stop()
        let generation = generation

        currentRequestedStationID = stationID
        currentRequestedMode = mode
        observePlayback(generation: generation)

        playTask = Task { [weak self] in
            guard let self, !Task.isCancelled, self.generation == generation else { return }

            do {
                try await doPlayStation(withID: stationID, mode: mode)
            } catch {
                guard !Task.isCancelled, self.generation == generation else { return }
                delegate?.simRadioMediaPlayer(
                    self,
                    stationID: stationID,
                    didChangeStatus: .failed(error.localizedDescription)
                )
            }
        }
    }

    public func stop() {
        generation = UUID()
        advanceTask?.cancel()
        advanceTask = nil
        playbackObservation = nil
        currentItemObservation = nil
        itemStatusObservation = nil
        nextPlayableItem = nil
        playlistBuilder = nil
        queuePlayer.pause()
        queuePlayer.removeAllItems()
        playTask?.cancel()
        playTask = nil
        playToEndTask?.cancel()
        playToEndTask = nil
        removePeriodicTimeObserver()
        currentMarkers = nil
        currentRequestedStationID = nil
        currentRequestedMode = nil
    }

    public func availableModes(stationID: MediaID) -> [MediaPlaybackMode] {
        switch stationID {
        case let .simRadio(id):
            guard let mediaState,
                  let stationData = mediaState.stationData(for: id)
            else {
                return []
            }
            return stationData.station.playlistRules.availableModes
        case .realRadio:
            return []
        }
    }
}

extension DefaultSimRadioMediaPlayer: AudioTapProcessorDelegate {
    nonisolated func audioTapProcessor(_: AudioTapProcessor, didUpdateSpectrum spectrum: [[Float]]) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            delegate?.simRadioMediaPlayer(
                self,
                didUpdateSpectrum: spectrum.first ??
                    .init(repeating: 0, count: MediaPlayer.Const.frequencyBands)
            )
        }
    }
}

private extension DefaultSimRadioMediaPlayer {
    /// Represents the next media item to be queued for playback
    struct NextPlayableItem {
        let stationID: MediaID
        let item: AVPlayerItem
        /// Reference date used to calculate the day boundary for playback scheduling
        let day: Date
        /// Precise time offset within the day for playback scheduling
        /// - Value represents seconds since start of day (00:00)
        let startTimeInDay: CMTime
        let mode: MediaPlaybackMode.ID?
        let markers: [AudioFragmentMarker]?
    }

    func doPlayStation(withID stationID: MediaID, mode: MediaPlaybackMode.ID?) async throws {
        removePeriodicTimeObserver()
        try Task.checkCancellation()
        guard currentRequestedStationID == stationID, currentRequestedMode == mode else {
            throw CancellationError()
        }

        let startingDate = Date()
        let startingTime = CMTime(seconds: startingDate.currentSecondOfDay)

        let playlistItem = try await makePlaylistItem(
            stationID: stationID,
            startingOn: startingDate,
            at: .init(seconds: startingDate.currentSecondOfDay),
            mode: mode
        )
        try Task.checkCancellation()
        guard currentRequestedStationID == stationID, currentRequestedMode == mode else {
            throw CancellationError()
        }

        currentMarkers = playlistItem.track.markers
        lastBroadcastedMarker = nil
        forceMarkerUpdate = true

        let loader = PlayerItemLoader()
        let playerItem = try await loader.loadPlayerItem(
            playlistItem: playlistItem,
            tapProcessor: audioTapProcessor
        )
        try Task.checkCancellation()
        guard currentRequestedStationID == stationID, currentRequestedMode == mode else {
            throw CancellationError()
        }

        queuePlayer.insert(playerItem, after: nil)
        queuePlayer.play()
        addDidPlayToEndObserver(to: playerItem)
        addPeriodicTimeObserver()

        guard let nextPlayableItem = try await makeNextPlayableItem(
            stationID: stationID,
            date: startingDate + playlistItem.duration.seconds,
            time: (startingTime + playlistItem.duration).wrappedDay,
            mode: mode
        ) else {
            throw PlayerItemLoadingError.playerItemCreatingError
        }

        try Task.checkCancellation()
        guard currentRequestedStationID == stationID, currentRequestedMode == mode else {
            throw CancellationError()
        }

        enqueue(nextPlayableItem)
    }

    func makePlaylistItem(
        stationID: MediaID,
        startingOn startingDate: Date,
        at startingTime: CMTime,
        mode: MediaPlaybackMode.ID?
    ) async throws -> PlaylistItem {
        switch stationID {
        case let .simRadio(id):
            try await makePlaylistItem(
                stationID: id,
                startingOn: startingDate,
                at: startingTime,
                modeID: mode
            )
        case .realRadio:
            throw PlayerItemLoadingError.playerItemCreatingError
        }
    }

    func makePlaylistItem(
        stationID: SimStation.ID,
        startingOn startingDate: Date,
        at startingTime: CMTime,
        modeID: MediaPlaybackMode.ID?
    ) async throws -> PlaylistItem {
        guard let mediaState,
              let stationData = mediaState.stationData(for: stationID)
        else {
            throw PlayerItemLoadingError.playerItemCreatingError
        }
        let playlistBuilder = playlistBuilder ?? PlaylistBuilder(stationData: stationData)
        self.playlistBuilder = playlistBuilder
        return try await playlistBuilder.makePlaylistItem(
            startingOn: startingDate,
            at: startingTime,
            mode: stationData.station.playlistRules.mode(for: modeID)
        )
    }

    func onPlayerItemDidPlayToEndTime() {
        guard let nextPlayableItem else {
            if let stationID = currentRequestedStationID {
                delegate?.simRadioMediaPlayer(self, stationID: stationID, didChangeStatus: .loading)
            }
            return
        }
        self.nextPlayableItem = nil
        let generation = generation
        addDidPlayToEndObserver(to: nextPlayableItem.item)
        currentMarkers = nextPlayableItem.markers
        lastBroadcastedMarker = nil
        forceMarkerUpdate = true
        addPeriodicTimeObserver()
        advanceTask?.cancel()
        advanceTask = Task { [weak self] in
            guard let self else { return }
            do {
                guard let next = try await makeNextPlayableItem(
                    stationID: nextPlayableItem.stationID,
                    date: nextPlayableItem.day,
                    time: nextPlayableItem.startTimeInDay,
                    mode: nextPlayableItem.mode
                ) else { throw PlayerItemLoadingError.playerItemCreatingError }
                try Task.checkCancellation()
                guard self.generation == generation else { return }
                enqueue(next)
            } catch {
                guard !Task.isCancelled, self.generation == generation else { return }
                delegate?.simRadioMediaPlayer(
                    self,
                    stationID: nextPlayableItem.stationID,
                    didChangeStatus: .failed(error.localizedDescription)
                )
            }
        }
    }

    func enqueue(_ next: NextPlayableItem) {
        let wasEmpty = queuePlayer.currentItem == nil
        nextPlayableItem = next
        queuePlayer.insert(next.item, after: nil)
        if wasEmpty {
            // Preparation finished after the previous item had already ended.
            onPlayerItemDidPlayToEndTime()
            queuePlayer.play()
        }
    }

    func observePlayback(generation: UUID) {
        playbackObservation = queuePlayer.observe(\.timeControlStatus, options: [.new]) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                guard let self, self.generation == generation,
                      let stationID = currentRequestedStationID else { return }
                switch queuePlayer.timeControlStatus {
                case .playing:
                    delegate?.simRadioMediaPlayer(self, stationID: stationID, didChangeStatus: .playing)
                case .waitingToPlayAtSpecifiedRate:
                    delegate?.simRadioMediaPlayer(self, stationID: stationID, didChangeStatus: .loading)
                default: break
                }
            }
        }
        currentItemObservation = queuePlayer.observe(\.currentItem, options: [.new]) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                guard let self, self.generation == generation else { return }
                observeCurrentItem(generation: generation)
            }
        }
    }

    func observeCurrentItem(generation: UUID) {
        itemStatusObservation = queuePlayer.currentItem?.observe(\.status, options: [
            .initial,
            .new
        ]) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                guard let self, self.generation == generation,
                      let stationID = currentRequestedStationID,
                      let item = queuePlayer.currentItem, item.status == .failed else { return }
                delegate?.simRadioMediaPlayer(
                    self,
                    stationID: stationID,
                    didChangeStatus: .failed(item.error?.localizedDescription ?? "Playback failed.")
                )
            }
        }
    }

    func addDidPlayToEndObserver(to item: AVPlayerItem) {
        playToEndTask?.cancel()
        playToEndTask = Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(
                named: .AVPlayerItemDidPlayToEndTime,
                object: item
            )

            for await _ in notifications {
                guard !Task.isCancelled else { break }
                self?.onPlayerItemDidPlayToEndTime()
            }
        }
    }

    func addPeriodicTimeObserver() {
        removePeriodicTimeObserver()
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))

        timeObserverToken = queuePlayer.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                self?.processPlaybackTime(time)
            }
        }
    }

    func processPlaybackTime(_ time: CMTime) {
        let currentMarker: AudioFragmentMarker?

            // Determine the current marker (it can be nil if there are no markers)
            = if let markers = currentMarkers, !markers.isEmpty
        {
            markers.last { time >= $0.offset }
        } else {
            nil
        }

        // Check if the marker has changed OR this is a forced update
        if currentMarker != lastBroadcastedMarker || forceMarkerUpdate {
            lastBroadcastedMarker = currentMarker
            forceMarkerUpdate = false
            delegate?.simRadioMediaPlayer(self, didCrossTrackMarker: currentMarker)
        }
    }

    func removePeriodicTimeObserver() {
        if let token = timeObserverToken {
            queuePlayer.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }

    func makeNextPlayableItem(
        stationID: MediaID,
        date: Date,
        time: CMTime,
        mode: MediaPlaybackMode.ID?
    ) async throws -> NextPlayableItem? {
        let playlistItem = try await makePlaylistItem(
            stationID: stationID,
            startingOn: date,
            at: time,
            mode: mode
        )

        let loader = PlayerItemLoader()
        let playerItem = try await loader.loadPlayerItem(
            playlistItem: playlistItem,
            tapProcessor: audioTapProcessor
        )

        return NextPlayableItem(
            stationID: stationID,
            item: playerItem,
            day: date + playlistItem.duration.seconds,
            startTimeInDay: (time + playlistItem.duration).wrappedDay,
            mode: mode,
            markers: playlistItem.track.markers
        )
    }
}
