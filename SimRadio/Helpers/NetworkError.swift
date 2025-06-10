//
//  NetworkError.swift
//  SimRadio
//
//  Created by Alexey Vorobyov
//

import Foundation

enum NetworkError: Error, LocalizedError {
    case httpError(statusCode: Int, description: String?)
    case nonHttpResponse

    var errorDescription: String? {
        switch self {
        case let .httpError(status, description):
            description ?? "HTTP Error Status Code: \(status)"
        case .nonHttpResponse:
            "Non HTTP Response"
        }
    }
}

extension URLResponse {
    var networkError: NetworkError? {
        guard let httpResponse = self as? HTTPURLResponse else {
            return .nonHttpResponse
        }
        if !httpResponse.statusCode.isSuccessStatusCode {
            return NetworkError.httpError(
                statusCode: httpResponse.statusCode,
                description: httpResponse.description
            )
        }
        return nil
    }
}

private extension Int {
    var isSuccessStatusCode: Bool {
        (200 ... 299).contains(self)
    }
}
