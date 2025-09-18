//
//  PlayerItemLoader.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 03.05.2025.
//

@preconcurrency import AVFoundation

@MainActor
class PlayerItemLoader {
    private var playerItemStatusObserver: NSKeyValueObservation?

    func loadPlayerItem(
        playlistItem: PlaylistItem,
        tapProcessor: AudioTapProcessor
    ) async throws -> AVPlayerItem {
        let composition = AVMutableComposition()
        let audioMix = AVMutableAudioMix()
        guard let mainTrack = composition.addAudioTrack(),
              let mixTrack = composition.addAudioTrack()
        else {
            throw PlayerItemLoadingError.playerItemCreatingError
        }
        let params = AVMutableAudioMixInputParameters(track: mainTrack)

        let tap = try tapProcessor.makeTap()
        params.audioTapProcessor = tap

        try await load(playlistItem.track, track: mainTrack)
        for mix in playlistItem.mixes {
            try await load(mix, track: mixTrack)
            params.setVolumeDip(
                range: .init(
                    start: mix.startTime,
                    duration: mix.playing.duration
                )
            )
        }
        audioMix.inputParameters = [params]
        let playerItem = AVPlayerItem(asset: composition)
        playerItem.audioMix = audioMix

        return playerItem
    }
}

private extension PlayerItemLoader {
    func load(
        _ audio: AudioFragment,
        track: AVMutableCompositionTrack
    ) async throws {
        let asset = AVURLAsset(url: audio.url)
        guard let assetTrack = try await asset.loadTracks(withMediaType: .audio).first else {
            throw PlayerItemLoadingError.fileNotFound(url: audio.url)
        }
        try track.insertTimeRange(
            audio.timeRange,
            of: assetTrack,
            at: audio.startTime
        )
    }
}

extension AVMutableComposition {
    func addAudioTrack() -> AVMutableCompositionTrack? {
        addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
    }
}

struct VolumeDipParams {
    let normalVolume: Float
    let lowVolume: Float
    let fadingDuration: CMTime
}

extension VolumeDipParams {
    static let `default` = VolumeDipParams(
        normalVolume: 1,
        lowVolume: 0.3,
        fadingDuration: .init(seconds: 1)
    )
}

extension AVMutableAudioMixInputParameters {
    func setVolumeDip(
        range: CMTimeRange,
        params: VolumeDipParams = .default
    ) {
        let fadeOutEnd = range.start
        let fadeOutStart = fadeOutEnd - params.fadingDuration
        let fadeInStart = range.end
        let fadeInEnd = fadeInStart + params.fadingDuration

        setVolumeRamp(
            fromStartVolume: params.normalVolume,
            toEndVolume: params.lowVolume,
            timeRange: CMTimeRange(start: fadeOutStart, end: fadeOutEnd)
        )

        setVolumeRamp(
            fromStartVolume: params.lowVolume,
            toEndVolume: params.normalVolume,
            timeRange: CMTimeRange(start: fadeInStart, end: fadeInEnd)
        )
    }
}
