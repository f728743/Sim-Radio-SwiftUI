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
final class DefaultRealRadioMediaPlayer {
    weak var mediaState: RealRadioMediaState?
    weak var delegate: RealRadioMediaPlayerDelegate?

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var currentStationID: RealStation.ID?
    private var spectrumUpdateTimer: Timer?
    private var statusObservation: NSKeyValueObservation?
    private var spectrum = SimulatedSpectrum()
}

// MARK: - RealRadioMediaPlayer

extension DefaultRealRadioMediaPlayer: RealRadioMediaPlayer {
    func playStation(withID stationID: RealStation.ID) {
        guard let mediaState,
              let station = mediaState.realRadio.stations[stationID],
              let stream = station.streamResolved.toHTTPS
        else {
            return
        }

        // Don't restart if already playing the same station
        if currentStationID == stationID, player?.rate != 0 {
            return
        }

        stop()
        currentStationID = stationID

        print("Loading real radio station: \(station.title)")

        // Configure AVPlayer for streaming
        setupPlayerForStream(stream)
    }

    func stop() {
        cleanup()
        print("Stopped real radio playback")
    }
}

private extension DefaultRealRadioMediaPlayer {
    func setupPlayerForStream(_ streamURL: URL) {
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
        statusObservation = playerItem?.observe(\.status, options: [.new, .initial]) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.handlePlayerItemStatusChanged()
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
            if let error = playerItem.error {
                print("Error creating player item for real radio: \(error)")
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
        else {
            return
        }
        print("Attempting fallback playback for: \(station.title)")
        let fallbackPlayer = AVPlayer(url: station.stream)
        fallbackPlayer.play()
        player = fallbackPlayer
    }
}

extension URL {
    var toHTTPS: URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.scheme = "https"
        return components?.url
    }
}
