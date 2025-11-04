//
//  MediaItemScreen.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 24.09.2025.
//

import SwiftUI

struct MediaItemScreen: View {
    @Environment(Dependencies.self) var dependencies
    @State private var viewModel: MediaItemScreenViewModel
    @State private var selection: Media.ID?

    init(item: Media) {
        _viewModel = State(
            wrappedValue: MediaItemScreenViewModel(item: item)
        )
    }

    var body: some View {
        content
            .task {
                viewModel.mediaState = dependencies.mediaState
                viewModel.player = dependencies.mediaPlayer
            }
    }
}

private extension MediaItemScreen {
    @ViewBuilder
    var content: some View {
        List {
            let item = viewModel.item
            let meta = item.meta
            MediaListHeaderView(
                item: .init(
                    title: meta.title,
                    subtitle: meta.subtitle,
                    artwork: .radio(meta.artwork)
                ),
                onEvent: { _ in
                    viewModel.onPlay()
                }
            )
            .listRowInsets(.rowInsets)
            .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
            .alignmentGuide(.listRowSeparatorTrailing) { $0[.trailing] + ViewConst.screenPaddings }
            .listSectionSeparator(.hidden, edges: .top)
            .padding(.top, 14)
            .padding(.bottom, 25)

            ItemView(
                model: .init(
                    title: viewModel.item.meta.title,
                    downloadStatus: viewModel.downloadStatus(for: item.id),
                    activity: viewModel.mediaActivity(item.id)
                ),
                index: 1
            )
            .listRowInsets(.rowInsets)
            .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
            .alignmentGuide(.listRowSeparatorTrailing) { $0[.trailing] + ViewConst.screenPaddings }
            .onTapGesture {
                viewModel.onSelect(media: item.id)
                selection = item.id
                Task {
                    try? await Task.sleep(for: .milliseconds(80))
                    selection = nil
                }
            }
        }
        .listStyle(.plain)
    }
}

private struct ItemView: View {
    struct Model {
        let title: String
        var downloadStatus: MediaDownloadStatus?
        var activity: MediaActivity?
    }

    let model: Model
    let index: Int

    var body: some View {
        HStack(spacing: 9) {
            Group {
                if let activity = model.activity {
                    MediaActivityIndicator(state: activity)
                        .foregroundStyle(Color.brand)
                } else {
                    Text("\(index)")
                }
            }
            .frame(width: 22)

            Text(model.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            if let downloadStatus = model.downloadStatus {
                MediaDownloadProgressView(status: downloadStatus)
            }
        }
        .font(.system(size: 16))
        .frame(height: 50)
        .contentShape(.rect)
    }
}

#Preview {
    @Previewable @State var dependencies = Dependencies.stub
    @Previewable @State var playerController = PlayerController.stub
    let item: Media = dependencies.mediaState.mediaList.first!.items.first!
    MediaItemScreen(item: item)
        .environment(dependencies)
        .environment(playerController)
}
