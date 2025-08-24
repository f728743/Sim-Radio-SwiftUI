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
    func playStation(withID stationID: MediaID) {
        Task {
            do {
                try await doPlayStation(withID: stationID)
            } catch {
                print(error)
            }
        }
    }

    func stop() {
        queuePlayer.removeAllItems()
        playToEndTask?.cancel()
        playToEndTask = nil
        removePeriodicTimeObserver()
        currentMarkers = nil
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

        let markers: [AudioFragmentMarker]?
    }

    func doPlayStation(withID stationID: MediaID) async throws {
        removePeriodicTimeObserver()

        let startingDate = Date()
//        let startingDate = Date("03.05.2025 00:02:35")
        let startingTime = CMTime(seconds: startingDate.currentSecondOfDay)

        let playlistItem = try await makePlaylistItem(
            stationID: stationID,
            startingOn: startingDate,
            at: .init(seconds: startingDate.currentSecondOfDay)
        )

        currentMarkers = playlistItem.track.markers
        lastBroadcastedMarker = nil

        let loader = PlayerItemLoader()
        let playerItem = try await loader.loadPlayerItem(
            playlistItem: playlistItem,
            tapProcessor: audioTapProcessor
        )

        addPeriodicTimeObserver()

        queuePlayer.insert(playerItem, after: nil)
        queuePlayer.play()
        addDidPlayToEndObserver(to: playerItem)

        guard let nextPlayableItem = try await makeNextPlayableItem(
            stationID: stationID,
            date: startingDate + playlistItem.duration.seconds,
            time: (startingTime + playlistItem.duration).wrappedDay
        ) else {
            throw PlayerItemLoadingError.playerItemCreatingError
        }
        self.nextPlayableItem = nextPlayableItem
        queuePlayer.insert(nextPlayableItem.item, after: nil)
    }

    func makePlaylistItem(
        stationID: MediaID,
        startingOn startingDate: Date,
        at startingTime: CMTime
    ) async throws -> PlaylistItem {
        switch stationID {
        case let .simRadio(id):
            try await makePlaylistItem(
                stationID: id,
                startingOn: startingDate,
                at: startingTime
            )
        }
    }

    func makePlaylistItem(
        stationID: SimStation.ID,
        startingOn startingDate: Date,
        at startingTime: CMTime
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
            mode: stationData.station.playlistRules.defaultMode
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
                time: nextPlayableItem.startTimeInDay
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
        time: CMTime
    ) async throws -> NextPlayableItem? {
        let playlistItem = try await makePlaylistItem(
            stationID: stationID,
            startingOn: date,
            at: time
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
