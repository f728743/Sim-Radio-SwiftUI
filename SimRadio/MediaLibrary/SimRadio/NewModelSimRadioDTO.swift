//
//  NewModelSimRadioDTO.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 14.06.2025.
//

enum NewModelSimRadioDTO {
    struct GameSeries: Codable {
        let origin: String?
        let trackLists: [TrackList]
        let stations: [Station]
    }

    struct TrackList: Codable {
        let id: ID
        let tracks: [Track]
    }

    struct Track: Codable, Hashable {
        let id: ID
        let path: String?
        let duration: Double?
        let intro: [Track.ID]?
        let markers: TrackMarkers?
        let trackList: TrackList.ID?
    }

    struct TrackMarker: Codable, Hashable {
        let offset: Double
        let id: Int
        let title: String?
        let artist: String?
    }

    struct TrackMarkers: Codable, Hashable {
        let track: [TrackMarker]?
        let dj: [TypeMarker]?
        let rockout: [TypeMarker]?
        let beat: [ValueMarker]?
    }

    struct ValueMarker: Codable, Hashable {
        let offset: Double
        let value: Int
    }

    enum MarkerType: String, Codable, Hashable {
        case start
        case end
        case introStart
        case introEnd
        case outroStart
        case outroEnd
    }

    struct TypeMarker: Codable, Hashable {
        let offset: Double
        let value: MarkerType
    }

    struct Station: Codable {
        let id: ID
        let genre: String
        let trackLists: [TrackList.ID]
    }

    enum StationFlag: String, Codable {
        case noBack2BackMusic
        case playNews
        case playsUsersMusic
        case isMixStation
        case back2BackAds
        case sequentialMusic
        case identsInsteadOfAds
        case locked
        case useRandomizedStrideSelection
        case playWeather
    }

    // ===============================================================================================

//    struct GameSeries: Codable, Sendable {
//        let origin: String?
//        let info: SeriesInfo
//        let stations: [Station]
//        let common: GameSeriesShared
//    }

//    struct SeriesInfo: Codable {
//        let title: String
//        let logo: String
//    }

//    struct GameSeriesShared: Codable, Sendable {
//        let fileGroups: [FileGroup]
//    }

//    struct Station: Codable {
//        let tag: String
//        let info: StationInfo
//        let fileGroups: [FileGroup]
//        let playlist: Playlist
//    }

//    struct FileGroup: Codable, Sendable {
//        let tag: String
//      let files: [File]
//    }

    //  struct File: Codable, Sendable {
//      let tag: String?
//      let path: String
//      let duration: Double
//      let audibleDuration: Double?
//      let attachments: Attachments?
//      let markers: TrackMarkers?
    //  }

    //  struct TrackMarkers: Codable {
//      let track: [TrackMarker]?
//      let dj: [TypeMarker]?
//      let rockout: [TypeMarker]?
//      let beat: [ValueMarker]?
    //  }

    //  struct TrackMarker: Codable {
//      let offset: Int
//      let id: Int
//      let title: String?
//      let artist: String?
    //  }

    //  struct Attachments: Codable {
//      let files: [File]
    //  }

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

extension NewModelSimRadioDTO.TrackList {
    struct ID: Codable, Hashable { let value: String }
}

extension NewModelSimRadioDTO.TrackList.ID {
    init(_ value: String) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

extension NewModelSimRadioDTO.Track {
    struct ID: Codable, Hashable { let value: String }
}

extension NewModelSimRadioDTO.Track.ID {
    init(_ value: String) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

extension NewModelSimRadioDTO.Station {
    struct ID: Codable, Hashable { let value: String }
}

extension NewModelSimRadioDTO.Station.ID {
    init(_ value: String) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
