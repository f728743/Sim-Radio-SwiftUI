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

    init() {
        audioTapProcessor = AudioTapProcessor(
            frequencyBands: MediaPlayer.Const.frequencyBands
        )
        audioTapProcessor.delegate = self
    }
}

extension DefaultSimRadioMediaPlayer: SimRadioMediaPlayer {
    func playStation(withID stationID: SimStation.ID) {
        Task {
            do {
                try await doPlayStation(withID: stationID)
            } catch {
                print(error)
            }
        }
    }

    func playStation(withID stationID: LegacySimStation.ID) {
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
        let stationID: LegacySimStation.ID
        let item: AVPlayerItem
        /// Reference date used to calculate the day boundary for playback scheduling
        /// - Important: Calendar operations should use this date's startOfDay
        let day: Date
        /// Precise time offset within the day for playback scheduling
        /// - Note: Uses CMTime for frame-accurate scheduling and AVFoundation compatibility
        /// - Value represents seconds since start of day (00:00)
        let startTimeInDay: CMTime
    }

    func doPlayStation(withID stationID: SimStation.ID) async throws {
        guard let mediaState else { return }

        guard let stationData = mediaState.stationData(for: stationID) else { return }
        let playlistBuilder = PlaylistBuilder(stationData: stationData)
        let startingDate = Date()
        let startingTime = CMTime(seconds: startingDate.currentSecondOfDay)

        let playlistOption = (stationData.station.playlistRules?.options?.available ?? []).last.map(\.id)

        guard let playlistRules = stationData.station.playlistRules else {
            return
        }

        let playlistItem = try await playlistBuilder.makePlaylistItem(
            startingOn: startingDate,
            at: .init(seconds: startingDate.currentSecondOfDay),
            mode: playlistRules.defaultMode
        )
    }

    func doPlayStation(withID stationID: LegacySimStation.ID) async throws {
        guard let mediaState else { return }

        guard let stationData = mediaState.stationData(for: stationID) else { return }
        let playlistBuilder = LegacyPlaylistBuilder(stationData: stationData)
        let startingDate = Date()
        let startingTime = CMTime(seconds: startingDate.currentSecondOfDay)

        let playlistItem = try await playlistBuilder.makePlaylistItem(
            startingOn: startingDate,
            at: .init(seconds: startingDate.currentSecondOfDay)
        )

        let loader = PlayerItemLoader()
        let playerItem = try await loader.loadPlayerItem(
            playlistItem: playlistItem,
            tapProcessor: audioTapProcessor
        )

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

    func onPlayerItemDidPlayToEndTime() {
        guard let nextPlayableItem else { return }
        addDidPlayToEndObserver(to: nextPlayableItem.item)
        Task {
            guard let newNextPlayableItem = try await makeNextPlayableItem(
                stationID: nextPlayableItem.stationID,
                date: nextPlayableItem.day,
                time: nextPlayableItem.startTimeInDay
            ) else { return }
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

    func makeNextPlayableItem(
        stationID: LegacySimStation.ID,
        date: Date,
        time: CMTime
    ) async throws -> NextPlayableItem? {
        guard let stationData = mediaState?.stationData(for: stationID) else { return nil }
        let playlistBuilder = LegacyPlaylistBuilder(stationData: stationData)
        let playlistItem = try await playlistBuilder.makePlaylistItem(
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
            startTimeInDay: (time + playlistItem.duration).wrappedDay
        )
    }
}
