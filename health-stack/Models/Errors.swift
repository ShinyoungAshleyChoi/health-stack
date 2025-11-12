//
//  Errors.swift
//  health-stack
//

import Foundation

enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case authorizationDenied
    case dataNotAvailable
    case queryFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .authorizationDenied:
            return "HealthKit authorization was denied. Please enable permissions in Settings."
        case .dataNotAvailable:
            return "The requested health data is not available"
        case .queryFailed(let error):
            return "Failed to query health data: \(error.localizedDescription)"
        }
    }
}

enum GatewayError: Error, LocalizedError {
    case invalidConfiguration
    case insecureConnection
    case networkError(Error)
    case authenticationFailed
    case serverError(statusCode: Int, message: String)
    case timeout
    case sslValidationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Gateway configuration is invalid"
        case .insecureConnection:
            return "Only HTTPS connections are allowed. Please use a secure URL."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .authenticationFailed:
            return "Authentication failed. Please check your credentials."
        case .serverError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message)"
        case .timeout:
            return "Request timed out. Please check your connection."
        case .sslValidationFailed:
            return "SSL certificate validation failed"
        }
    }
}

enum StorageError: Error, LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case encryptionFailed
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .encryptionFailed:
            return "Data encryption failed"
        }
    }
}
