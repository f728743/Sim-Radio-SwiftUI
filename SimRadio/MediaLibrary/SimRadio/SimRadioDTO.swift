//
//  SimRadioDTO.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 14.06.2025.
//

import Foundation

enum SimRadioDTO {
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
        let start: Double?
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
        let isHidden: Bool?
        let id: ID
        let meta: StationMeta
        let trackLists: [TrackList.ID]
        let playlist: Playlist
    }

    struct StationMeta: Codable {
        let title: String
        let artwork: String
        let host: String?
        let genre: String
        let genreCode: String
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

    struct Playlist: Codable {
        let firstFragment: [PlaylistTransition]
        let fragments: [Fragment]
        let options: Options?
        let positions: [VoiceOverPosition]?
    }

    struct PlaylistTransition: Codable {
        let fragment: Fragment.ID
        let option: SourceOption.ID?
        let probability: Double?
    }

    struct Fragment: Codable {
        let id: ID
        let src: FragmentSource
        let voiceOver: [VoiceOver]?
        let next: [PlaylistTransition]
    }

    struct Options: Codable {
        let available: [SourceOption]
        let alternateInterval: Double?
    }

    struct SourceOption: Codable {
        let id: ID
        let title: String
    }

    struct FragmentSource: Codable {
        let trackLists: [TrackList.ID]?
        let introTrackLists: [TrackList.ID]?
        let track: Track.ID?
        let trackStart: Double?
    }

    struct VoiceOverPosition: Codable {
        let id: ID
        let relativeOffset: Double
    }

    struct VoiceOver: Codable {
        let id: ID
        let src: FragmentSource
        let condition: Condition
        let positions: [VoiceOverPosition.ID]
    }

    struct Condition: Codable {
        let nextFragment: Fragment.ID?
        let probability: Double?
        let timeInterval: TimeInterval?
    }

    struct TimeInterval: Codable {
        let from: String
        let to: String
    }
}

extension SimRadioDTO.StationMeta {
    enum Const {
        static let mediaExtension = ".png"
    }
}

extension SimStationMeta {
    init(origin: URL, data: SimRadioDTO.StationMeta) {
        let artwork = origin
            .deletingLastPathComponent()
            .appendingPathComponent(data.artwork + SimRadioDTO.StationMeta.Const.mediaExtension)

        self.init(
            title: data.title,
            artwork: artwork,
            genre: data.genre,
            host: data.host
        )
    }
}

extension SimRadioDTO.TrackList {
    struct ID: CodableStringIDProtocol { let value: String }
}

extension SimRadioDTO.Track {
    struct ID: CodableStringIDProtocol { let value: String }
}

extension SimRadioDTO.Station {
    struct ID: CodableStringIDProtocol { let value: String }
}

extension SimRadioDTO.Fragment {
    struct ID: CodableStringIDProtocol { let value: String }
}

extension SimRadioDTO.VoiceOverPosition {
    struct ID: CodableStringIDProtocol { let value: String }
}

extension SimRadioDTO.VoiceOver {
    struct ID: CodableStringIDProtocol { let value: String }
}

extension SimRadioDTO.SourceOption {
    struct ID: CodableStringIDProtocol { let value: String }
}
