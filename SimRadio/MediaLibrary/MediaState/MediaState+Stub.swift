//
//  MediaState+Stub.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 23.04.2025.
//

extension MediaState {
    static var stub: MediaState = {
        let simRadioLibrary = SimRadioLibraryStub()
        let mediaState = MediaState(simRadioLibrary: simRadioLibrary)
        mediaState.simRadioLibrary(simRadioLibrary, didChange: .stub)
        return mediaState
    }()
}
