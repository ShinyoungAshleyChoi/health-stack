//
//  GatewayService.swift
//  health-stack
//

import Foundation
import UIKit
import os.log

class GatewayService: GatewayServiceProtocol {
    private var config: GatewayConfig?
    private let networkClient: NetworkClient
    private let configurationManager: ConfigurationManagerProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "health-stack", category: "GatewayService")
    
    // Retry configuration
    private let maxRetries = 5
    private let initialRetryDelay: TimeInterval = 1.0
    private let maxRetryDelay: TimeInterval = 16.0
    
    // Batch configuration
    private let maxBatchSize = 100
    
    init(networkClient: NetworkClient = NetworkClient(), configurationManager: ConfigurationManagerProtocol) {
        self.networkClient = networkClient
        self.configurationManager = configurationManager
    }
    
    // MARK: - GatewayServiceProtocol
    
    func configure(config: GatewayConfig) throws {
        try config.validate()
        try validateSecureConnectionForConfig(config)
        self.config = config
        logger.info("Gateway service configured with URL: \(config.baseURL)")
    }
    
    func sendHealthData(_ data: [HealthDataSample]) async throws -> SyncResponse {
        guard let config = config else {
            throw GatewayError.invalidConfiguration
        }
        
        try validateSecureConnection()
        
        // Split data into batches
        let batches = data.chunked(into: maxBatchSize)
        var totalSynced = 0
        var totalFailed = 0
        
        for batch in batches {
            do {
                let response = try await sendBatchWithRetry(batch: batch, config: config)
                totalSynced += response.syncedCount
                totalFailed += response.failedCount
            } catch {
                logger.error("Failed to send batch: \(error.localizedDescription)")
                totalFailed += batch.count
                throw error
            }
        }
        
        return SyncResponse(
            success: totalFailed == 0,
            syncedCount: totalSynced,
            failedCount: totalFailed,
            message: totalFailed == 0 ? "All data synced successfully" : "Some data failed to sync"
        )
    }
    
    func testConnection() async throws -> Bool {
        guard let config = config else {
            throw GatewayError.invalidConfiguration
        }
        
        try validateSecureConnection()
        
        let url = buildURL(config: config, path: "/health")
        let headers = buildHeaders(config: config)
        
        do {
            try await networkClient.testConnection(url: url, headers: headers)
            logger.info("Connection test successful")
            return true
        } catch {
            logger.error("Connection test failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func validateSecureConnection() throws {
        guard let config = config else {
            throw GatewayError.invalidConfiguration
        }
        
        try validateSecureConnectionForConfig(config)
    }
    
    // MARK: - Private Methods
    
    private func validateSecureConnectionForConfig(_ config: GatewayConfig) throws {
        guard config.baseURL.lowercased().hasPrefix("https://") else {
            throw GatewayError.insecureConnection
        }
        
        guard let url = URL(string: config.baseURL) else {
            throw GatewayError.invalidConfiguration
        }
        
        guard url.scheme?.lowercased() == "https" else {
            throw GatewayError.insecureConnection
        }
    }
    
    private func sendBatchWithRetry(batch: [HealthDataSample], config: GatewayConfig) async throws -> SyncResponse {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await sendBatch(batch: batch, config: config)
            } catch let error as GatewayError {
                lastError = error
                
                // Don't retry on authentication or configuration errors
                switch error {
                case .authenticationFailed, .invalidConfiguration, .insecureConnection:
                    throw error
                default:
                    break
                }
                
                // Calculate exponential backoff delay
                let delay = min(initialRetryDelay * pow(2.0, Double(attempt)), maxRetryDelay)
                logger.warning("Retry attempt \(attempt + 1)/\(self.maxRetries) after \(delay)s delay")
                
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            } catch {
                lastError = error
                throw error
            }
        }
        
        throw lastError ?? GatewayError.networkError(NSError(domain: "GatewayService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Max retries exceeded"]))
    }
    
    private func sendBatch(batch: [HealthDataSample], config: GatewayConfig) async throws -> SyncResponse {
        let url = buildURL(config: config, path: "/health/data")
        let headers = buildHeaders(config: config)
        
        // Get userId from configuration
        let userId = configurationManager.getUserId() ?? "unknown"
        let payload = HealthDataPayload(userId: userId, samples: batch)
        
        logger.info("Sending batch of \(batch.count) samples to gateway for user: \(userId)")
        
        do {
            let response: SyncResponse = try await networkClient.request(
                url: url,
                method: .post,
                body: payload,
                headers: headers,
                responseType: SyncResponse.self
            )
            
            logger.info("Batch sent successfully: \(response.syncedCount) synced")
            return response
        } catch let error as GatewayError {
            logger.error("Gateway error: \(error.localizedDescription)")
            throw error
        } catch {
            logger.error("Unexpected error: \(error.localizedDescription)")
            throw GatewayError.networkError(error)
        }
    }
    
    private func buildURL(config: GatewayConfig, path: String) -> URL {
        var urlString = config.baseURL
        
        // Remove trailing slash if present
        if urlString.hasSuffix("/") {
            urlString.removeLast()
        }
        
        // Add port if specified
        if let port = config.port {
            if let url = URL(string: urlString), url.port == nil {
                urlString += ":\(port)"
            }
        }
        
        // Add path
        urlString += path
        
        return URL(string: urlString) ?? config.fullURL
    }
    
    private func buildHeaders(config: GatewayConfig) -> [String: String] {
        var headers: [String: String] = [:]
        
        // Add API Key authentication
        if let apiKey = config.apiKey {
            headers["X-API-Key"] = apiKey
        }
        
        // Add Basic authentication
        if let username = config.username, let password = config.password {
            let credentials = "\(username):\(password)"
            if let credentialsData = credentials.data(using: .utf8) {
                let base64Credentials = credentialsData.base64EncodedString()
                headers["Authorization"] = "Basic \(base64Credentials)"
            }
        }
        
        return headers
    }
}
