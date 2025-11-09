//
//  URL+Extensions.swift
//  SharedUtilities
//
//  Created by Alexey Vorobyov on 08.04.2025.
//

import Kingfisher
import UIKit

public extension URL {
    var image: UIImage? {
        get async {
            return await ImageLoader.shared.getImage(for: self)
        }
    }

    func ensureDirectoryExists() throws {
        if !FileManager.default.fileExists(atPath: path) {
            try FileManager.default.createDirectory(
                at: self,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }

    func removeFileIfExists() throws {
        if isFileExists {
            try FileManager.default.removeItem(at: self)
        }
    }

    var isFileExists: Bool {
        FileManager.default.fileExists(atPath: path)
    }

    func isDirectoryEmpty() throws -> Bool {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return false
        }
        return try fileManager.contentsOfDirectory(atPath: path).isEmpty
    }

    @discardableResult
    func removeDirectoryIfEmpty() -> Bool {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return false
        }
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            if contents.isEmpty {
                try fileManager.removeItem(at: self)
                return true
            } else {
                return false
            }
        } catch {
            return false
        }
    }

    @discardableResult
    func remove() -> Bool {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: self)
            return true
        } catch {
            return false
        }
    }
}

public extension [URL] {
    /// Removes all empty directories in the array, starting from the most nested ones,
    /// and recursively checks parent directories for emptiness
    func removeEmptyDirectories() {
        // Process deepest directories first
        let sortedURLs = sorted { $0.pathComponents.count > $1.pathComponents.count }
        for url in sortedURLs {
            var currentURL = url
            while currentURL.pathComponents.count > 1 { // Don't remove root directory
                if currentURL.removeDirectoryIfEmpty() {
                    // If directory was removed, move to its parent
                    currentURL = currentURL.deletingLastPathComponent()
                } else {
                    // If directory isn't empty, stop going up
                    break
                }
            }
        }
    }

    /// Removes all files and directories at the specified URLs
    func removeAll() {
        forEach { $0.remove() }
    }
}

public extension String {
    func deletingLastPathComponent() -> String {
        split(separator: "/").dropLast().joined(separator: "/")
    }
}

private actor ImageLoader {
    static let shared = ImageLoader()
    
    private let requestModifier = AnyModifier { request in
        var modifiedRequest = request
        modifiedRequest.timeoutInterval = 1
        return modifiedRequest
    }
    
    private var loadingTasks: [URL: Task<UIImage?, Never>] = [:]
    
    func getImage(for url: URL) async -> UIImage? {
        if let existingTask = loadingTasks[url] {
            return await existingTask.value
        }
        
        let task = Task<UIImage?, Never> {
            let result: UIImage?
            do {
                let image = try await KingfisherManager.shared.retrieveImage(
                    with: url,
                    options: [.requestModifier(requestModifier)]
                ).image
                result = image
            } catch {
                result = nil
            }
            return result
        }
        
        loadingTasks[url] = task
        let result = await task.value
        loadingTasks[url] = nil
        return result
    }
}
