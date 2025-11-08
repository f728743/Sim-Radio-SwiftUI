//
//  ExpandableNowPlaying.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 17.11.2024.
//

import SwiftUI

enum PlayerMatchedGeometry {
    case artwork
    case backgroundView
}

struct ExpandableNowPlaying: View {
    @Binding var show: Bool
    @Binding var expanded: Bool
    var collapsedFrame: CGRect
    @Environment(PlayerController.self) var model
    @State private var offsetY: CGFloat = 0.0
    @State private var needRestoreProgressOnActive: Bool = false
    @State private var windowProgress: CGFloat = 0.0
    @State private var progressTrackState: CGFloat = 0.0
    @State private var expandProgress: CGFloat = 0.0
    @Namespace private var animationNamespace

    var body: some View {
        expandableNowPlaying
            .onChange(of: expanded) {
                if expanded {
                    stacked(progress: 1, withAnimation: true)
                }
            }
            .onPreferenceChange(NowPlayingExpandProgressPreferenceKey.self) { [$expandProgress] value in
                $expandProgress.wrappedValue = value
            }
    }
}

private extension ExpandableNowPlaying {
    var isFullyExpanded: Bool {
        expandProgress >= 1
    }

    var isFullyCollapsed: Bool {
        expandProgress.isZero
    }

    var expandableNowPlaying: some View {
        GeometryReader {
            let size = $0.size
            ZStack(alignment: .top) {
                NowPlayingBackground(
                    colors: model.colors.map { Color($0) },
                    expanded: expanded,
                    isFullExpanded: isFullyExpanded
                )
                CompactNowPlaying(
                    expanded: $expanded,
                    animationNamespace: animationNamespace
                )
                .opacity(expanded ? 0 : 1)

                RegularNowPlaying(
                    expanded: expanded,
                    size: size,
                    animationNamespace: animationNamespace
                )
                .opacity(expanded ? 1 : 0)
                ProgressTracker(progress: progressTrackState)
            }
            .frame(height: expanded ? nil : ViewConst.compactNowPlayingHeight, alignment: .top)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, insets.bottom)
            .padding(.leading, insets.leading)
            .padding(.trailing, insets.trailing)
            .offset(y: offsetY)
            .gesture(
                PanGesture(
                    onChange: { handleGestureChange(value: $0, viewSize: size) },
                    onEnd: { handleGestureEnd(value: $0, viewSize: size) }
                )
            )
            .ignoresSafeArea()
        }
        .opacity(isFullyCollapsed ? 0 : 1)
    }

    func handleGestureChange(value: PanGesture.Value, viewSize: CGSize) {
        guard expanded else { return }
        let translation = max(value.translation.height, 0)
        offsetY = translation
        windowProgress = max(min(translation / viewSize.height, 1), 0)
        stacked(progress: 1 - windowProgress, withAnimation: false)
    }

    func handleGestureEnd(value: PanGesture.Value, viewSize: CGSize) {
        guard expanded else { return }
        let translation = max(value.translation.height, 0)
        let velocity = value.velocity.height / 5
        withAnimation(.playerExpandAnimation) {
            if (translation + velocity) > (viewSize.height * 0.3) {
                expanded = false
                resetStackedWithAnimation()
            } else {
                stacked(progress: 1, withAnimation: true)
            }
            offsetY = 0
        }
    }

    func stacked(progress: CGFloat, withAnimation: Bool) {
        if withAnimation {
            SwiftUI.withAnimation(.playerExpandAnimation) {
                progressTrackState = progress
            }
        } else {
            progressTrackState = progress
        }
    }

    func resetStackedWithAnimation() {
        withAnimation(.playerExpandAnimation) {
            progressTrackState = 0
        }
    }

    var insets: EdgeInsets {
        if expanded {
            return .init(top: 0, leading: 0, bottom: 0, trailing: 0)
        }

        return .init(
            top: 0,
            leading: collapsedFrame.minX,
            bottom: UIScreen.size.height - collapsedFrame.maxY,
            trailing: UIScreen.size.width - collapsedFrame.maxX
        )
    }
}

extension Animation {
    static let playerExpandAnimationDuration: TimeInterval = 0.3
    static var playerExpandAnimation: Animation {
        .smooth(duration: playerExpandAnimationDuration, extraBounce: 0)
    }
}

private struct ProgressTracker: View, @preconcurrency Animatable {
    var progress: CGFloat = 0

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .preference(key: NowPlayingExpandProgressPreferenceKey.self, value: progress)
    }
}

#Preview {
    @Previewable @State var dependencies = Dependencies.stub
    @Previewable @State var playerController = PlayerController.stub

    OverlaidRootView()
        .environment(playerController)
        .environment(dependencies)
}
