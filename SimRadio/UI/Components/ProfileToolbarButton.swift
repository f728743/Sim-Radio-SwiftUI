//
//  ProfileToolbarButton.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.01.2025.
//

import SwiftUI

struct ProfileToolbarButton: View {
    var body: some View {
        Image(systemName: "person.crop.circle")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(Color(.palette.brand))
    }
}
