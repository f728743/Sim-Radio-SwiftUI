//
//  LegacySimRadioDTO.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.03.2025.
//

import Foundation

enum LegacySimRadioDTO {
    struct GameSeries: Codable, Sendable {
        let origin: String?
        let info: SeriesInfo
        let common: GameSeriesCommon
        let stations: [Station]
    }

    struct SeriesInfo: Codable {
        let title: String
        let logo: String
    }

    struct GameSeriesCommon: Codable, Sendable {
        let fileGroups: [FileGroup]
    }

    struct Station: Codable {
        let tag: String
        let info: StationInfo
        let fileGroups: [FileGroup]
        let playlist: Playlist
    }

    struct FileGroup: Codable, Sendable {
        let tag: String
        let files: [File]
    }

    struct File: Codable, Sendable {
        let tag: String?
        let path: String
        let duration: Double
        let audibleDuration: Double?
        let attaches: Attaches?
        let markers: [TrackMarker]?
    }

    struct TrackMarker: Codable {
        let title: String
        let artist: String
        let startTime: TimeInterval
    }

    struct Attaches: Codable {
        let files: [File]
    }

    struct StationInfo: Codable {
        let title: String
        let genre: String
        let logo: String
        let dj: String?
    }

    struct FirstFragment: Codable {
        let tag: String
    }

    struct FragmentRef: Codable {
        let fragmentTag: String
        let probability: Double?
    }

    struct Source: Codable {
        let type: SrcType
        let groupTag: String?
        let fileTag: String?
    }

    struct Position: Codable {
        let tag: String
        let relativeOffset: Double
    }

    struct PosVariant: Codable {
        let posTag: String
    }

    struct Condition: Codable {
        let type: ConditionType
        let fragmentTag: String?
        let probability: Double?
        let from: String?
        let to: String?
        let condition: [Condition]?
    }

    struct Mix: Codable {
        let tag: String
        let src: Source
        let condition: Condition
        let posVariant: [PosVariant]
    }

    struct Mixin: Codable {
        let pos: [Position]
        let mix: [Mix]
    }

    struct Fragment: Codable {
        let tag: String
        let src: Source
        let nextFragment: [FragmentRef]
        let mixins: Mixin?
    }

    struct Playlist: Codable {
        let firstFragment: FragmentRef
        let fragments: [Fragment]
    }

    enum SrcType: String, Codable {
        case group
        case attach
        case file
    }

    enum ConditionType: String, Codable {
        case nextFragment
        case random
        case groupAnd
        case groupOr
        case timeInterval
    }
}
