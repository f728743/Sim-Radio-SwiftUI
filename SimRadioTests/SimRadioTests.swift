//
//  SimRadioTests.swift
//  SimRadioTests
//
//  Created by Alexey Vorobyov on 30.01.2025.
//

import CoreMedia
import Foundation
@testable import SimRadio
import Testing

// swiftlint:disable all

struct SimRadioTests {
    @Test func makePlaylistForEndOfDay() async throws {
        let playlistBuilder = PlaylistBuilder(stationData: stationData)
        let date = Date("03.05.2025 23:55:29")
        let time: CMTime = .init(seconds: date.currentSecondOfDay)
        let playlist = try await playlistBuilder.makePlaylist(
            startingOn: date,
            at: time,
            duration: .init(seconds: 10 * 60),
            trimLastItem: true
        )

        let playlistDescription = #"""
        Play [0.0...214.24] from File (52.28 + 214.24), radio_01_class_rock/black_velvet.m4a
        Play [214.24...231.52] from File (0.0 + 17.28), mono_solo/mono_solo_01.m4a
        Play [231.52...271.0] from File (0.0 + 39.48), news/mono_news_09.m4a
        Play [271.0...276.2] from File (0.0 + 5.2), id/id_03.m4a
        Play [276.2...525.74] from File (0.0 + 249.54), radio_01_class_rock/all_the_things_she_said.m4a
          Play [283.53...288.64] from File (0.0 + 5.11), intro/all_the_things_she_said_02.m4a
          Play [514.61...518.36] from File (0.0 + 3.75), general/general_01.m4a
        Play [525.74...600.0] from File (0.0 + 74.26), radio_01_class_rock/big_log.m4a
          Play [531.97...534.55] from File (0.0 + 2.58), intro/big_log_01.m4a

        """#
        #expect(playlist.description == playlistDescription)
    }

    @Test func makePlaylistForStartOfDay() async throws {
        let playlistBuilder = PlaylistBuilder(stationData: stationData)
        let date = Date("03.05.2025 00:1:40")
        let time: CMTime = .init(seconds: date.currentSecondOfDay)

        let playlist = try await playlistBuilder.makePlaylist(
            startingOn: date,
            at: time,
            duration: .init(seconds: 10 * 60),
            trimLastItem: true
        )

        let playlistDescription = #"""
        Play [0.0...116.87] from File (93.33 + 116.87), radio_01_class_rock/big_log.m4a
          Play [107.52...110.66] from File (0.0 + 3.13), to_ad/to_ad_01.m4a
        Play [116.87...149.12] from File (0.0 + 32.25), adverts/mono_ad009_prop_43.m4a
        Play [149.12...415.65] from File (0.0 + 266.53), radio_01_class_rock/black_velvet.m4a
          Play [156.96...162.3] from File (0.0 + 5.35), intro/black_velvet_01.m4a
        Play [415.65...432.92] from File (0.0 + 17.28), mono_solo/mono_solo_01.m4a
        Play [432.92...582.76] from File (0.0 + 149.84), news/mono_news_02.m4a
        Play [582.76...589.24] from File (0.0 + 6.48), id/id_04.m4a
        Play [589.24...600.0] from File (0.0 + 10.76), radio_01_class_rock/burning_heart.m4a
          Play [595.59...600.0] from File (0.0 + 4.41), intro/burning_heart_02.m4a

        """#

        #expect(playlist.description == playlistDescription)
    }

    var stationData: SimRadioStationData {
        let series = try! JSONDecoder().decode(LegacySimRadioDTO.GameSeries.self, from: radioJson.data(using: .utf8)!)
        let media = LegacySimRadioMedia(origin: URL(string: "/")!, dto: series)
        let stationData = media.stationData(for: .init(value: "683434/radio_01_class_rock"))

        return .init(
            station: stationData!.station,
            fileGroups: stationData!.fileGroups,
            isDownloaded: false
        )
    }
}

private extension Date {
    init(_ string: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        let someDateTime = formatter.date(from: string)
        self = someDateTime!
    }
}

let radioJson = #"""
{
  "info": {
    "title": "GTA V Radio",
    "logo": "gta_v.png"
  },
  "common": {
    "fileGroups": [
      {
        "tag": "adverts",
        "files": [
          { "path": "common/adverts/ad082_alcoholia.m4a", "duration": 48.32 },
          { "path": "common/adverts/mono_ad001_life_invader.m4a", "duration": 31.05, "audibleDuration": 30.462 },
          { "path": "common/adverts/mono_ad002_righteous_slaughter_nuke.m4a", "duration": 27.93, "audibleDuration": 27.177 },
          { "path": "common/adverts/mono_ad003_righteous_slaughter_russian.m4a", "duration": 55.09, "audibleDuration": 54.48 },
          { "path": "common/adverts/mono_ad004_righteous_slaughter_levels.m4a", "duration": 48.34, "audibleDuration": 47.63 },
          { "path": "common/adverts/mono_ad005_sa_tourism_board.m4a", "duration": 51.73 },
          { "path": "common/adverts/mono_ad006_desert_tourism.m4a", "duration": 37.03, "audibleDuration": 36.286 },
          { "path": "common/adverts/mono_ad007_sa_water_power.m4a", "duration": 35.04 },
          { "path": "common/adverts/mono_ad008_up_n_atom.m4a", "duration": 22.84 },
          { "path": "common/adverts/mono_ad009_prop_43.m4a", "duration": 32.25}
        ]
      },
      {
        "tag": "news",
        "files": [
          { "path": "common/news/mono_news_01.m4a", "duration": 150.21, "audibleDuration": 148.41 },
          { "path": "common/news/mono_news_02.m4a", "duration": 151.38, "audibleDuration": 149.84 },
          { "path": "common/news/mono_news_03.m4a", "duration": 104.79, "audibleDuration": 103.27 },
          { "path": "common/news/mono_news_04.m4a", "duration": 148.35, "audibleDuration": 146.49 },
          { "path": "common/news/mono_news_05.m4a", "duration": 121.83, "audibleDuration": 120.19 },
          { "path": "common/news/mono_news_06.m4a", "duration": 141.74, "audibleDuration": 140.11 },
          { "path": "common/news/mono_news_07.m4a", "duration": 100.26, "audibleDuration": 98.814 },
          { "path": "common/news/mono_news_08.m4a", "duration": 131.75, "audibleDuration": 130.13 },
          { "path": "common/news/mono_news_09.m4a", "duration": 125.59, "audibleDuration": 124.05 },
          { "path": "common/news/mono_news_10.m4a", "duration": 104.22, "audibleDuration": 102.35 }
        ]
      }
    ]
  },
  "stations": [
    {
      "tag": "radio_01_class_rock",
      "info": {
        "title": "Los Santos Rock Radio",
        "genre": "Classic rock, soft rock, pop rock",
        "logo": "radio_01_class_rock.png",
        "dj": "Kenny Loggins"
      },
      "fileGroups": [
        {
          "tag": "track",
          "files": [
            {
              "path": "all_the_things_she_said.m4a",
              "duration": 249.54,
              "attaches": {
                "files": [
                  { "path": "intro/all_the_things_she_said_01.m4a", "duration": 3.94, "audibleDuration": 3.5613 },
                  { "path": "intro/all_the_things_she_said_02.m4a", "duration": 5.11 }
                ]
              }
            },
            {
              "path": "baker_street.m4a",
              "duration": 329.17,
              "attaches": {
                "files": [ { "path": "intro/baker_street_01.m4a", "duration": 3.63 }, { "path": "intro/baker_street_02.m4a", "duration": 6.85 } ]
              }
            },
            {
              "path": "big_log.m4a",
              "duration": 211.03,
              "audibleDuration": 210.2,
              "attaches": {
                "files": [ { "path": "intro/big_log_01.m4a", "duration": 2.58 }, { "path": "intro/big_log_02.m4a", "duration": 6.02 } ]
              }
            },
            {
              "path": "black_velvet.m4a",
              "duration": 266.88,
              "audibleDuration": 266.53,
              "attaches": {
                "files": [ { "path": "intro/black_velvet_01.m4a", "duration": 5.35 }, { "path": "intro/black_velvet_02.m4a", "duration": 4.82} ]
              }
            },
            {
              "path": "burning_heart.m4a",
              "duration": 218.35,
              "audibleDuration": 217.66,
              "attaches": {
                "files": [ { "path": "intro/burning_heart_01.m4a", "duration": 6.49 }, { "path": "intro/burning_heart_02.m4a", "duration": 6.19 } ]
              }
            }
          ]
        },
        {
          "tag": "general",
          "files": [
            { "path": "general/general_01.m4a", "duration": 4.08, "audibleDuration": 3.7533 },
            { "path": "general/general_02.m4a", "duration": 5.95 },
            { "path": "general/general_03.m4a", "duration": 3.37 },
            { "path": "general/general_04.m4a", "duration": 1.4 },
            { "path": "general/general_05.m4a", "duration": 3.33 }
          ]
        },
        {
          "tag": "id",
          "files": [
            { "path": "id/id_01.m4a", "duration": 7.27, "audibleDuration": 6.67 },
            { "path": "id/id_02.m4a", "duration": 5.57, "audibleDuration": 5.1826 },
            { "path": "id/id_03.m4a", "duration": 6.27, "audibleDuration": 5.2 },
            { "path": "id/id_04.m4a", "duration": 7.61, "audibleDuration": 6.48 },
            { "path": "id/id_05.m4a", "duration": 8.49, "audibleDuration": 7.3586 },
          ]
        },
        {
          "tag": "mono_solo",
          "files": [
            { "path": "mono_solo/heists_obh_briefcase_close_mt_thud.m4a", "duration": 24.25, "audibleDuration": 22.93 },
            { "path": "mono_solo/mono_solo_01.m4a", "duration": 18.57, "audibleDuration": 17.278 },
            { "path": "mono_solo/mono_solo_02.m4a", "duration": 24.37, "audibleDuration": 23.209 },
            { "path": "mono_solo/mono_solo_03.m4a", "duration": 26.0, "audibleDuration": 24.617 },
            { "path": "mono_solo/mono_solo_04.m4a", "duration": 25.62, "audibleDuration": 24.14 }
          ]
        },
        {
          "tag": "time_evening",
          "files": [
            { "path": "time_evening/evening_01.m4a", "duration": 3.97, "audibleDuration": 3.66 },
            { "path": "time_evening/evening_02.m4a", "duration": 2.31, "audibleDuration": 1.7906 },
            { "path": "time_evening/evening_03.m4a", "duration": 3.19 }
          ]
        },
        {
          "tag": "time_morning",
          "files": [
            { "path": "time_morning/morning_01.m4a", "duration": 5.17 },
            { "path": "time_morning/morning_02.m4a", "duration": 4.48 },
            { "path": "time_morning/morning_03.m4a", "duration": 3.79 },
          ]
        },
        {
          "tag": "to_adverts",
          "files": [
            { "path": "to_ad/to_ad_01.m4a", "duration": 3.49, "audibleDuration": 3.1346 },
            { "path": "to_ad/to_ad_02.m4a", "duration": 2.1 },
            { "path": "to_ad/to_ad_03.m4a", "duration": 2.57 },
          ]
        },
        {
          "tag": "to_news",
          "files": [ 
            { "path": "to_news/to_news_01.m4a", "duration": 4.06},
            { "path": "to_news/to_news_02.m4a", "duration": 3.54 },
            { "path": "to_news/to_news_03.m4a", "duration": 2.55 },
          ]
        }
      ],
      "playlist": {
        "firstFragment": { "fragmentTag": "id" },
        "fragments": [
          {
            "tag": "id",
            "src": { "type": "group", "groupTag": "id" },
            "nextFragment": [
              { "fragmentTag": "track" }
            ]
          },
          {
            "tag": "track",
            "src": { "type": "group", "groupTag": "track" },
            "nextFragment": [
              { "fragmentTag": "adverts", "probability": 0.357 },
              { "fragmentTag": "monoSolo", "probability": 0.286 },
              { "fragmentTag": "news", "probability": 0.143 },
              { "fragmentTag": "track" }
            ],
            "mixins": {
              "pos": [
                { "tag": "begin", "relativeOffset": 0.03 },
                { "tag": "end", "relativeOffset": 0.97 }
              ],
              "mix": [
                {
                  "tag": "toNews",
                  "src": { "type": "group", "groupTag": "to_news" },
                  "condition": { "type": "nextFragment", "fragmentTag": "news" },
                  "posVariant": [ { "posTag": "end" } ]
                },
                {
                  "tag": "toAdverts",
                  "src": { "type": "group", "groupTag": "to_adverts" },
                  "condition": { "type": "nextFragment", "fragmentTag": "adverts" },
                  "posVariant": [ { "posTag": "end" } ]
                },
                {
                  "tag": "general",
                  "src": { "type": "group", "groupTag": "general" },
                  "condition": { "type": "random", "probability": 0.333 },
                  "posVariant": [ { "posTag": "end" }, { "posTag": "begin" } ]
                },
                {
                  "tag": "intro",
                  "src": { "type": "attach" },
                  "condition": { "type": "random", "probability": 0.333 },
                  "posVariant": [ { "posTag": "begin" }, { "posTag": "end" } ]
                },
                {
                  "tag": "morning",
                  "src": { "type": "group","groupTag": "time_morning" },
                  "condition": {
                    "type": "groupAnd",
                    "condition": [ 
                        { "type": "random", "probability": 0.333 },
                        { "type": "timeInterval", "from": "5:00", "to": "11:00"}
                    ]
                  },
                  "posVariant": [ { "posTag": "end" }, { "posTag": "begin" } ]
                },
                {
                  "tag": "evening",
                  "src": { "type": "group", "groupTag": "time_evening" },
                  "condition": {
                    "type": "groupAnd",
                    "condition": [
                      { "type": "random", "probability": 0.333 },
                      { "type": "timeInterval", "from": "18:00", "to": "24:00" }
                    ]
                  },
                  "posVariant": [ { "posTag": "end" }, { "posTag": "begin" } ]
                }
              ]
            }
          },
          {
            "tag": "monoSolo",
            "src": { "type": "group", "groupTag": "mono_solo"},
            "nextFragment": [
              { "fragmentTag": "news", "probability": 0.4 },
              { "fragmentTag": "track" }
            ]
          },
          {
            "tag": "news",
            "src": { "type": "group","groupTag": "news" },
            "nextFragment": [
              { "fragmentTag": "id", "probability": 0.667 },
              { "fragmentTag": "track" }
            ]
          },
          {
            "tag": "adverts",
            "src": { "type": "group", "groupTag": "adverts" },
            "nextFragment": [ 
                { "fragmentTag": "track" }
            ]
          }
        ]
      }
    }
  ] 
}
"""#
// swiftlint:enable all
