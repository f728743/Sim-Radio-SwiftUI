//
//  SimRadioMedia+Stub.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 23.04.2025.
//

import Foundation

extension SimRadioMedia {
    static var stub: SimRadioMedia {
        let seriesID = SimGameSeries.ID(origin: URL(string: "sample-gta5")!)
        let stations: [SimStation] = gta5stations.map {
            .init(
                id: .init(series: seriesID, value: $0.title),
                meta: .init(
                    title: $0.title,
                    logo: stationImageUrl(String($0.logo.split(separator: ".")[0])),
                    genre: $0.genre,
                    host: $0.dj
                ),
                trackLists: [],
                playlistRules: .init(
                    firstFragment: [],
                    fragments: [],
                    options: nil,
                    positions: nil
                )
            )
        }

        return .init(
            series: [
                seriesID: SimGameSeries(
                    id: seriesID,
                    meta: .init(
                        artwork: stationGroupImageUrl(),
                        title: "GTA V Radio",
                        subtitle: nil
                    ),
                    stationsIDs: stations.map(\.id)
                )
            ],
            trackLists: [:],
            stations: Dictionary(uniqueKeysWithValues: stations.map { ($0.id, $0) })
        )
    }
}

extension MediaList {
    static var mockGta5: Self {
        let seriesID = SimGameSeries.ID(origin: URL(string: "sample-gta5")!)
        return MediaList(
            id: .simRadioSeries(seriesID),
            meta: .init(
                artwork: stationGroupImageUrl(),
                title: "GTA V Radio",
                subtitle: nil
            ),
            items: gta5stations.map {
                Media(
                    id: .simRadio(.init(series: seriesID, value: $0.title)),
                    meta: .init(
                        artwork: stationImageUrl(String($0.logo.split(separator: ".")[0])),
                        title: $0.title,
                        listSubtitle: $0.genre,
                        detailsSubtitle: $0.detailsSubtitle,
                        isLiveStream: false
                    )
                )
            }
        )
    }
}

private let gta5BaseUrl = "https://raw.githubusercontent.com/tmp-acc/GTA-V-Radio-Stations/master"
private func stationImageUrl(_ station: String) -> URL? {
    URL(string: "\(gta5BaseUrl)/\(station)/\(station).png")
}

private func stationGroupImageUrl() -> URL? {
    URL(string: "\(gta5BaseUrl)/gta_v.png")
}

private struct GTARadioStation {
    let title: String
    let genre: String
    let logo: String
    let dj: String?
    var detailsSubtitle: String {
        dj.map { "Hosted by \($0) – \(genre)" } ?? genre
    }
}

private let gta5stations: [GTARadioStation] = [
    GTARadioStation(
        title: "Los Santos Rock Radio",
        genre: "Classic rock, soft rock, pop rock",
        logo: "radio_01_class_rock.png",
        dj: "Kenny Loggins"
    ),
    GTARadioStation(
        title: "Non-Stop Pop FM",
        genre: "Pop music, electronic dance music, electro house",
        logo: "radio_02_pop.png",
        dj: "Cara Delevingne"
    ),
    GTARadioStation(
        title: "Radio Los Santos",
        genre: "Modern contemporary hip hop, trap",
        logo: "radio_03_hiphop_new.png",
        dj: "Big Boy"
    ),
    GTARadioStation(
        title: "Channel X",
        genre: "Punk rock, hardcore punk and grunge",
        logo: "radio_04_punk.png",
        dj: "Keith Morris"
    ),
    GTARadioStation(
        title: "WCTR: West Coast Talk Radio",
        genre: "Public Talk Radio",
        logo: "radio_05_talk_01.png",
        dj: nil
    ),
    GTARadioStation(
        title: "Rebel Radio",
        genre: "Country music and rockabilly",
        logo: "radio_06_country.png",
        dj: "Jesco White"
    ),
    GTARadioStation(
        title: "Soulwax FM",
        genre: "Electronic music",
        logo: "radio_07_dance_01.png",
        dj: "Soulwax"
    ),
    GTARadioStation(
        title: "East Los FM",
        genre: "Mexican music and Latin music",
        logo: "radio_08_mexican.png",
        dj: "DJ Camilo and Don Cheto"
    ),
    GTARadioStation(
        title: "West Coast Classics",
        genre: "Golden age hip hop and gangsta rap",
        logo: "radio_09_hiphop_old.png",
        dj: "DJ Pooh"
    ),
    GTARadioStation(
        title: "Blaine County Talk Radio",
        genre: "Public Talk Radio",
        logo: "radio_11_talk_02.png",
        dj: nil
    ),
    GTARadioStation(
        title: "Blue Ark",
        genre: "Reggae, dancehall and dub",
        logo: "radio_12_reggae.png",
        dj: "Lee \"Scratch\" Perry"
    ),
    GTARadioStation(
        title: "WorldWide FM",
        genre: "Lounge, chillwave, jazz-funk and world",
        logo: "radio_13_jazz.png",
        dj: "Gilles Peterson"
    ),
    GTARadioStation(
        title: "FlyLo FM",
        genre: "IDM and Midwest hip hop",
        logo: "radio_14_dance_02.png",
        dj: "Flying Lotus"
    ),
    GTARadioStation(
        title: "The Lowdown 91.1",
        genre: "Classic soul, disco, gospel",
        logo: "radio_15_motown.png",
        dj: "Pam Grier"
    ),
    GTARadioStation(
        title: "Radio Mirror Park",
        genre: "Indie pop, synthpop, indietronica and chillwave",
        logo: "radio_16_silverlake.png",
        dj: "Twin Shadow"
    ),
    GTARadioStation(
        title: "Space 103.2",
        genre: "Funk and R&B",
        logo: "radio_17_funk.png",
        dj: "Bootsy Collins"
    ),
    GTARadioStation(
        title: "Vinewood Boulevard Radio",
        genre: "Garage rock, alternative rock and noise rock",
        logo: "radio_18_90s_rock.png",
        dj: "Nate Williams and Stephen Pope"
    )
]
