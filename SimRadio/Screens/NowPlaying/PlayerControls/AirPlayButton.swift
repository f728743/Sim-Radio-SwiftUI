//
//  AirPlayButton.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 16.05.2025.
//

import AVKit
import SwiftUI

struct AirPlayButton: View {
    private let airPlayPresenter = AirPlayPresenter()

    var body: some View {
        Button(
            action: {
                airPlayPresenter.presentAirPlayPicker()
            },
            label: {
                Image(systemName: "airplayaudio")
                    .font(.system(size: 24))
            }
        )
    }
}

private class AirPlayPresenter {
    @MainActor
    func presentAirPlayPicker() {
        let routePickerView = AVRoutePickerView()
        guard let rootViewController = UIApplication.keyWindow?.rootViewController
        else {
            print("Unable to find root view controller.")
            return
        }

        routePickerView.frame = .zero
        routePickerView.alpha = 0.0001
        routePickerView.isUserInteractionEnabled = false
        rootViewController.view.addSubview(routePickerView)

        if let internalButton = routePickerView.subviews.first(where: { $0 is UIButton }) as? UIButton {
            internalButton.sendActions(for: .touchUpInside)
        } else {
            print("Could not find internal button AVRoutePickerView. Display may not work.")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            routePickerView.removeFromSuperview()
        }
    }
}
