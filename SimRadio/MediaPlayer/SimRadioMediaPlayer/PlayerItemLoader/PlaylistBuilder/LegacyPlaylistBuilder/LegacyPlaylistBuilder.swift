//
//  LegacyPlaylistBuilder.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 02.05.2025.
//

import AVFoundation

class LegacyPlaylistBuilder {
    let stationData: LegacySimRadioStationData
    var playlistСache: [Date: [PlaylistItem]] = [:]

    init(stationData: LegacySimRadioStationData) {
        self.stationData = stationData
    }

    // swiftlint:disable cyclomatic_complexity function_body_length

    /// Generates a playlist of the specified duration (`duration`),
    /// starting from the given date/time (`playlistStart`).
    /// Correctly handles trimming and time-shifting of items and their mixes.
    /// Assumes that the startTime of mixes from `makeDailyPlaylist` are absolute within the context of the day.
    /// - Parameters:
    ///   - playlistStart: Exact date and time for the playlist to start.
    ///   - duration: Total desired duration of the playlist in seconds.
    /// - Returns: An array of `PlaylistItem` forming the requested playlist.
    /// - Throws: Errors related to playlist generation.
    func makePlaylist(
        startingOn playlistStartDate: Date,
        at timeOffsetInFirstDay: CMTime,
        duration: CMTime,
        trimLastItem: Bool = false
    ) async throws -> [PlaylistItem] {
        guard duration > .zero else { return [] }
        var resultPlaylist: [PlaylistItem] = []
        var accumulatedDuration: CMTime = .zero
        var currentDate = playlistStartDate.startOfDay
        var dailyItems = try await makeDailyPlaylist(for: currentDate)

        // Find the index of the first relevant item
        guard let firstRelevantItem = dailyItems.firstIndex(
            where: { $0.track.playing.end > timeOffsetInFirstDay }
        ) else {
            throw PlaylistGenerationError.makeDailyPlaylistError(date: currentDate)
        }

        var index = firstRelevantItem

        while accumulatedDuration < duration {
            // Move to the next day if necessary
            if index >= dailyItems.count {
                guard let nextDay = currentDate.dayAfter else {
                    throw PlaylistGenerationError.makePlaylistError
                }
                currentDate = nextDay
                dailyItems = try await makeDailyPlaylist(for: currentDate)
                index = 0
                guard !dailyItems.isEmpty else {
                    throw PlaylistGenerationError.makeDailyPlaylistError(date: currentDate)
                }
                continue
            }

            let item = dailyItems[index]
            var itemFileTimeRange = item.track.timeRange
            var itemPlayableDuration = item.track.timeRange.duration
            let itemStartTimeInOutput = accumulatedDuration // Start time in the output playlist
            let parentOriginalStartTimeInDay = item.track.startTime

            // Adjustment for start offset (only for the first item)
            if accumulatedDuration == .zero {
                let offsetIntoItem = timeOffsetInFirstDay - parentOriginalStartTimeInDay
                if offsetIntoItem > .zero {
                    let newDuration = item.track.timeRange.duration - offsetIntoItem
                    if newDuration <= .zero {
                        index += 1
                        continue // Item is entirely before the playlist start
                    }
                    itemPlayableDuration = newDuration
                    itemFileTimeRange = CMTimeRange(
                        start: item.track.timeRange.start + offsetIntoItem,
                        duration: itemPlayableDuration
                    )
                }
            }

            let remainingNeededDuration = duration - accumulatedDuration
            let remainingInDayDuration = max(
                .zero,
                .fullDayDuration - parentOriginalStartTimeInDay - itemFileTimeRange.start
            )
            let actualDurationToAdd = trimLastItem
                ? min(min(itemPlayableDuration, remainingNeededDuration), remainingInDayDuration)
                : min(itemPlayableDuration, remainingInDayDuration)

            if actualDurationToAdd <= .zero {
                break // Desired duration reached or item has no playable duration
            }

            if actualDurationToAdd < itemPlayableDuration {
                itemFileTimeRange = CMTimeRange(
                    start: itemFileTimeRange.start,
                    duration: actualDurationToAdd
                )
            }

            let parentActualStartTimeInDay = parentOriginalStartTimeInDay +
                (itemFileTimeRange.start - item.track.timeRange.start)

            let parentActualEndTimeInDay = parentActualStartTimeInDay + itemFileTimeRange.duration

            let adjustedMixes: [AudioFragment] = item.mixes.compactMap { originalMix in
                originalMix.adjustedMix(
                    parentActualStartTimeInDay: parentActualStartTimeInDay,
                    parentActualEndTimeInDay: parentActualEndTimeInDay,
                    itemStartTimeInOutput: itemStartTimeInOutput
                )
            }

            let newItem = PlaylistItem(
                track: AudioFragment(
                    url: item.track.url,
                    timeRange: itemFileTimeRange,
                    startTime: itemStartTimeInOutput,
                    markers: nil
                ),
                mixes: adjustedMixes // List of processed and filtered mixes
            )
            resultPlaylist.append(newItem)
            accumulatedDuration += actualDurationToAdd
            index += 1
        }
        return resultPlaylist
    }

