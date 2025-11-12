//
//  LoadingStateView.swift
//  health-stack
//
//  Reusable loading state views for consistent UI
//

import SwiftUI

/// A view that displays a loading indicator with an optional message
struct LoadingStateView: View {
    let message: String
    
    init(message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .accessibilityLabel("Loading")
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading: \(message)")
    }
}

/// A view that displays an empty state with icon and message
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondaryText)
                .accessibilityHidden(true)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primaryText)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

/// A view that displays an error state with retry option
struct ErrorStateView: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?
    
    init(title: String, message: String, retryAction: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.errorColor)
                .accessibilityHidden(true)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if let retryAction = retryAction {
                Button(action: {
                    HapticFeedback.medium.generate()
                    retryAction()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Retry")
                    }
                    .primaryButtonStyle()
                }
                .padding(.horizontal, 32)
                .accessibilityLabel("Retry")
                .accessibilityHint("Attempts to reload the content")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Preview

#Preview("Loading State") {
    LoadingStateView(message: "Loading sync history...")
}

#Preview("Empty State") {
    EmptyStateView(
        icon: "clock.arrow.circlepath",
        title: "No Sync History",
        message: "Sync history will appear here after your first sync"
    )
}

#Preview("Error State") {
    ErrorStateView(
        title: "Failed to Load",
        message: "Unable to load sync history. Please check your connection and try again.",
        retryAction: { print("Retry tapped") }
    )
}
