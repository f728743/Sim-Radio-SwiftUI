//
//  APISearchResponseDTO+Mock.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 23.10.2025.
//

import Foundation

extension APISimRadioSeriesDTO {
    #if DEBUG
    static var mock: APISimRadioSeriesDTO {
        APISimRadioSeriesDTO(
            id: "gta_5_radio",
            url: "https://media.githubusercontent.com/media/maxerohingta/convert_gta5_audio/" +
                "refs/heads/main/converted_m4a/sim_radio.json",
            title: "GTA V Radio",
            logo: "textures/gta_5_radio.png",
            coverTitle: "GTAV Radio",
            coverLogo: "textures/cover.jpg",
            stations: [
                SimRadio.APISimStationDTO(
                    id: "radio_11_talk_02",
                    logo: "textures/radio_11_talk_02.png",
                    tags: "talk",
                    title: "Blaine County Talk Radio"
                ),
                SimRadio.APISimStationDTO(
                    id: "radio_21_dlc_xm17",
                    logo: "textures/radio_21_dlc_xm17.png",
                    tags: "hiphop",
                    title: "Blonded Los Santos 97.8 FM"
                ),
                SimRadio.APISimStationDTO(
                    id: "radio_12_reggae",
                    logo: "textures/radio_12_reggae.png",
                    tags: "reggae, dancehall, dub",
                    title: "Blue Ark"
                ),
                SimRadio.APISimStationDTO(
                    id: "radio_04_punk",
                    logo: "textures/radio_04_punk.png",
                    tags: "punk rock, hardcore punk, grunge",
                    title: "Channel X"
                ),
                SimRadio.APISimStationDTO(
                    id: "radio_08_mexican",
                    logo: "textures/radio_08_mexican.png",
                    tags: "mexican, latin",
                    title: "East Los FM"
                ),
                SimRadio.APISimStationDTO(
                    id: "radio_14_dance_02",
                    logo: "textures/radio_14_dance_02.png",
                    tags: "idm,midwest hiphop",
                    title: "FlyLo FM"
                ),
                SimRadio.APISimStationDTO(
                    id: "radio_23_dlc_xm19_radio",
                    logo: "textures/radio_23_dlc_xm19_radio.png",
                    tags: "modern hiphop, uk rap, afrofusion",
                    title: "iFruit Radio"
                ),
                SimRadio.APISimStationDTO(
                    id: "radio_34_dlc_hei4_kult",
                    logo: "textures/radio_34_dlc_hei4_kult.png",
                    tags: "alternative rock",
                    title: "Kult FM"
                ),
                SimRadio.APISimStationDTO(
                    id: "radio_01_class_rock",
                    logo: "textures/radio_01_class_rock.png",
                    tags: "classic rock, soft rock, pop rock",
                    title: "Los Santos Rock Radio"
                ),
                SimRadio.APISimStationDTO(
                    id: "radio_22_dlc_battle_mix1_radio",
                    logo: "textures/radio_22_dlc_battle_mix1_radio.png",
                    tags: "house, techno",
                    title: "Los Santos Underground Radio"
                ),
                SimRadio.APISimStationDTO(
                    id: "radio_37_motomami",
                    logo: "textures/radio_37_motomami.png",
                    tags: "latin",
                    title: "MOTOMAMI Los Santos"
                ),
                SimRadio.APISimStationDTO(
                    id: "radio_02_pop",
                    logo: "textures/radio_02_pop.png",
                    tags: "pop, electronic dance, electro house",
                    title: "Non-Stop Pop FM"
                ),
                SimRadio.APISimStationDTO(
                    id: "radio_03_hiphop_new",
                    logo: "textures/radio_03_hiphop_new.png",
                    tags: "modern hiphop, trap",
                    title: "Radio Los Santos"
                ),
                SimRadio.APISimStationDTO(
                    id: "radio_16_silverlake",
                    logo: "textures/radio_16_silverlake.png",
                    tags: "indie pop, synthpop, indietronica, chillwave",
                    title: "Radio Mirror Park"
                ),
                SimRadio.APISimStationDTO(
                    id: "radio_06_country",
                    logo: "textures/radio_06_country.png",
                    tags: "country, rockabilly",
                    title: "Rebel Radio"
                ),
                SimRadio.APISimStationDTO(
                    id: "radio_07_dance_01",
                    logo: "textures/radio_07_dance_01.png",
                    tags: "electronic",
                    title: "Soulwax FM"
                ),
                SimRadio.APISimStationDTO(
                    id: "radio_17_funk",
                    logo: "textures/radio_17_funk.png",
                    tags: "funk, r&b",
                    title: "Space 103.2"
                ),
                SimRadio.APISimStationDTO(
                    id: "radio_27_dlc_prhei4",
                    logo: "textures/radio_27_dlc_prhei4.png",
                    tags: "electronic, house, techno",
                    title: "Still Slipping Los Santos"
                ),
                SimRadio.APISimStationDTO(
                    id: "radio_20_thelab",
                    logo: "textures/radio_20_thelab.png",
                    tags: "hiphop",
                    title: "The Lab"
                ),
                SimRadio.APISimStationDTO(
                    id: "radio_15_motown",
                    logo: "textures/radio_15_motown.png",
                    tags: "classic soul, disco, gospel",
                    title: "The Lowdown 91.1"
                ),
                SimRadio.APISimStationDTO(
                    id: "radio_35_dlc_hei4_mlr",
                    logo: "textures/radio_35_dlc_hei4_mlr.png",
                    tags: "house, disco, techno",
                    title: "The Music Locker"
                ),
                SimRadio.APISimStationDTO(
                    id: "radio_18_90s_rock",
                    logo: "textures/radio_18_90s_rock.png",
                    tags: "garage rock, alternative rock, noise rock",
                    title: "Vinewood Boulevard Radio"
                ),
                SimRadio.APISimStationDTO(
                    id: "radio_05_talk_01",
                    logo: "textures/radio_05_talk_01.png",
                    tags: "talk",
                    title: "WCTR: West Coast Talk Radio"
                ),
                SimRadio.APISimStationDTO(
                    id: "radio_09_hiphop_old",
                    logo: "textures/radio_09_hiphop_old.png",
                    tags: "golden age hiphop, gangsta rap",
                    title: "West Coast Classics"
                ),
                SimRadio.APISimStationDTO(
                    id: "radio_13_jazz",
                    logo: "textures/radio_13_jazz.png",
                    tags: "lounge, chillwave, jazz-funk",
                    title: "WorldWide FM"
                )
            ],
            foundStations: [
                "radio_21_dlc_xm17",
                "radio_08_mexican",
                "radio_14_dance_02",
                "radio_34_dlc_hei4_kult",
                "radio_02_pop",
                "radio_07_dance_01",
                "radio_13_jazz"
            ]
        )
    }
    #endif
}
