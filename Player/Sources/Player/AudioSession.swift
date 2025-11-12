//
//  AudioSession.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 08.05.2025.
//

import AVFAudio

@MainActor
protocol AudioSessionDelegate: AnyObject {
    func audioSessionInterruptionBegan()
    func audioSessionInterruptionEnded(shouldResume: Bool)
}

@MainActor
class AudioSession {
    private var interruptionTask: Task<Void, Never>?
    weak var delegate: AudioSessionDelegate?

    init() {
        setupAudioSession()
        setupAudioInterruptionObserver()
    }

    func setActive(_ active: Bool) {
        do {
            try AVAudioSession.sharedInstance().setActive(active)
        } catch {
            print("AVAudioSession setActive Error: \(error.localizedDescription)")
        }
    }

    deinit {
        interruptionTask?.cancel()
    }
}

private extension AudioSession {
    func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
        } catch {
            print("AVAudioSession configuring Error: \(error.localizedDescription)")
        }
    }

    func setupAudioInterruptionObserver() {
        interruptionTask = Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(
                named: AVAudioSession.interruptionNotification
            )

            for await notification in notifications {
                self?.handleAudioSessionInterruption(notification: notification)
            }
        }
    }

    private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let interruptionTypeRaw = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeRaw)
        else {
            return
        }

        switch interruptionType {
        case .began:
            delegate?.audioSessionInterruptionBegan()
        case .ended:
            if let optionsRaw = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsRaw)
                delegate?.audioSessionInterruptionEnded(shouldResume: options.contains(.shouldResume))
            }
        @unknown default:
            break
        }
    }
}
