//
//  SearchScreen.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 23.09.2025.
//

import SwiftUI

struct SearchScreen: View {
    @State private var viewModel: SearchScreenViewModel
    @State private var searchText: String = "rock"
    
    init() {
        _viewModel = State(
            wrappedValue: SearchScreenViewModel()
        )
    }
    
    var body: some View {
        Button("Search") {
            viewModel.search(query: searchText)
        }
        Text("Looking for something?")
            .navigationTitle("Search")
            .searchable(text: $searchText, placement: .toolbar, prompt: Text("Search..."))
    }
}

#Preview {
    SearchScreen()
}
