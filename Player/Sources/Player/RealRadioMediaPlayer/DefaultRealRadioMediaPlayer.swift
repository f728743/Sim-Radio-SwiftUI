//
//  DefaultRealRadioMediaPlayer.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.10.2025.
//

import AVFoundation
import Foundation
import MediaLibrary

@MainActor
public final class DefaultRealRadioMediaPlayer {
    public weak var mediaState: RealRadioMediaState?
    public weak var delegate: RealRadioMediaPlayerDelegate?

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var currentStationID: RealStation.ID?
    private var spectrumUpdateTimer: Timer?
    private var statusObservation: NSKeyValueObservation?
    private var spectrum = SimulatedSpectrum()
    private var playbackObservation: NSKeyValueObservation?
    private var generation = UUID()
    private var attemptedFallback = false

    public init() {}
}

// MARK: - RealRadioMediaPlayer

extension DefaultRealRadioMediaPlayer: RealRadioMediaPlayer {
    public func playStation(withID stationID: RealStation.ID) {
        guard let mediaState,
              let station = mediaState.realRadio.stations[stationID],
              let stream = station.streamResolved.toHTTPS
        else {
            delegate?.realRadioMediaPlayer(
                self,
                stationID: stationID,
                didChangeStatus: .failed("Station stream is unavailable.")
            )
            return
        }

        // Don't restart if already playing the same station
        if currentStationID == stationID, player?.rate != 0 {
            return
        }

        stop()
        currentStationID = stationID
        attemptedFallback = false

        print("Loading real radio station: \(station.title)")

        // Configure AVPlayer for streaming
        setupPlayerForStream(stream)
    }

    public func stop() {
        cleanup()
        print("Stopped real radio playback")
    }
}

private extension DefaultRealRadioMediaPlayer {
    func setupPlayerForStream(_ streamURL: URL) {
        generation = UUID()
        statusObservation = nil
        playbackObservation = nil
        player?.pause()
        stopSimulatedSpectrumUpdates()
        let assetOptions: [String: Any] = [
            AVURLAssetAllowsCellularAccessKey: true,
            AVURLAssetAllowsConstrainedNetworkAccessKey: true,
            AVURLAssetAllowsExpensiveNetworkAccessKey: true
        ]

        let asset = AVURLAsset(url: streamURL, options: assetOptions)
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)

        setupPlayerObservers()
        player?.play()
    }

    func setupPlayerObservers() {
        let generation = generation
        statusObservation = playerItem?.observe(\.status, options: [.new, .initial]) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                guard let self, self.generation == generation else { return }
                handlePlayerItemStatusChanged()
            }
        }
        playbackObservation = player?.observe(\.timeControlStatus, options: [.new]) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                guard let self, self.generation == generation, let stationID = currentStationID else { return }
                switch player?.timeControlStatus {
                case .playing:
                    delegate?.realRadioMediaPlayer(self, stationID: stationID, didChangeStatus: .playing)
                case .waitingToPlayAtSpecifiedRate:
                    delegate?.realRadioMediaPlayer(self, stationID: stationID, didChangeStatus: .loading)
                default: break
                }
            }
        }
    }

    func startSimulatedSpectrumUpdates() {
        spectrumUpdateTimer?.invalidate()
        spectrumUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateSpectrum()
            }
        }
    }

    func stopSimulatedSpectrumUpdates() {
        spectrumUpdateTimer?.invalidate()
        spectrumUpdateTimer = nil
    }

    func updatePlaybackState() {
        updateSpectrum()
    }

    func updateSpectrum() {
        let isPlaying = player?.rate != 0 && player?.error == nil
        let spectrum = isPlaying
            ? spectrum.generate()
            : [Float](repeating: 0, count: MediaPlayer.Const.frequencyBands)
        delegate?.realRadioMediaPlayer(self, didUpdateSpectrum: spectrum)
    }

    func cleanup() {
        generation = UUID()
        playbackObservation = nil
        player?.pause()
        player?.replaceCurrentItem(with: nil)

        statusObservation = nil

        stopSimulatedSpectrumUpdates()

        playerItem = nil
        player = nil
        currentStationID = nil
        spectrum.reset()
        delegate?.realRadioMediaPlayer(
            self,
            didUpdateSpectrum: .init(
                repeating: 0,
                count: MediaPlayer.Const.frequencyBands
            )
        )
    }

    func handlePlayerItemStatusChanged() {
        guard let playerItem else { return }

        switch playerItem.status {
        case .readyToPlay:
            startSimulatedSpectrumUpdates()
            print("Real radio stream ready to play")
        case .failed:
            if attemptedFallback {
                if let stationID = currentStationID {
                    delegate?.realRadioMediaPlayer(
                        self,
                        stationID: stationID,
                        didChangeStatus: .failed(playerItem.error?.localizedDescription ?? "Playback failed.")
                    )
                }
            } else {
                attemptFallbackPlayback()
            }
        case .unknown:
            print("Real radio stream state unknown")
        @unknown default:
            break
        }
    }

    func attemptFallbackPlayback() {
        guard let stationID = currentStationID,
              let station = mediaState?.realRadio.stations[stationID]
        else { return }
        print("Attempting fallback playback for: \(station.title)")
        attemptedFallback = true
        setupPlayerForStream(station.stream)
    }
}

extension URL {
    var toHTTPS: URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.scheme = "https"
        return components?.url
    }
}
