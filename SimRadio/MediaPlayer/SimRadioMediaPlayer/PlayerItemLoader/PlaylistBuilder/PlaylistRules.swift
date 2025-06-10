//
//  PlaylistRules.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 04.05.2025.
//

import Foundation

class PlaylistRules {
    let fileGroups: [SimFileGroup.ID: SimFileGroup]
    let firstFragmentTag: String
    let fragments: [String: Fragment]

    init(
        stationID: SimStation.ID,
        model: SimRadioDTO.Playlist,
        fileGroups: [SimFileGroup.ID: SimFileGroup],
        rnd: RandomNumberGenerator
    ) throws {
        firstFragmentTag = model.firstFragment.fragmentTag
        fragments = try Dictionary(uniqueKeysWithValues: model.fragments.map {
            try ($0.tag, Fragment(stationID: stationID, model: $0, fileGroups: fileGroups, rnd: rnd))
        })
        self.fileGroups = fileGroups
    }

    struct Mix {
        var src: FileSource
        let condition: SimRadioDTO.Condition
        var positions: [String]

        init(
            stationID: SimStation.ID,
            model: SimRadioDTO.Mix,
            fileGroups: [SimFileGroup.ID: SimFileGroup],
            rnd: RandomNumberGenerator
        ) throws {
            guard let src = makeFileSource(
                stationID: stationID,
                model: model.src,
                fileGroups: fileGroups,
                rnd: rnd
            ) else {
                throw PlaylistGenerationError.wrongSource
            }
            self.src = src
            condition = model.condition
            positions = model.posVariant.map(\.posTag)
        }
    }

    struct Fragment {
        let src: FileSource
        let nextFragment: [SimRadioDTO.FragmentRef]
        let mixPositions: [String: Double]
        let mixins: [Mix]

        init(
            stationID: SimStation.ID,
            model: SimRadioDTO.Fragment,
            fileGroups: [SimFileGroup.ID: SimFileGroup],
            rnd: RandomNumberGenerator
        ) throws {
            guard let src = makeFileSource(
                stationID: stationID,
                model: model.src,
                fileGroups: fileGroups,
                rnd: rnd
            ) else {
                throw PlaylistGenerationError.wrongSource
            }
            self.src = src
            nextFragment = model.nextFragment
            mixPositions = model.mixins == nil
                ? [:]
                : Dictionary(uniqueKeysWithValues: model.mixins!.pos.map { ($0.tag, $0.relativeOffset) })

            mixins = model.mixins == nil
                ? []
                : try model.mixins!.mix.map {
                    try Mix(
                        stationID: stationID,
                        model: $0,
                        fileGroups: fileGroups,
                        rnd: rnd
                    )
                }
        }
    }
}
