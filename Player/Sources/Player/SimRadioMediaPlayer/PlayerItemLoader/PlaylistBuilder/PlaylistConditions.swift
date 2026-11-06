//
//  PlaylistConditions.swift
//  Player
//

import AVFoundation
import MediaLibrary
import SharedUtilities

extension SimRadioDTO.Condition {
    func isSatisfied(
        nextFragmentID: SimRadioDTO.Fragment.ID,
        startingFrom second: CMTime,
        generator: inout RandomNumberGenerator
    ) throws -> Bool {
        let nextFragmentSatisfied = nextFragment == nil ?
            true : nextFragment == nextFragmentID

        let probabilitySatisfied = probability == nil ?
            true : Double.random(in: 0 ... 1, using: &generator) >= probability!

        let timeIntervalSatisfied = timeInterval == nil ?
            true : try timeInterval!.contains(second)

        return nextFragmentSatisfied && probabilitySatisfied && timeIntervalSatisfied
    }
}

extension SimRadioDTO.TimeInterval {
    func contains(_ second: CMTime) throws -> Bool {
        guard let from = secOfDay(hhmm: from),
              let to = secOfDay(hhmm: to)
        else {
            throw PlaylistGenerationError.invalidTimeInterval(from: from, to: to)
        }
        return CMTime(seconds: from) <= second && second <= CMTime(seconds: to)
    }
}

func secOfDay(hhmm: String) -> Double? {
    let time = hhmm.split { $0 == ":" }.map(String.init)
    guard time.count > 1, let h = Double(time[0]), let m = Double(time[1]) else {
        return nil
    }
    return (h * 60 * 60) + (m * 60)
}
