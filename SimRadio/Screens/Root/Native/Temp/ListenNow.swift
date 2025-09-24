//
//  ListenNow.swift
//  AppleMusicSheet
//
//  Created by Alexey Vorobyov on 25.09.2025.
//

import SwiftUI

struct ListenNow: View {
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    Image("Card 1")
                        .resizable()
                        .aspectRatio(contentMode: .fit)

                    Image("Card 2")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .padding()
                .padding(.bottom, 100)
            }
            .navigationTitle("Listen Now")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        VStack {}
                            .navigationTitle("Account Info")
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.title3)
                    }
                }
            }
        }
    }
}
