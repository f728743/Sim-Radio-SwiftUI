//
//  DefaultSimRadioMediaPlayer.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 01.05.2025.
//

import AVFoundation

@MainActor
class DefaultSimRadioMediaPlayer {
    weak var mediaState: SimRadioMediaState?
    weak var delegate: SimRadioMediaPlayerDelegate?

    private let queuePlayer = AVQueuePlayer()
    private let audioTapProcessor: AudioTapProcessor
    private var nextPlayableItem: NextPlayableItem?
    private var observer: NSObjectProtocol?
    private var playToEndTask: Task<Void, Never>?
    private var playTask: Task<Void, Never>?

    private var currentRequestedStationID: MediaID?
    private var currentRequestedMode: MediaPlaybackMode.ID?

    private var timeObserverToken: Any?
    private var currentMarkers: [AudioFragmentMarker]?
    private var lastBroadcastedMarker: AudioFragmentMarker?

    init() {
        audioTapProcessor = AudioTapProcessor(
            frequencyBands: MediaPlayer.Const.frequencyBands
        )
        audioTapProcessor.delegate = self
    }
}

extension DefaultSimRadioMediaPlayer: SimRadioMediaPlayer {
    func playStation(withID stationID: MediaID, mode: MediaPlaybackMode.ID?) {
        playTask?.cancel()

        // Save the ID of the new request
        // This will serve as a "generation identifier"
        currentRequestedStationID = stationID
        currentRequestedMode = mode

        playTask = Task { [weak self] in
            guard let self else { return }

            // If the task ID doesn't match the last requested ID,
            // then this task is outdated and should be terminated
            guard currentRequestedStationID == stationID, currentRequestedMode == mode else {
                // This task is outdated, just exit
                return
            }

            queuePlayer.removeAllItems()
            playToEndTask?.cancel()
            playToEndTask = nil

            do {
                try await doPlayStation(withID: stationID, mode: mode)
            } catch {
                if !Task.isCancelled {
                    // Log error only if it's from the *current* task
                    if currentRequestedStationID == stationID, currentRequestedMode == mode {
                        print("Playback error: \(error)")
                    }
                }
            }
        }
    }

    func stop() {
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

    func availableModes(stationID: MediaID) -> [MediaPlaybackMode] {
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
                didUpdateSpectrum: spectrum.first ?? .init(repeating: 0, count: MediaPlayer.Const.frequencyBands)
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
        /// - Important: Calendar operations should use this date's startOfDay
        let day: Date
        /// Precise time offset within the day for playback scheduling
        /// - Note: Uses CMTime for frame-accurate scheduling and AVFoundation compatibility
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

        guard let nextPlayableItem = try await makeNextPlayableItem(
            stationID: stationID,
            date: startingDate + playlistItem.duration.seconds,
            time: (startingTime + playlistItem.duration).wrappedDay,
            mode: mode
        ) else {
            throw PlayerItemLoadingError.playerItemCreatingError
        }

        // Check before updating nextPlayableItem
        try Task.checkCancellation()
        guard currentRequestedStationID == stationID, currentRequestedMode == mode else {
            throw CancellationError()
        }

        self.nextPlayableItem = nextPlayableItem
        queuePlayer.insert(nextPlayableItem.item, after: nil)
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
        let playlistBuilder = PlaylistBuilder(stationData: stationData)

        return try await playlistBuilder.makePlaylistItem(
            startingOn: startingDate,
//            at: .init(seconds: startingDate.currentSecondOfDay),
            at: startingTime,
            mode: stationData.station.playlistRules.mode(for: modeID)
        )
    }

    func onPlayerItemDidPlayToEndTime() {
        guard let nextPlayableItem else { return }
        addDidPlayToEndObserver(to: nextPlayableItem.item)
        removePeriodicTimeObserver()
        Task {
            guard let newNextPlayableItem = try await makeNextPlayableItem(
                stationID: nextPlayableItem.stationID,
                date: nextPlayableItem.day,
                time: nextPlayableItem.startTimeInDay,
                mode: nextPlayableItem.mode
            ) else { return }

            currentMarkers = nextPlayableItem.markers
            lastBroadcastedMarker = nil
            addPeriodicTimeObserver()
            queuePlayer.insert(newNextPlayableItem.item, after: nil)
            self.nextPlayableItem = newNextPlayableItem
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
        guard let markers = currentMarkers,
              !markers.isEmpty
        else {
            return
        }
        let currentMarker = markers.last { time >= $0.offset }
        if currentMarker != lastBroadcastedMarker {
            lastBroadcastedMarker = currentMarker
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

private extension Date {
    init(_ string: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        let someDateTime = formatter.date(from: string)
        self = someDateTime!
    }
}

extension SimRadioDTO.Playlist {
    var availableModes: [MediaPlaybackMode] {
        guard let options, options.available.isEmpty == false else { return [] }

        let alternate = options.alternateInterval.map { _ in
            [MediaPlaybackMode(id: .alternate, title: "Alternate")]
        } ?? []

        let available = options.available.map {
            MediaPlaybackMode(id: .init(value: $0.id.value), title: $0.title)
        }
        return alternate + available
    }
}

extension MediaPlaybackMode.ID {
    static var alternate: Self {
        .init(value: "alternate_playback")
    }
}

extension SimRadioDTO.Playlist {
    func mode(for id: MediaPlaybackMode.ID?) throws -> PlaylistBuilder.PlaylistMode? {
        guard let id else { return defaultMode }
        if id == .alternate {
            guard let interval = options?.alternateInterval else {
                throw PlaylistGenerationError.wrongMode
            }
            return .alternate(interval)
        }
        guard let option = options?.available.first(where: { $0.id.value == id.value }) else {
            throw PlaylistGenerationError.wrongMode
        }
        return .option(option.id)
    }

    private var defaultMode: PlaylistBuilder.PlaylistMode? {
        guard let options, options.available.isEmpty == false else { return nil }
        if let interval = options.alternateInterval {
            return .alternate(interval)
        }
        return options.available.first.map { .option($0.id) }
    }
}
