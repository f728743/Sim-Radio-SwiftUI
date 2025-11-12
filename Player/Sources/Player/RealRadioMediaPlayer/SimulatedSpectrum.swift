//
//  SimulatedSpectrum.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 04.11.2025.
//

import Foundation

struct SimulatedSpectrum {
    var currentBands: [Float] = Array(repeating: 0.0, count: MediaPlayer.Const.frequencyBands)

    mutating func reset() {
        currentBands = Array(repeating: 0.0, count: MediaPlayer.Const.frequencyBands)
    }

    mutating func generate() -> [Float] {
        // --- Simulation settings (feel free to experiment) ---

        // 1. Decay factor: how quickly the bars "fall"
        // (closer to 1.0 = slower, closer to 0.0 = faster)
        let decayFactor: Float = 0.82

        // 2. Minimum "noise" level (so the spectrum doesn't completely "die")
        let noiseFloor: Float = 0.05

        // 3. Chance of a "strong beat" on low frequencies
        let bassBeatChance: Float = 0.15 // 15% chance per frame

        // 4. Chance of "flickering" on mid and high frequencies
        let flickerChance: Float = 0.25 // 25% chance

        // --- Generation logic ---

        // Step 1: Apply decay to all bands
        // Each band becomes slightly "quieter" than in the previous frame
        for i in 0 ..< currentBands.count {
            currentBands[i] *= decayFactor
        }

        // Step 2: Simulate a "beat" (strong bass hit)
        // This creates "pulsation" on low frequencies
        if Float.random(in: 0 ... 1) < bassBeatChance {
            let beatStrength = Float.random(in: 0.4 ... 0.7)
            // Hit the bass (index 0) and slightly the mid-bass (index 1)
            currentBands[0] = max(currentBands[0], beatStrength * 0.6)
            currentBands[1] = max(currentBands[1], beatStrength)
            currentBands[2] = max(currentBands[2], beatStrength * 0.3)
        }

        // Step 3: Add random "flickering" (jitter)
        // This simulates cymbals, vocals and other instruments
        for i in 1 ..< currentBands.count where Float.random(in: 0 ... 1) < flickerChance { // Skip bass (index 0)
            let flickerStrength = Float.random(in: 0.2 ... 0.6)
            currentBands[i] = max(currentBands[i], flickerStrength)
        }

        // Step 4: Apply noise floor and limit maximum value
        // This ensures values are always in the range [noiseFloor...1.0]
        return currentBands.map { max(noiseFloor, min($0, 1.0)) }
    }
}
