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
    @State private var selection: Media.ID?
    @State private var viewModel: MediaListScreenViewModel

    init(items: [Media], listMeta: MediaList.Meta? = nil) {
        _viewModel = State(
            wrappedValue: MediaListScreenViewModel(items: items, listMeta: listMeta)
        )
    }

    var body: some View {
        content
            .contentMargins(.bottom, ViewConst.tabbarHeight + 27, for: .scrollContent)
            .contentMargins(.bottom, ViewConst.tabbarHeight, for: .scrollIndicators)
            .background(Color(.palette.appBackground))
            .toolbar {
                Button { print("Profile tapped") }
                    label: { ProfileToolbarButton() }
            }
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
                header(listMeta: listMeta)
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
                .listRowBackground(Color(.palette.appBackground))
        }
        .listStyle(.plain)
    }

    func header(listMeta: MediaList.Meta) -> some View {
        VStack(spacing: 0) {
            ArtworkView(
                .radio(listMeta.artwork),
                cornerRadius: 10
            )
            .padding(.horizontal, 52)

            Text(listMeta.title)
                .font(.appFont.mediaListHeaderTitle)
                .padding(.top, 18)

            if let subtitle = listMeta.subtitle {
                Text(subtitle)
                    .font(.appFont.mediaListHeaderSubtitle)
                    .foregroundStyle(Color(.palette.textSecondary))
                    .padding(.top, 2)
            }

            buttons
                .padding(.top, 14)
        }
        .listRowBackground(Color(.palette.appBackground))
    }

    var buttons: some View {
        HStack(spacing: 16) {
            Button {
                print("Play")
            }
            label: {
                buttonLabel("Play", systemImage: "play.fill")
            }

            Button {
                print("Shuffle")
            }
            label: {
                buttonLabel("Shuffle", systemImage: "shuffle")
            }
        }
        .buttonStyle(AppleMusicButtonStyle())
    }

    func buttonLabel(_ title: String, systemImage icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
            Text(title)
                .font(.appFont.button)
        }
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
                : Color(.palette.appBackground)
        )
        .alignmentGuide(.listRowSeparatorLeading) {
            isLastItem ? $0[.leading] : $0[.leading] + 60
        }
        .swipeActions(edge: .trailing) {
            ForEach(viewModel.swipeButtons(media: item.id), id: \.self) { button in
                Button(
                    action: { [weak viewModel] in
                        viewModel?.onSwipeActions(media: item.id, button: button)
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
        items: dependencies.mediaState.mediaList.first?.items ?? [],
        listMeta: dependencies.mediaState.mediaList.first?.meta
    )
    .environment(dependencies)
}