    // swiftlint:enable cyclomatic_complexity function_body_length

    /// Generates a single `PlaylistItem` starting at the specified date and time offset within that day.
    /// - Parameters:
    ///   - playlistStartDate: The date on which the playlist item should start.
    ///   - timeOffsetInFirstDay: The time offset within the start date's day, in seconds, where the item begins.
    /// - Returns: A `PlaylistItem` representing the audio fragment and its associated mixes,
    /// adjusted to start at the specified offset.
    /// - Throws: `PlaylistGenerationError.makeDailyPlaylistError` if no valid item is found
    /// for the given date and time or if the item's duration is invalid.
    func makePlaylistItem(
        startingOn playlistStartDate: Date,
        at timeOffsetInFirstDay: CMTime
    ) async throws -> PlaylistItem {
        let currentDate = playlistStartDate.startOfDay
        let dailyItems = try await makeDailyPlaylist(for: currentDate)

        // Find the first item that is relevant (i.e., its playing end time is after the timeOffsetInFirstDay)
        guard let relevantItem = dailyItems.first(where: { $0.track.playing.end > timeOffsetInFirstDay }) else {
            throw PlaylistGenerationError.makeDailyPlaylistError(date: currentDate)
        }

        var itemFileTimeRange = relevantItem.track.timeRange
        var itemPlayableDuration = relevantItem.track.timeRange.duration
        let parentOriginalStartTimeInDay = relevantItem.track.startTime
        let itemStartTimeInOutput: CMTime = .zero // Single item, start at 0 in output

        // Adjust for the time offset within the item
        if timeOffsetInFirstDay > parentOriginalStartTimeInDay {
            let offsetIntoItem = timeOffsetInFirstDay - parentOriginalStartTimeInDay
            let newDuration = max(.zero, relevantItem.track.timeRange.duration - offsetIntoItem)
            itemPlayableDuration = newDuration
            itemFileTimeRange = CMTimeRange(
                start: relevantItem.track.timeRange.start + offsetIntoItem,
                duration: itemPlayableDuration
            )
        }

        let remainingInDayDuration = max(
            .zero,
            .fullDayDuration - parentOriginalStartTimeInDay - itemFileTimeRange.start
        )
        let actualDurationToAdd = min(itemPlayableDuration, remainingInDayDuration)

        if actualDurationToAdd < itemPlayableDuration {
            itemFileTimeRange = CMTimeRange(
                start: itemFileTimeRange.start,
                duration: actualDurationToAdd
            )
        }

        let parentActualStartTimeInDay = parentOriginalStartTimeInDay +
            (itemFileTimeRange.start - relevantItem.track.timeRange.start)
        let parentActualEndTimeInDay = parentActualStartTimeInDay + itemFileTimeRange.duration

        // Adjust mixes to align with the trimmed track
        let adjustedMixes: [AudioFragment] = relevantItem.mixes.compactMap { originalMix in
            originalMix.adjustedMix(
                parentActualStartTimeInDay: parentActualStartTimeInDay,
                parentActualEndTimeInDay: parentActualEndTimeInDay,
                itemStartTimeInOutput: itemStartTimeInOutput
            )
        }

        return PlaylistItem(
            track: AudioFragment(
                url: relevantItem.track.url,
                timeRange: itemFileTimeRange,
                startTime: itemStartTimeInOutput,
                markers: nil
            ),
            mixes: adjustedMixes
        )
    }
}

private extension LegacyPlaylistBuilder {
    var station: LegacySimStation { stationData.station }
    var fileGroups: [LegacySimFileGroup] { stationData.fileGroups }

