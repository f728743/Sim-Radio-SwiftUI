import MediaLibrary

extension SimRadioDTO.Playlist {
    var availableModes: [MediaPlaybackMode] {
        guard let options, options.available.isEmpty == false else { return [] }

        let alternate = options.alternateInterval.map { _ in
            [MediaPlaybackMode(id: .alternate, title: "Alternate")]
        } ?? []

        let available = options.available.map {
            MediaPlaybackMode(id: .init(value: $0.id.value), title: $0.title)
        }
        return alternate + available
    }
}

extension MediaPlaybackMode.ID {
    static var alternate: Self {
        .init(value: "alternate_playback")
    }
}

extension SimRadioDTO.Playlist {
    func mode(for id: MediaPlaybackMode.ID?) throws -> PlaylistBuilder.PlaylistMode? {
        guard let id else { return defaultMode }
        if id == .alternate {
            guard let interval = options?.alternateInterval else {
                throw PlaylistGenerationError.wrongMode
            }
            return .alternate(interval)
        }
        guard let option = options?.available.first(where: { $0.id.value == id.value }) else {
            throw PlaylistGenerationError.wrongMode
        }
        return .option(option.id)
    }

    private var defaultMode: PlaylistBuilder.PlaylistMode? {
        guard let options, options.available.isEmpty == false else { return nil }
        if let interval = options.alternateInterval {
            return .alternate(interval)
        }
        return options.available.first.map { .option($0.id) }
    }
}
