//
//  MixPlayingCondition.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 28.01.2025.
//

import CoreMedia

protocol MixPlayingCondition {
    func isSatisfied(
        forNextFragment tag: String,
        startingFrom second: CMTime,
        generator: inout RandomNumberGenerator
    ) -> Bool?
}

extension LegacySimRadioDTO.Condition: MixPlayingCondition {
    func isSatisfied(
        forNextFragment tag: String,
        startingFrom second: CMTime,
        generator: inout RandomNumberGenerator
    ) -> Bool? {
        switch type {
        case .nextFragment:
            isSatisfied(nextFragment: tag)
        case .random:
            isSatisfiedRandom(rnd: &generator)
        case .groupAnd:
            isGroupAndSatisfied(nextFragment: tag, starts: second, generator: &generator)
        case .groupOr:
            isGroupOrSatisfied(nextFragment: tag, starts: second, generator: &generator)
        case .timeInterval:
            isSatisfiedForTimeInterval(starts: second)
        }
    }

    func isSatisfied(nextFragment tag: String) -> Bool? {
        guard let next = fragmentTag else { return nil }
        return next == tag
    }

    func isSatisfiedRandom(rnd: inout RandomNumberGenerator) -> Bool? {
        guard let probability else { return nil }
        return probability >= Double.random(in: 0 ... 1, using: &rnd)
    }

    func isGroupAndSatisfied(
        nextFragment tag: String,
        starts sec: CMTime,
        generator: inout RandomNumberGenerator
    ) -> Bool? {
        guard let condition, condition.count > 1 else { return nil }
        return condition.firstIndex {
            $0.isSatisfied(forNextFragment: tag, startingFrom: sec, generator: &generator) == false
        } == nil
    }

    func isGroupOrSatisfied(
        nextFragment tag: String,
        starts sec: CMTime,
        generator: inout RandomNumberGenerator
    ) -> Bool? {
        guard let condition, condition.count > 1 else { return nil }
        return condition.firstIndex {
            $0.isSatisfied(forNextFragment: tag, startingFrom: sec, generator: &generator) == true
        } != nil
    }

    func isSatisfiedForTimeInterval(starts sec: CMTime) -> Bool? {
        guard let from = from.map({ secOfDay(hhmm: $0) }) ?? nil,
              let to = to.map({ secOfDay(hhmm: $0) }) ?? nil
        else {
            return nil
        }
        return CMTime(seconds: from) <= sec
            && sec <= CMTime(seconds: to)
    }
}

func secOfDay(hhmm: String) -> Double? {
    let time = hhmm.split { $0 == ":" }.map(String.init)
    guard time.count > 1 else {
        return nil
    }

    guard let h = Double(time[0]), let m = Double(time[1]) else {
        return nil
    }
    return (h * 60 * 60) + (m * 60)
}
