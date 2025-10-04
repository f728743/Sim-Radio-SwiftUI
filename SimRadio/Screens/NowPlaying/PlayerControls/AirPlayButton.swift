//
//  AirPlayButton.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 16.05.2025.
//

import AVKit
import SwiftUI
import UIKit

struct AirPlayButton: View {
    @State private var presenter = AirPlayPresenter()

    var body: some View {
        ZStack {
            // Invisible AVRoutePickerView hosted correctly in SwiftUI hierarchy
            AirPlayRoutePickerView(presenter: $presenter)
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
                .opacity(0.0001)

            Button(
                action: {
                    presenter.presentAirPlayPicker()
                },
                label: {
                    Image(systemName: "airplayaudio")
                        .font(.system(size: 24))
                }
            )
        }
    }
}

private struct AirPlayRoutePickerView: UIViewRepresentable {
    @Binding var presenter: AirPlayPresenter

    func makeUIView(context _: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView(frame: .zero)
        view.prioritizesVideoDevices = false
        view.isHidden = true // keep it hidden; we trigger it programmatically
        // Hand the instance to the presenter so it can trigger the internal button safely
        presenter.attach(routePickerView: view)
        return view
    }

    func updateUIView(_: AVRoutePickerView, context _: Context) {
        // Nothing to update dynamically right now
    }
}

private final class AirPlayPresenter {
    private weak var routePickerView: AVRoutePickerView?

    func attach(routePickerView: AVRoutePickerView) {
        self.routePickerView = routePickerView
    }

    @MainActor
    func presentAirPlayPicker() {
        guard let routePickerView else {
            // Not yet mounted in the SwiftUI hierarchy; try again shortly
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.presentAirPlayPicker()
            }
            return
        }

        // Find the internal UIButton and trigger it
        if let internalButton = routePickerView.subviews.first(where: { $0 is UIButton }) as? UIButton {
            internalButton.sendActions(for: .touchUpInside)
        } else {
            // On some OS versions, subview hierarchy can change; as a fallback,
            // try UIControlEvents broadly or iterate deeper if needed.
            if let button = findButton(in: routePickerView) {
                button.sendActions(for: .touchUpInside)
            } else {
                print("Could not find internal button in AVRoutePickerView. Display may not work.")
            }
        }
    }

    @MainActor private func findButton(in view: UIView) -> UIButton? {
        if let button = view as? UIButton { return button }
        for sub in view.subviews {
            if let found = findButton(in: sub) { return found }
        }
        return nil
    }
}
