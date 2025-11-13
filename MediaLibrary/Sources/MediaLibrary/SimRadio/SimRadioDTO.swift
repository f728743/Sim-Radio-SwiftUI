//
//  SimRadioDTO.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 14.06.2025.
//

import Foundation

public enum SimRadioDTO {
    public struct GameSeries: Codable {
        public let meta: SeriesMeta
        public let origin: String?
        public let stations: [Station]
        public let trackLists: [TrackList]
    }

    public struct SeriesMeta: Codable {
        public let title: String
        public let subtitle: String?
        public let logo: String
        public let cover: SeriesCover
        public let isOnlineOnly: Bool?
    }

    public struct SeriesCover: Codable {
        public let image: String
        public let title: String
    }

    public struct TrackList: Codable {
        public let id: ID
        public let tracks: [Track]
    }

    public struct Track: Codable, Hashable {
        public let id: ID
        public let path: String?
        public let start: Double?
        public let duration: Double?
        public let intro: [Track.ID]?
        public let markers: TrackMarkers?
        public let trackList: TrackList.ID?
    }

    public struct TrackMarker: Codable, Hashable, Sendable {
        public let offset: Double
        public let id: Int
        public let title: String?
        public let artist: String?
    }

    public struct TrackMarkers: Codable, Hashable, Sendable {
        public let track: [TrackMarker]?
        public let dj: [TypeMarker]?
        public let rockout: [TypeMarker]?
        public let beat: [ValueMarker]?
    }

    public struct ValueMarker: Codable, Hashable, Sendable {
        public let offset: Double
        public let value: Int
    }

    public enum MarkerType: String, Codable, Hashable, Sendable {
        case start
        case end
        case introStart
        case introEnd
        case outroStart
        case outroEnd
    }

    public struct TypeMarker: Codable, Hashable, Sendable {
        public let offset: Double
        public let value: MarkerType
    }

    public struct Station: Codable {
        public let isHidden: Bool?
        public let id: ID
        public let meta: StationMeta
        public let trackLists: [TrackList.ID]
        public let playlist: Playlist
    }

    public struct StationMeta: Codable {
        public let title: String
        public let logo: String
        public let host: String?
        public let genre: String
        public let genreCode: String?
    }

    public enum StationFlag: String, Codable {
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

    public struct Playlist: Codable, Sendable {
        public let firstFragment: [PlaylistTransition]
        public let fragments: [Fragment]
        public let options: Options?
        public let positions: [VoiceOverPosition]?
    }

    public struct PlaylistTransition: Codable, Sendable {
        public let fragment: Fragment.ID
        public let option: SourceOption.ID?
        public let probability: Double?
    }

    public struct Fragment: Codable, Sendable {
        public let id: ID
        public let src: FragmentSource
        public let voiceOver: [VoiceOver]?
        public let next: [PlaylistTransition]
    }

    public struct Options: Codable, Sendable {
        public let available: [SourceOption]
        public let alternateInterval: Double?
    }

    public struct SourceOption: Codable, Sendable {
        public let id: ID
        public let title: String
    }

    public struct FragmentSource: Codable, Sendable {
        public let trackLists: [TrackList.ID]?
        public let introTrackLists: [TrackList.ID]?
        public let track: Track.ID?
        public let trackStart: Double?
    }

    public struct VoiceOverPosition: Codable, Sendable {
        public let id: ID
        public let relativeOffset: Double
    }

    public struct VoiceOver: Codable, Sendable {
        public let id: ID
        public let src: FragmentSource
        public let condition: Condition
        public let positions: [VoiceOverPosition.ID]
    }

    public struct Condition: Codable, Sendable {
        public let nextFragment: Fragment.ID?
        public let probability: Double?
        public let timeInterval: TimeInterval?
    }

    public struct TimeInterval: Codable, Sendable {
        public let from: String
        public let to: String
    }
}

extension SimStationMeta {
    init(origin: URL, data: SimRadioDTO.StationMeta, timestamp: Date?) {
        let logo = origin
            .deletingLastPathComponent()
            .appendingPathComponent(data.logo)

        self.init(
            title: data.title,
            logo: logo,
            genre: data.genre,
            host: data.host,
            timestamp: timestamp
        )
    }
}

public extension SimRadioDTO.TrackList {
    struct ID: CodableStringIDProtocol {
        public let value: String
        public init(value: String) {
            self.value = value
        }
    }
}

public extension SimRadioDTO.Track {
    struct ID: CodableStringIDProtocol {
        public let value: String
        public init(value: String) {
            self.value = value
        }
    }
}

public extension SimRadioDTO.Station {
    struct ID: CodableStringIDProtocol {
        public let value: String
        public init(value: String) {
            self.value = value
        }
    }
}

public extension SimRadioDTO.Fragment {
    struct ID: CodableStringIDProtocol {
        public let value: String
        public init(value: String) {
            self.value = value
        }
    }
}

public extension SimRadioDTO.VoiceOverPosition {
    struct ID: CodableStringIDProtocol {
        public let value: String
        public init(value: String) {
            self.value = value
        }
    }
}

public extension SimRadioDTO.VoiceOver {
    struct ID: CodableStringIDProtocol {
        public let value: String
        public init(value: String) {
            self.value = value
        }
    }
}

public extension SimRadioDTO.SourceOption {
    struct ID: CodableStringIDProtocol {
        public let value: String
        public init(value: String) {
            self.value = value
        }
    }
}
