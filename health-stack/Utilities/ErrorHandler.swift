//
//  ErrorHandler.swift
//  health-stack
//

import Foundation
import os.log

/// Centralized error handling and logging utility
class ErrorHandler {
    static let shared = ErrorHandler()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "health-stack", category: "ErrorHandler")
    
    private init() {}
    
    // MARK: - Error Logging
    
    func log(_ error: Error, context: String = "", level: OSLogType = .error) {
        let errorMessage = formatErrorMessage(error, context: context)
        
        switch level {
        case .debug:
            logger.debug("\(errorMessage)")
        case .info:
            logger.info("\(errorMessage)")
        case .error:
            logger.error("\(errorMessage)")
        case .fault:
            logger.fault("\(errorMessage)")
        default:
            logger.log("\(errorMessage)")
        }
    }
    
    func logInfo(_ message: String) {
        logger.info("\(message)")
    }
    
    func logDebug(_ message: String) {
        logger.debug("\(message)")
    }
    
    // MARK: - User-Friendly Error Messages
    
    func getUserFriendlyMessage(for error: Error) -> String {
        if let healthKitError = error as? HealthKitError {
            return getUserFriendlyMessage(for: healthKitError)
        } else if let gatewayError = error as? GatewayError {
            return getUserFriendlyMessage(for: gatewayError)
        } else if let storageError = error as? StorageError {
            return getUserFriendlyMessage(for: storageError)
        } else if let urlError = error as? URLError {
            return getUserFriendlyMessage(for: urlError)
        } else {
            return error.localizedDescription
        }
    }
    
    private func getUserFriendlyMessage(for error: HealthKitError) -> String {
        switch error {
        case .notAvailable:
            return "HealthKit is not available on this device. This app requires HealthKit to function."
        case .authorizationDenied:
            return "Access to health data was denied. Please enable permissions in Settings to use this app."
        case .dataNotAvailable:
            return "The requested health data is not available. This may be because no data has been recorded yet."
        case .queryFailed(let underlyingError):
            return "Failed to retrieve health data: \(underlyingError.localizedDescription)"
        }
    }
    
    private func getUserFriendlyMessage(for error: GatewayError) -> String {
        switch error {
        case .invalidConfiguration:
            return "Gateway configuration is invalid. Please check your settings and try again."
        case .insecureConnection:
            return "Only secure HTTPS connections are allowed. Please update your gateway URL to use HTTPS."
        case .networkError(let underlyingError):
            return "Network error: \(underlyingError.localizedDescription). Please check your internet connection."
        case .authenticationFailed:
            return "Authentication failed. Please verify your credentials in Settings."
        case .serverError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message). Please contact your system administrator."
        case .timeout:
            return "The request timed out. Please check your internet connection and try again."
        case .sslValidationFailed:
            return "SSL certificate validation failed. The server's security certificate could not be verified."
        }
    }
    
    private func getUserFriendlyMessage(for error: StorageError) -> String {
        switch error {
        case .saveFailed(let underlyingError):
            return "Failed to save data: \(underlyingError.localizedDescription). Your device may be low on storage."
        case .fetchFailed(let underlyingError):
            return "Failed to retrieve data: \(underlyingError.localizedDescription)"
        case .encryptionFailed:
            return "Failed to encrypt data. This may indicate a security issue with your device."
        }
    }
    
    private func getUserFriendlyMessage(for error: URLError) -> String {
        switch error.code {
        case .notConnectedToInternet:
            return "No internet connection. Please check your network settings and try again."
        case .timedOut:
            return "The request timed out. Please try again."
        case .cannotFindHost:
            return "Cannot reach the server. Please check the gateway URL in Settings."
        case .cannotConnectToHost:
            return "Cannot connect to the server. The server may be down or unreachable."
        case .networkConnectionLost:
            return "Network connection was lost. Please try again."
        case .dnsLookupFailed:
            return "DNS lookup failed. Please check the gateway URL in Settings."
        case .badServerResponse:
            return "Received an invalid response from the server."
        case .userAuthenticationRequired:
            return "Authentication is required. Please check your credentials in Settings."
        case .secureConnectionFailed:
            return "Secure connection failed. The server's security certificate may be invalid."
        default:
            return "Network error: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Error Recovery Suggestions
    
    func getRecoverySuggestion(for error: Error) -> String? {
        if let healthKitError = error as? HealthKitError {
            return getRecoverySuggestion(for: healthKitError)
        } else if let gatewayError = error as? GatewayError {
            return getRecoverySuggestion(for: gatewayError)
        } else if let storageError = error as? StorageError {
            return getRecoverySuggestion(for: storageError)
        } else if let urlError = error as? URLError {
            return getRecoverySuggestion(for: urlError)
        }
        return nil
    }
    
    private func getRecoverySuggestion(for error: HealthKitError) -> String? {
        switch error {
        case .notAvailable:
            return nil
        case .authorizationDenied:
            return "Go to Settings > Privacy & Security > Health to grant permissions."
        case .dataNotAvailable:
            return "Try syncing again later when more health data is available."
        case .queryFailed:
            return "Try restarting the app or your device."
        }
    }
    
    private func getRecoverySuggestion(for error: GatewayError) -> String? {
        switch error {
        case .invalidConfiguration:
            return "Go to Settings to configure your gateway."
        case .insecureConnection:
            return "Update your gateway URL to start with 'https://'."
        case .networkError:
            return "Check your internet connection and try again."
        case .authenticationFailed:
            return "Verify your API key or username/password in Settings."
        case .serverError:
            return "Contact your system administrator for assistance."
        case .timeout:
            return "Try again with a better internet connection."
        case .sslValidationFailed:
            return "Contact your system administrator to verify the server certificate."
        }
    }
    
    private func getRecoverySuggestion(for error: StorageError) -> String? {
        switch error {
        case .saveFailed:
            return "Free up storage space on your device and try again."
        case .fetchFailed:
            return "Try restarting the app."
        case .encryptionFailed:
            return "Restart your device and try again."
        }
    }
    
    private func getRecoverySuggestion(for error: URLError) -> String? {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return "Connect to Wi-Fi or cellular data and try again."
        case .timedOut:
            return "Try again with a better internet connection."
        case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return "Verify the gateway URL in Settings."
        case .userAuthenticationRequired:
            return "Check your credentials in Settings."
        case .secureConnectionFailed:
            return "Contact your system administrator."
        default:
            return "Try again later."
        }
    }
    
    // MARK: - Retry Capability
    
    func shouldRetry(error: Error) -> Bool {
        if let gatewayError = error as? GatewayError {
            switch gatewayError {
            case .networkError, .timeout:
                return true
            case .serverError(let statusCode, _):
                // Retry on 5xx errors (server errors) but not 4xx (client errors)
                return statusCode >= 500
            default:
                return false
            }
        } else if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .timedOut, .networkConnectionLost, .cannotConnectToHost:
                return true
            default:
                return false
            }
        } else if error is StorageError {
            return false
        }
        return false
    }
    
    // MARK: - Private Helpers
    
    private func formatErrorMessage(_ error: Error, context: String) -> String {
        var message = ""
        
        if !context.isEmpty {
            message += "[\(context)] "
        }
        
        message += "\(type(of: error)): \(error.localizedDescription)"
        
        return message
    }
}
