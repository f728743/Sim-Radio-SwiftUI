//
//  SearchScreen.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 23.09.2025.
//

import SwiftUI

struct SearchScreen: View {
    @State private var viewModel = SearchScreenViewModel()
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Searching...")
                    .padding()
            } else if let errorMessage = viewModel.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }
            
            if viewModel.stations.isEmpty && !viewModel.isLoading && viewModel.errorMessage == nil {
                ContentUnavailableView.search
            } else {
                List(viewModel.stations) { station in
                    StationRow(station: station) {
                        viewModel.playStation(station)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Search")
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text("Search for radio stations...")
        )
    }
}

struct StationRow: View {
    let station: RealRadioStationDTO
    let onPlay: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(station.name)
                    .font(.headline)
                
                if let country = station.country {
                    Text(country)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let tags = station.tags, !tags.isEmpty {
                    Text(tags)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: onPlay) {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SearchScreen()
}
