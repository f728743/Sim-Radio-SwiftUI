//
//  FileSource.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 02.05.2025.
//

import Foundation

struct FileFromGroup {
    let groupID: LegacySimFileGroup.ID
    let file: LegacySimFile
}

extension FileFromGroup {
    func url(local: Bool) -> URL {
        local ? groupID.localFileURL(for: file.url) : file.url
    }
}

protocol FileSource {
    func next(parentFile: FileFromGroup?, generator: inout RandomNumberGenerator) -> FileFromGroup?
}

struct ParticularFileSource: FileSource {
    let file: FileFromGroup

    func next(parentFile _: FileFromGroup?, generator _: inout RandomNumberGenerator) -> FileFromGroup? {
        file
    }
}

class AttachedFileSource: FileSource {
    func next(parentFile: FileFromGroup?, generator: inout RandomNumberGenerator) -> FileFromGroup? {
        if let parentFile, parentFile.file.attaches.count > 0 {
            let attachGroupID: LegacySimFileGroup.ID = .init(
                value: parentFile
                    .groupID
                    .value
                    .split(separator: "/")
                    .dropLast()
                    .joined(separator: "/") + "/\(LegacySimRadioMedia.attachesGroupTag)"
            )
            return FileFromGroup(
                groupID: attachGroupID,
                file: parentFile.file.attaches[
                    Int(Double(parentFile.file.attaches.count) * Double.random(in: 0 ... 1, using: &generator))
                ]
            )
        }
        return nil
    }
}

class GroupFileSource: FileSource {
    var randomFiles: NonRepeatingRandomizer<LegacySimFile>
    let groupID: LegacySimFileGroup.ID
    init?(fileGroup: LegacySimFileGroup) {
        guard let files = NonRepeatingRandomizer(
            elements: fileGroup.files,
            avoidRepeatsRatio: 3.0 / 7.0
        ) else {
            return nil
        }
        groupID = fileGroup.id
        randomFiles = files
    }

    func next(parentFile _: FileFromGroup?, generator: inout RandomNumberGenerator) -> FileFromGroup? {
        .init(groupID: groupID, file: randomFiles.next(generator: &generator))
    }
}

extension LegacySimFileGroup.ID {
    init(tag: String, prefix: String) {
        self.init(value: "\(prefix)/\(tag)")
    }
}

extension Dictionary where Iterator.Element == (key: LegacySimFileGroup.ID, value: LegacySimFileGroup) {
    func fileGroup(tag: String, stationID: LegacySimStation.ID) -> LegacySimFileGroup? {
        let stationFiles = self[LegacySimFileGroup.ID(tag: tag, prefix: stationID.value)]
        let seriesFiles = self[LegacySimFileGroup.ID(tag: tag, prefix: stationID.seriesID.value)]
        return stationFiles ?? seriesFiles
    }
}

func makeFileSource(
    stationID: LegacySimStation.ID,
    model: LegacySimRadioDTO.Source,
    fileGroups: [LegacySimFileGroup.ID: LegacySimFileGroup],
    generator _: inout RandomNumberGenerator
) -> FileSource? {
    switch model.type {
    case .file:
        guard
            let fileTag = model.fileTag,
            let groupTag = model.groupTag,
            let fileGroup = fileGroups.fileGroup(tag: groupTag, stationID: stationID),
            let file = fileGroup.files.first(where: { $0.tag == fileTag })
        else { return nil }
        return ParticularFileSource(file: .init(groupID: fileGroup.id, file: file))

    case .group:
        guard
            let groupTag = model.groupTag,
            let fileGroup = fileGroups.fileGroup(tag: groupTag, stationID: stationID)
        else { return nil }
        return GroupFileSource(fileGroup: fileGroup)

    case .attach:
        return AttachedFileSource()
    }
}
