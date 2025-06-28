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
    func next(parentFile: FileFromGroup?, rnd: inout RandomNumberGenerator) -> FileFromGroup?
}

struct ParticularFileSource: FileSource {
    let file: FileFromGroup

    func next(parentFile _: FileFromGroup?, rnd _: inout RandomNumberGenerator) -> FileFromGroup? {
        file
    }
}

struct AttachedFileSource: FileSource {
    func next(parentFile: FileFromGroup?, rnd: inout RandomNumberGenerator) -> FileFromGroup? {
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
                    Int(Double(parentFile.file.attaches.count) * Double.random(in: 0 ... 1, using: &rnd))
                ]
            )
        }
        return nil
    }
}

struct GroupFileSource: FileSource {
    var randomFiles: RandomFilePicker
    let groupID: LegacySimFileGroup.ID
    init?(fileGroup: LegacySimFileGroup, rnd: RandomNumberGenerator) {
        guard let files = RandomFilePicker(
            from: fileGroup.files,
            withDontRepeatRatio: 3.0 / 7.0,
            rnd: rnd
        ) else {
            return nil
        }
        groupID = fileGroup.id
        randomFiles = files
    }

    func next(parentFile _: FileFromGroup?, rnd _: inout RandomNumberGenerator) -> FileFromGroup? {
        .init(groupID: groupID, file: randomFiles.next())
    }
}

class RandomFilePicker {
    private var discardPile: [LegacySimFile] = []
    private var draw: [LegacySimFile] = []
    private let maxDiscardPileCount: Int
    private var rnd: RandomNumberGenerator

    init?(
        from: [LegacySimFile],
        withDontRepeatRatio: Double,
        rnd: RandomNumberGenerator
    ) {
        maxDiscardPileCount = max(1, Int(withDontRepeatRatio * Double(from.count)))
        if from.count < 2 {
            return nil
        }
        draw = from
        self.rnd = rnd
    }

    func next() -> LegacySimFile {
        let index = Int(Double(draw.count) * Double.random(in: 0 ... 1, using: &rnd))
        let res = draw[index]

        discardPile.append(res)
        draw.remove(at: index)
        if discardPile.count > maxDiscardPileCount {
            let putBack = discardPile[0]
            discardPile.remove(at: 0)
            draw.append(putBack)
        }
        return res
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
    rnd: RandomNumberGenerator
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
        return GroupFileSource(fileGroup: fileGroup, rnd: rnd)

    case .attach:
        return AttachedFileSource()
    }
}
