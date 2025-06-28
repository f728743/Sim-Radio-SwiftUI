//
//  PlaylistRules.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 04.05.2025.
//

import Foundation

class PlaylistRules {
    let fileGroups: [LegacySimFileGroup.ID: LegacySimFileGroup]
    let firstFragmentTag: String
    let fragments: [String: Fragment]

    init(
        stationID: LegacySimStation.ID,
        model: LegacySimRadioDTO.Playlist,
        fileGroups: [LegacySimFileGroup.ID: LegacySimFileGroup],
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
        let condition: LegacySimRadioDTO.Condition
        var positions: [String]

        init(
            stationID: LegacySimStation.ID,
            model: LegacySimRadioDTO.Mix,
            fileGroups: [LegacySimFileGroup.ID: LegacySimFileGroup],
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
        let nextFragment: [LegacySimRadioDTO.FragmentRef]
        let mixPositions: [String: Double]
        let mixins: [Mix]

        init(
            stationID: LegacySimStation.ID,
            model: LegacySimRadioDTO.Fragment,
            fileGroups: [LegacySimFileGroup.ID: LegacySimFileGroup],
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
