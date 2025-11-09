//
//  Date+Extensions.swift
//  SharedUtilities
//
//  Created by Alexey Vorobyov on 29.01.2025.
//

import Foundation

public extension Date {
    var currentSecondOfDay: Double {
        let calendar = Calendar.current
        let h = calendar.component(.hour, from: self)
        let m = calendar.component(.minute, from: self)
        let s = calendar.component(.second, from: self)
        return Double(h * 60 * 60 + m * 60 + s)
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    static var tomorrow: Date? {
        Date().dayAfter
    }

    var dayAfter: Date? {
        guard let noon else { return nil }
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)
    }

    var noon: Date? {
        Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)
    }
}
