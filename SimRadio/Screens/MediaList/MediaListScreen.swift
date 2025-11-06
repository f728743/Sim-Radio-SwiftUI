//
//  MediaListScreen.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 09.12.2024.
//

import Kingfisher
import SwiftUI

struct MediaListScreen: View {
    @Environment(Dependencies.self) var dependencies
    @State private var selection: MediaID?
    @State private var viewModel: MediaListScreenViewModel

    init(items: [Media], listMeta: MediaList.Meta? = nil) {
        _viewModel = State(
            wrappedValue: MediaListScreenViewModel(items: items, listMeta: listMeta)
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

private extension MediaListScreen {
    var content: some View {
        List {
            if let listMeta = viewModel.listMeta {
                MediaListHeaderView(
                    item: .init(
                        title: listMeta.title,
                        subtitle: listMeta.subtitle,
                        artwork: .album(listMeta.artwork)
                    ),
                    onEvent: { event in
                        switch event {
                        case .play: viewModel.onPlay()
                        case .shuffle: viewModel.onShuffle()
                        }
                    }
                )
                .padding(.top, 7)
                .padding(.bottom, 26)
                .listRowInsets(.rowInsets)
                .listSectionSeparator(.hidden, edges: .top)
                .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
            }

            list

            footer
                .padding(.top, 17)
                .listRowInsets(.rowInsets)
                .listSectionSeparator(.hidden, edges: .bottom)
        }
        .listStyle(.plain)
        .contentMargins(.bottom, ViewConst.screenPaddings, for: .scrollContent)
    }

    var list: some View {
        ForEach(Array(viewModel.items.enumerated()), id: \.offset) { offset, item in
            let isLastItem = offset == viewModel.items.count - 1
            media(item, isLastItem: isLastItem)
        }
    }

    func media(_ item: Media, isLastItem: Bool) -> some View {
        MediaItemView(
            model: .init(
                artwork: item.meta.artwork,
                title: item.meta.title,
                subtitle: item.meta.subtitle,
                downloadStatus: viewModel.downloadStatus(for: item.id),
                activity: viewModel.mediaActivity(item.id)
            )
        )
        .contentShape(.rect)
        .listRowInsets(.rowInsets)
        .listRowBackground(
            item.id == selection
                ? Color(uiColor: .systemGray4)
                : Color(.systemBackground)
        )
        .alignmentGuide(.listRowSeparatorLeading) {
            isLastItem ? $0[.leading] : $0[.leading] + 60
        }
        .swipeActions(edge: .trailing) {
            ForEach(viewModel.swipeButtons(mediaID: item.id), id: \.self) { button in
                Button(
                    action: { [weak viewModel] in
                        viewModel?.onSwipeActions(mediaID: item.id, button: button)
                    },
                    label: {
                        Label(button.label, systemImage: button.systemImage)
                    }
                )
                .tint(button.color)
            }
        }
        .onTapGesture {
            viewModel.onSelect(media: item.id)
            selection = item.id
            Task {
                try? await Task.sleep(for: .milliseconds(80))
                selection = nil
            }
        }
    }

    @ViewBuilder
    var footer: some View {
        Text(viewModel.footer)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(Color(.palette.textTertiary))
            .font(.appFont.mediaListItemFooter)
    }
}

#Preview {
    @Previewable @State var dependencies = Dependencies.stub

    MediaListScreen(
        items: dependencies.mediaState.mediaList(persisted: false).first?.items ?? [],
        listMeta: dependencies.mediaState.mediaList(persisted: false).first?.meta
    )
    .environment(dependencies)
}
