//
//  SystemMediaInterface.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 08.05.2025.
//

import MediaPlayer

@MainActor
protocol SystemMediaInterfaceDelegate: AnyObject {
    func systemMediaInterface(_ interface: SystemMediaInterface, didReceiveRemoteCommand command: RemoteCommand)
}

@MainActor
class SystemMediaInterface {
    weak var delegate: SystemMediaInterfaceDelegate?

    func setRemoteCommandProfile(_ profile: CommandProfile) {
        let commands: [RemoteCommand] = profile.isLiveStream ? [
            .play, .stop, .nextTrack, .previousTrack
        ] : [
            .play, .pause, .stop, .togglePausePlay, .nextTrack, .previousTrack
        ]
        configureRemoteCommands(
            commands,
            disabledCommands: profile.isSwitchTrackEnabled ? [] : [.nextTrack, .previousTrack]
        )
    }

    func setNowPlayingInfo(_ info: NowPlayingInfo?) {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info?.mpNowPlayingInfo
    }
}

private extension SystemMediaInterface {
    func configureRemoteCommands(_ commands: [RemoteCommand], disabledCommands: [RemoteCommand]) {
        for command in RemoteCommand.allCases {
            command.removeHandler()
            if commands.contains(command) {
                command.addHandler { [weak self] remoteCommand, _ in
                    guard let self else { return .commandFailed }
                    delegate?.systemMediaInterface(self, didReceiveRemoteCommand: remoteCommand)
                    return .success
                }
            }
            command.setDisabled(disabledCommands.contains(command))
        }
    }
}

extension RemoteCommand {
    var mpRemoteCommand: MPRemoteCommand {
        let commandCenter = MPRemoteCommandCenter.shared()
        switch self {
        case .pause:
            return commandCenter.pauseCommand
        case .play:
            return commandCenter.playCommand
        case .stop:
            return commandCenter.stopCommand
        case .togglePausePlay:
            return commandCenter.togglePlayPauseCommand
        case .nextTrack:
            return commandCenter.nextTrackCommand
        case .previousTrack:
            return commandCenter.previousTrackCommand
        }
    }

    func removeHandler() {
        mpRemoteCommand.removeTarget(nil)
    }

    func addHandler(_ handler: @escaping (RemoteCommand, MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus) {
        mpRemoteCommand.addTarget { handler(self, $0) }
    }

    func setDisabled(_ isDisabled: Bool) {
        mpRemoteCommand.isEnabled = !isDisabled
    }
}

extension NowPlayingInfo {
    var mpNowPlayingInfo: [String: Any] {
        var info = [String: Any]()
        info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        info[MPNowPlayingInfoPropertyIsLiveStream] = meta.isLiveStream
        info[MPMediaItemPropertyTitle] = meta.title
        info[MPMediaItemPropertyArtist] = meta.artist
        info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: meta.artwork.size) { _ in meta.artwork }
        if let queue {
            info[MPNowPlayingInfoPropertyPlaybackQueueIndex] = queue.index
            info[MPNowPlayingInfoPropertyPlaybackQueueCount] = queue.count
        }
        if let progress {
            info[MPMediaItemPropertyPlaybackDuration] = CMTime(seconds: progress.duration)
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTime(seconds: progress.elapsedTime)
        }
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        return info
    }
}
