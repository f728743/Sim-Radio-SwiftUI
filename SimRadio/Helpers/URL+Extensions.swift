//
//  URL+Extensions.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 08.04.2025.
//

import Foundation
import Kingfisher
import UIKit

extension URL {
    var image: UIImage? {
        get async {
            try? await KingfisherManager.shared.retrieveImage(with: self).image
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
