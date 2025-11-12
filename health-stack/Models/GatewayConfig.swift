//
//  GatewayConfig.swift
//  health-stack
//

import Foundation

struct GatewayConfig: Codable {
    let baseURL: String
    let port: Int?
    let apiKey: String?
    let username: String?
    let password: String?
    
    var fullURL: URL {
        var urlString = baseURL
        if let port = port {
            urlString += ":\(port)"
        }
        return URL(string: urlString) ?? URL(string: "http://192.168.45.185")!
    }
    
    func validate() throws {
        // Validate URL format only (allow both HTTP and HTTPS)
        guard URL(string: baseURL) != nil else {
            throw GatewayError.invalidConfiguration
        }
        
        // Ensure URL has a scheme
        guard baseURL.lowercased().hasPrefix("http://") || baseURL.lowercased().hasPrefix("https://") else {
            throw GatewayError.invalidConfiguration
        }
    }
    
    init(baseURL: String, port: Int? = nil, apiKey: String? = nil, username: String? = nil, password: String? = nil) {
        self.baseURL = baseURL
        self.port = port
        self.apiKey = apiKey
        self.username = username
        self.password = password
    }
}
