//
//  APIService.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 04.10.2025.
//

import Foundation

protocol APIServiceProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> APIResponse<T>
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

enum HTTPHeader {
    static let contentType = "Content-Type"
    static let authorization = "Authorization"
    static let accept = "Accept"
}

enum ContentType: String {
    case json = "application/json"
    case formData = "multipart/form-data"
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case statusCode(Int)
    case decodingError(Error)
    case encodingError(Error)
    case noData
    case unauthorized
    case serverError(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .statusCode(let code):
            return "HTTP Error: \(code)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Encoding error: \(error.localizedDescription)"
        case .noData:
            return "No data received"
        case .unauthorized:
            return "Unauthorized access"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

struct Endpoint {
    let method: HTTPMethod
    let path: String
    let queryParameters: [String: Any]?
    let body: Any?
    let headers: [String: String]?
    
    init(method: HTTPMethod,
         path: String,
         queryParameters: [String: Any]? = nil,
         body: Any? = nil,
         headers: [String: String]? = nil) {
        self.method = method
        self.path = path
        self.queryParameters = queryParameters
        self.body = body
        self.headers = headers
    }
}

struct APIResponse<T: Decodable> {
    let value: T
    let response: HTTPURLResponse
}

class APIService: APIServiceProtocol {
    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    init(baseURL: String,
         session: URLSession = .shared,
         decoder: JSONDecoder = JSONDecoder(),
         encoder: JSONEncoder = JSONEncoder()) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
        
        // Configure decoder and encoder
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder.dateEncodingStrategy = .iso8601
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let response: APIResponse<T> = try await self.request(endpoint)
        return response.value
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> APIResponse<T> {
        let urlRequest = try buildURLRequest(from: endpoint)
        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        try validateStatusCode(httpResponse.statusCode)
        let decodedData = try decoder.decode(T.self, from: data)
        return APIResponse(value: decodedData, response: httpResponse)
    }
}

private extension APIService {
    func buildURLRequest(from endpoint: Endpoint) throws -> URLRequest {
        guard let url = buildURL(from: endpoint) else {
            throw APIError.invalidURL
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method.rawValue
        urlRequest.timeoutInterval = 30
        // Set default headers
        urlRequest.setValue(ContentType.json.rawValue, forHTTPHeaderField: HTTPHeader.accept)
        // Set custom headers
        endpoint.headers?.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        // Set body if needed
        if let body = endpoint.body {
            if let encodableBody = body as? Encodable {
                urlRequest.httpBody = try encodeBody(encodableBody)
                urlRequest.setValue(ContentType.json.rawValue, forHTTPHeaderField: HTTPHeader.contentType)
            } else if let dataBody = body as? Data {
                urlRequest.httpBody = dataBody
            } else if let dictionaryBody = body as? [String: Any] {
                urlRequest.httpBody = try JSONSerialization.data(withJSONObject: dictionaryBody)
                urlRequest.setValue(ContentType.json.rawValue, forHTTPHeaderField: HTTPHeader.contentType)
            }
        }
        return urlRequest
    }
    
    private func buildURL(from request: Endpoint) -> URL? {
        var urlComponents = URLComponents(string: baseURL + request.path)
        if let queryParameters = request.queryParameters {
            urlComponents?.queryItems = queryParameters.map { key, value in
                URLQueryItem(name: key, value: "\(value)")
            }
        }
        return urlComponents?.url
    }
    
    private func encodeBody(_ body: Encodable) throws -> Data {
        do {
            return try encoder.encode(body)
        } catch {
            throw APIError.encodingError(error)
        }
    }
    
    private func validateStatusCode(_ statusCode: Int) throws {
        switch statusCode {
        case 200...299:
            return // Success
        case 401:
            throw APIError.unauthorized
        case 400...499:
            throw APIError.statusCode(statusCode)
        case 500...599:
            throw APIError.serverError("Server error: \(statusCode)")
        default:
            throw APIError.statusCode(statusCode)
        }
    }
}

extension APIService {
    func get<T: Decodable>(_ path: String, parameters: [String: Any]? = nil) async throws -> T {
        let request = Endpoint(method: .get, path: path, queryParameters: parameters)
        return try await self.request(request)
    }
    
    func post<T: Decodable, U: Encodable>(_ path: String, body: U? = nil) async throws -> T {
        let request = Endpoint(method: .post, path: path, body: body)
        return try await self.request(request)
    }
    
    func put<T: Decodable, U: Encodable>(_ path: String, body: U? = nil) async throws -> T {
        let request = Endpoint(method: .put, path: path, body: body)
        return try await self.request(request)
    }
    
    func delete(_ path: String) async throws {
        let request = Endpoint(method: .delete, path: path)
        let _: EmptyResponse = try await self.request(request)
    }
}

struct EmptyResponse: Decodable {}