    func makeDailyPlaylist(
        for date: Date
    ) async throws -> [PlaylistItem] {
        if let cached = playlistСache[date] {
            return cached
        }
        var generator: any RandomNumberGenerator = SplitMix64(seed: UInt64(date.startOfDay.timeIntervalSince1970))
        let playlist = try await makePlaylist(
            duration: .init(seconds: .fullDayDuration),
            generator: &generator
        )
        return playlist
    }

    func makePlaylist(
        duration: CMTime,
        generator: inout RandomNumberGenerator
    ) async throws -> [PlaylistItem] {
        let rules = try LegacyPlaylistRules(
            stationID: stationData.station.id,
            model: station.playlistRules,
            fileGroups: Dictionary(uniqueKeysWithValues: fileGroups.map { ($0.id, $0) }),
            generator: &generator
        )

        var result: [PlaylistItem] = []
        var moment: CMTime = .zero
        var fragmentTag = station.playlistRules.firstFragment.fragmentTag

        var next = try await nextFragmentTag(
            after: fragmentTag,
            rules: rules,
            generator: &generator
        )

        while moment < duration {
            let playlistItem = try await makePlaylistItem(
                tag: fragmentTag,
                nextTag: next,
                starts: moment,
                rules: rules,
                generator: &generator
            )
            result.append(playlistItem)
            moment += playlistItem.track.playing.duration
            fragmentTag = next
            next = try await nextFragmentTag(
                after: fragmentTag,
                rules: rules,
                generator: &generator
            )
        }
        return result
    }

    func nextFragmentTag(
        after fragmentTag: String,
        rules: LegacyPlaylistRules,
        generator: inout RandomNumberGenerator
    ) async throws -> String {
        guard let fragment = rules.fragments[fragmentTag] else {
            throw PlaylistGenerationError.legacyFragmentNotFound(tag: fragmentTag)
        }
        let rnd = Double.random(in: 0 ... 1, using: &generator)
        var p = 0.0
        for next in fragment.nextFragment {
            p += next.probability ?? 1.0
            if rnd <= p {
                return next.fragmentTag
            }
        }
        throw PlaylistGenerationError.notExhaustiveLegacyFragment(tag: fragmentTag)
    }

    func makePlaylistItem(
        tag: String,
        nextTag: String,
        starts sec: CMTime,
        rules: LegacyPlaylistRules,
        generator: inout RandomNumberGenerator
    ) async throws -> PlaylistItem {
        guard let fragment = rules.fragments[tag] else {
            throw PlaylistGenerationError.legacyFragmentNotFound(tag: tag)
        }

        guard let file = fragment.src.next(parentFile: nil, generator: &generator) else {
            throw PlaylistGenerationError.wrongSource
        }
        let mixes = try await makeMixesForFragment(
            to: file,
            starts: sec,
            at: fragment.mixPositions,
            mixins: fragment.mixins,
            nextTag: nextTag,
            generator: &generator
        )
        return PlaylistItem(
            track: AudioFragment(
                url: file.url(local: stationData.isDownloaded),
                timeRange: .init(
                    start: .zero,
                    duration: .init(seconds: file.file.duration)
                ),
                startTime: sec,
                markers: nil,
            ),
            mixes: mixes
        )
    }

    // swiftlint:disable:next function_parameter_count
    func makeMixesForFragment(
        to file: FileFromGroup,
        starts sec: CMTime,
        at positions: [String: Double],
        mixins: [LegacyPlaylistRules.Mix],
        nextTag: String,
        generator: inout RandomNumberGenerator
    ) async throws -> [AudioFragment] {
        var usedPositions: Set<String> = []
        var res: [AudioFragment] = []
        for mix in mixins where mix.condition.isSatisfied(
            forNextFragment: nextTag,
            startingFrom: sec,
            generator: &generator
        ) == true {
            for posTag in mix.positions {
                if usedPositions.contains(posTag) {
                    continue
                }
                guard let pos = positions[posTag] else {
                    throw PlaylistGenerationError.wrongPositionTag(tag: posTag)
                }
                if let mixFile = mix.src.next(parentFile: file, generator: &generator) {
                    let t = file.file.duration - mixFile.file.duration
                    let mixStartsSec = sec + .init(seconds: t * pos)
                    res.append(AudioFragment(
                        url: mixFile.url(local: stationData.isDownloaded),
                        timeRange: .init(start: .zero, duration: .init(seconds: mixFile.file.duration)),
                        startTime: mixStartsSec,
                        markers: nil
                    ))
                    usedPositions.insert(posTag)
                    break
                }
            }
        }
        return res.sorted { $0.playing.start < $1.playing.start }
    }
}
