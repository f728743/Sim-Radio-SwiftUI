//
//  VolumeSliderViewModel.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 15.05.2025.
//

import AVFoundation
import SwiftUI

@MainActor
class VolumeSliderViewModel: ObservableObject {
    @Published var currentVolume: Double = 0.0
    private var audioSession = AVAudioSession.sharedInstance()
    private var volumeObservation: NSKeyValueObservation?
    private var isSliderActive: Bool = false
    let volumeViewProxy = MPVolumeViewProxy()

    init() {
        currentVolume = Double(audioSession.outputVolume)
        observeVolumeChanges()
    }

    private func observeVolumeChanges() {
        volumeObservation = audioSession.observe(\.outputVolume, options: [.new, .initial]) { [weak self] _, change in
            guard let self, let newVolume = change.newValue else { return }
            DispatchQueue.main.async {
                guard !self.isSliderActive else { return }
                let value = Double(newVolume)
                if abs(self.currentVolume - value) > 0.001 {
                    withAnimation {
                        self.currentVolume = value
                    }
                }
            }
        }
    }

    func setVolume(_ volume: Double) {
        guard let mpVolumeView = volumeViewProxy.mpVolumeView,
              let slider = mpVolumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        else {
            print("MPVolumeView or its UISlider not found.")
            return
        }

        if abs(slider.value - Float(volume)) > 0.001 {
            slider.setValue(Float(volume), animated: false)
        }
    }

    func setSliderActive(_ isActive: Bool) {
        isSliderActive = isActive
    }

    deinit {
        volumeObservation?.invalidate()
    }
}
