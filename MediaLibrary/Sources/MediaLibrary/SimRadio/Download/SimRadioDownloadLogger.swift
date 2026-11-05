//
//  SimRadioDownloadLogger.swift
//  MediaLibrary
//

private enum DownloadLog {
    case info(verbose: Bool), warning, error
}

private let logSettings: [DownloadLog] = [.warning, .error]

enum SimRadioDownloadLogger {
    static var isInfoEnabled: Bool {
        logSettings.logInfo
    }

    static var isVerboseInfoEnabled: Bool {
        logSettings.logVerboseInfo
    }

    static func log(verboseInfo: String) {
        guard logSettings.logVerboseInfo else { return }
        print(verboseInfo)
    }

    static func log(info: String) {
        guard logSettings.logInfo else { return }
        print(info)
    }

    static func log(warning: String) {
        guard logSettings.contains(
            where: {
                if case .warning = $0 {
                    return true
                }
                return false
            }
        ) else { return }
        print(warning)
    }

    static func log(error: String) {
        guard logSettings.contains(
            where: {
                if case .error = $0 {
                    return true
                }
                return false
            }
        ) else { return }
        print(error)
    }
}

extension Collection<DownloadLog> {
    var logVerboseInfo: Bool {
        contains(
            where: {
                if case let .info(verbose) = $0, verbose {
                    return true
                }
                return false
            }
        )
    }

    var logInfo: Bool {
        contains(
            where: {
                if case .info = $0 {
                    return true
                }
                return false
            }
        )
    }
}
