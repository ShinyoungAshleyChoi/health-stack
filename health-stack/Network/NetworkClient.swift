//
//  NetworkClient.swift
//  health-stack
//

import Foundation

class NetworkClient: NSObject {
    private var session: URLSession!
    private let timeout: TimeInterval = 30.0
    
    override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        configuration.waitsForConnectivity = true
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    // MARK: - Public Methods
    
    func request<T: Encodable, R: Decodable>(
        url: URL,
        method: HTTPMethod,
        body: T?,
        headers: [String: String]?,
        responseType: R.Type
    ) async throws -> R {
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeout
        
        // Add headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Add body
        if let body = body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(body)
        }
        
        // Execute request
        let (data, response) = try await session.data(for: request)
        
        // Validate response
        try validateResponse(response: response, data: data)
        
        // Decode response
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(R.self, from: data)
    }
    
    func requestWithoutResponse<T: Encodable>(
        url: URL,
        method: HTTPMethod,
        body: T?,
        headers: [String: String]?
    ) async throws {
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeout
        
        // Add headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Add body
        if let body = body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(body)
        }
        
        // Execute request
        let (data, response) = try await session.data(for: request)
        
        // Validate response
        try validateResponse(response: response, data: data)
    }
    
    func testConnection(url: URL, headers: [String: String]?) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        request.timeoutInterval = timeout
        
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GatewayError.networkError(NSError(domain: "NetworkClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw GatewayError.serverError(statusCode: httpResponse.statusCode, message: "Connection test failed")
        }
    }
    
    // MARK: - Private Methods
    
    private func validateResponse(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GatewayError.networkError(NSError(domain: "NetworkClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401, 403:
            throw GatewayError.authenticationFailed
        case 408:
            throw GatewayError.timeout
        default:
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GatewayError.serverError(statusCode: httpResponse.statusCode, message: message)
        }
    }
}

// MARK: - URLSessionDelegate

extension NetworkClient: URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // SSL Certificate Validation
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Perform certificate pinning validation if enabled
        let domain = challenge.protectionSpace.host
        if SecurityValidator.shared.isCertificatePinningEnabled {
            let isPinned = SecurityValidator.shared.validatePinnedCertificate(
                serverTrust: serverTrust,
                domain: domain
            )
            
            if !isPinned {
                // Certificate pinning failed
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }
        }
        
        // Perform default SSL validation
        let credential = URLCredential(trust: serverTrust)
        completionHandler(.useCredential, credential)
    }
}

// MARK: - Supporting Types

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}
