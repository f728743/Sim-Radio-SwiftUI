//
//  MediaState+Stub.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 23.04.2025.
//

extension DefaultMediaState {
    static var stub: DefaultMediaState = {
        let simRadioLibrary = SimRadioLibraryStub()
        let mediaState = DefaultMediaState(simRadioLibrary: simRadioLibrary)
        mediaState.simRadioLibrary(simRadioLibrary, didChange: .stub, nonPersistedSeries: [])
        return mediaState
    }()
}
