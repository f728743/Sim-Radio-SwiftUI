//
//  PlaylistItem.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 02.05.2025.
//

import AVFoundation

struct PlaylistItem: Sendable {
    let track: AudioFragment
    let mixes: [AudioFragment]
}

struct AudioFragmentMarkerValue: Equatable {
    let title: String?
    let artist: String?
}

struct AudioFragmentMarker: Equatable {
    let offset: CMTime
    let value: AudioFragmentMarkerValue
}

struct AudioFragment: Sendable {
    let url: URL
    let timeRange: CMTimeRange
    let startTime: CMTime
    let markers: [AudioFragmentMarker]?
}

extension AudioFragment {
    var playing: CMTimeRange {
        .init(start: startTime, duration: timeRange.duration)
    }
}

extension AudioFragment: CustomStringConvertible {
    private func formatTime(_ time: CMTime) -> String {
        time.seconds.formatted(
            .number
                .precision(.fractionLength(1 ... 2))
                .locale(Locale(identifier: "en_US_POSIX"))
        )
    }

    func description(nesting: Int) -> String {
        let playStart = formatTime(playing.start)
        let playEnd = formatTime(playing.end)
        let fileStart = formatTime(timeRange.start)
        let fileDuration = formatTime(timeRange.duration)
        let indent = String(repeating: "  ", count: nesting)
        return "\(indent)Play [\(playStart)...\(playEnd)] from File (\(fileStart) + \(fileDuration)), " +
            "\(url.pathComponents.suffix(2).joined(separator: "/"))\n"
    }

    var description: String {
        description(nesting: 0)
    }
}

extension PlaylistItem: CustomStringConvertible {
    var description: String {
        [
            track.description,
            mixes.description(nesting: 1)
        ].joined()
    }
}

extension AudioFragment {
    func trimmed(to endTime: CMTime) -> AudioFragment {
        let newPlayDuration = max(.zero, min(endTime, playing.end) - startTime)
        return .init(
            url: url,
            timeRange: .init(
                start: timeRange.start,
                duration: newPlayDuration
            ),
            startTime: startTime,
            markers: markers
        )
    }
}

extension PlaylistItem {
    func trimmed(to endTime: CMTime) -> PlaylistItem? {
        let trimmedTrack = track.trimmed(to: endTime)

        guard trimmedTrack.timeRange.duration > .zero else {
            return nil
        }

        let trimmedMixes = mixes.compactMap { mixFragment -> AudioFragment? in
            let trimmedMix = mixFragment.trimmed(to: endTime)
            return trimmedMix.timeRange.duration > .zero ? trimmedMix : nil
        }

        return PlaylistItem(track: trimmedTrack, mixes: trimmedMixes)
    }

    var duration: CMTime {
        track.timeRange.duration
    }
}

extension [PlaylistItem] {
    var description: String {
        map(\.description).joined()
    }

    var duration: CMTime {
        guard let first, let last else {
            return .zero
        }
        let start = first.track.startTime
        let end = last.track.startTime + last.track.timeRange.duration
        return end - start
    }

    func trimmed(to overallEndTime: CMTime) -> [PlaylistItem] {
        compactMap { playlistItem -> PlaylistItem? in
            playlistItem.trimmed(to: overallEndTime)
        }
    }
}

extension [AudioFragment] {
    func description(nesting: Int) -> String {
        map { $0.description(nesting: nesting) }.joined()
    }
}
