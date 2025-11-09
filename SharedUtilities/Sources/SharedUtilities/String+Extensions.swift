//
//  String+Extensions.swift
//  SharedUtilities
//
//  Created by Alexey Vorobyov
//

import Foundation

public extension String {
    var nonCryptoHash: UInt64 {
        var result = UInt64(5381)
        let buf = [UInt8](utf8)
        for byte in buf {
            result = 127 * (result & 0x00FF_FFFF_FFFF_FFFF) + UInt64(byte)
        }
        return result
    }
}
