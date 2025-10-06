//
//  SearchScreenViewModel.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 04.10.2025.
//

import Foundation

@Observable @MainActor
class SearchScreenViewModel {
    let searchService = SearchService(apiService: APIService(baseURL: "https://cx10577.tw1.ru"))
    func search(query: String) {
        Task {
            do {
                let result =  try await searchService.search(query: query)
                print(result.data.stations.map(\.name))
            } catch {
                print("API call Error: \(error.localizedDescription)")
            }
        }
    }
}
