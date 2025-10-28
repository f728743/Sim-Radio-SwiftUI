//
//  DefaultRealRadioMediaPlayer.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.10.2025.
//

import AVFoundation
import Foundation

@MainActor
class DefaultRealRadioMediaPlayer {
    weak var mediaState: RealRadioMediaState?
    weak var delegate: RealRadioMediaPlayerDelegate?
    private var player: AVPlayer?
}

extension DefaultRealRadioMediaPlayer: RealRadioMediaPlayer {
    func playStation(withID stationID: RealStation.ID) {
        guard let mediaState, let station = mediaState.realRadio.stations[stationID] else {
            print("Error: Could not find real station with ID \(stationID)")
            return
        }

        guard let streamURL = station.streamResolved?.toHTTPS else {
            print("Error: no stream")
            return
        }

        stop()

        Task {
            do {
                // Asynchronously create the player item and attach the audio tap
                let item = try await createPlayerItem(with: streamURL)

                let player = AVPlayer(playerItem: item)
                self.player = player
                player.play()
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func stop() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
    }

    private func createPlayerItem(with url: URL) async throws -> AVPlayerItem {
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        return item
    }
}

extension URL {
    var toHTTPS: URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.scheme = "https"
        return components?.url
    }
}
