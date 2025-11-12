//
//  NowPlayingInfo.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 08.05.2025.
//

import MediaLibrary
import UIKit

struct NowPlayingInfo {
    let meta: MediaMeta
    let artwork: UIImage
    let isPlaying: Bool
    let queue: Queue?
    let progress: Progress?

    init(
        meta: MediaMeta,
        artwork: UIImage,
        isPlaying: Bool,
        queue: Queue? = nil,
        progress: Progress? = nil
    ) {
        self.meta = meta
        self.artwork = artwork
        self.isPlaying = isPlaying
        self.queue = queue
        self.progress = progress
    }

    struct Queue {
        let index: Int
        let count: Int
    }

    struct Progress {
        let elapsedTime: TimeInterval
        let duration: TimeInterval
    }
}

extension NowPlayingInfo {
    func playing(_ playing: Bool) -> NowPlayingInfo {
        .init(
            meta: meta,
            artwork: artwork,
            isPlaying: playing,
            queue: queue,
            progress: progress
        )
    }

    func progress(
        elapsedTime: TimeInterval,
        duration: TimeInterval? = nil
    ) -> NowPlayingInfo {
        guard let duration = duration ?? progress?.duration else {
            return self
        }
        return .init(
            meta: meta,
            artwork: artwork,
            isPlaying: isPlaying,
            queue: queue,
            progress: .init(elapsedTime: elapsedTime, duration: duration)
        )
    }
}
