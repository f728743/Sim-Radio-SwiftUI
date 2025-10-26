//
//  RealRadioMediaState.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.10.2025.
//

@MainActor
protocol RealRadioMediaState: AnyObject, Sendable {
    var realRadio: RealRadioMedia { get }
    var nonPersistedRealStations: [RealStation.ID] { get }
}
