//
//  ErrorAlertModifier.swift
//  health-stack
//

import SwiftUI

/// View modifier for displaying error alerts with retry capability
struct ErrorAlertModifier: ViewModifier {
    @Binding var error: ErrorInfo?
    let onRetry: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert(error?.title ?? "Error", isPresented: .constant(error != nil)) {
                Button("OK", role: .cancel) {
                    error = nil
                }
                
                if let error = error, error.isRetryable, let onRetry = onRetry {
                    Button("Retry") {
                        self.error = nil
                        onRetry()
                    }
                }
                
                if let error = error, error.showSettings {
                    Button("Open Settings") {
                        self.error = nil
                        openSettings()
                    }
                }
            } message: {
                if let error = error {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(error.message)
                        
                        if let suggestion = error.recoverySuggestion {
                            Text("\n\(suggestion)")
                                .font(.caption)
                        }
                    }
                }
            }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

extension View {
    func errorAlert(error: Binding<ErrorInfo?>, onRetry: (() -> Void)? = nil) -> some View {
        modifier(ErrorAlertModifier(error: error, onRetry: onRetry))
    }
}

/// Structured error information for display
struct ErrorInfo: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let recoverySuggestion: String?
    let isRetryable: Bool
    let showSettings: Bool
    let underlyingError: Error?
    
    init(
        title: String = "Error",
        message: String,
        recoverySuggestion: String? = nil,
        isRetryable: Bool = false,
        showSettings: Bool = false,
        underlyingError: Error? = nil
    ) {
        self.title = title
        self.message = message
        self.recoverySuggestion = recoverySuggestion
        self.isRetryable = isRetryable
        self.showSettings = showSettings
        self.underlyingError = underlyingError
    }
    
    /// Create ErrorInfo from an Error
    static func from(_ error: Error, context: String = "") -> ErrorInfo {
        let errorHandler = ErrorHandler.shared
        
        // Log the error
        errorHandler.log(error, context: context)
        
        // Get user-friendly message
        let message = errorHandler.getUserFriendlyMessage(for: error)
        let suggestion = errorHandler.getRecoverySuggestion(for: error)
        let isRetryable = errorHandler.shouldRetry(error: error)
        
        // Determine if we should show settings button
        let showSettings: Bool
        if let healthKitError = error as? HealthKitError {
            switch healthKitError {
            case .authorizationDenied:
                showSettings = true
            default:
                showSettings = false
            }
        } else if let gatewayError = error as? GatewayError {
            switch gatewayError {
            case .authenticationFailed, .invalidConfiguration:
                showSettings = true
            default:
                showSettings = false
            }
        } else {
            showSettings = false
        }
        
        return ErrorInfo(
            message: message,
            recoverySuggestion: suggestion,
            isRetryable: isRetryable,
            showSettings: showSettings,
            underlyingError: error
        )
    }
}
