//
//  CodableStringIDProtocol.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 07.07.2025.
//

public protocol CodableStringIDProtocol: Codable, Hashable, Sendable {
    var value: String { get }
    init(value: String)
}

public extension CodableStringIDProtocol {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self.init(value: value)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
