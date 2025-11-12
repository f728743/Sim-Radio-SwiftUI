//
//  CommandProfile.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 10.05.2025.
//

public struct CommandProfile: Equatable {
    public let isLiveStream: Bool
    public let isSwitchTrackEnabled: Bool

    public init(isLiveStream: Bool, isSwitchTrackEnabled: Bool) {
        self.isLiveStream = isLiveStream
        self.isSwitchTrackEnabled = isSwitchTrackEnabled
    }
}
