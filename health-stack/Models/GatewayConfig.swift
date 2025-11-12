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
        return URL(string: urlString) ?? URL(string: "https://192.168.45.185")!
    }
    
    func validate() throws {
        guard baseURL.lowercased().hasPrefix("https://") else {
            throw GatewayError.insecureConnection
        }
        
        guard URL(string: baseURL) != nil else {
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
