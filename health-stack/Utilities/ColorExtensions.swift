//
//  ColorExtensions.swift
//  health-stack
//
//  Color extensions for consistent theming and dark mode support
//

import SwiftUI

extension Color {
    // MARK: - Semantic Colors
    
    /// Primary background color that adapts to light/dark mode
    static let primaryBackground = Color(.systemBackground)
    
    /// Secondary background color for cards and elevated surfaces
    static let secondaryBackground = Color(.secondarySystemBackground)
    
    /// Tertiary background color for grouped content
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    
    /// Primary text color that adapts to light/dark mode
    static let primaryText = Color(.label)
    
    /// Secondary text color for less prominent text
    static let secondaryText = Color(.secondaryLabel)
    
    /// Tertiary text color for disabled or placeholder text
    static let tertiaryText = Color(.tertiaryLabel)
    
    // MARK: - Status Colors
    
    /// Success state color (green)
    static let successColor = Color.green
    
    /// Warning state color (orange)
    static let warningColor = Color.orange
    
    /// Error state color (red)
    static let errorColor = Color.red
    
    /// Info state color (blue)
    static let infoColor = Color.blue
    
    // MARK: - Card Shadow
    
    /// Shadow color that adapts to light/dark mode
    static var cardShadow: Color {
        Color.black.opacity(0.1)
    }
    
    // MARK: - Gradient Colors
    
    /// Gradient colors for onboarding background
    static let gradientStart = Color.blue.opacity(0.6)
    static let gradientEnd = Color.purple.opacity(0.6)
}

extension View {
    /// Applies a consistent card style with shadow
    func cardStyle() -> some View {
        self
            .background(Color.secondaryBackground)
            .cornerRadius(12)
            .shadow(color: Color.cardShadow, radius: 5, x: 0, y: 2)
    }
    
    /// Applies a primary button style
    func primaryButtonStyle(isEnabled: Bool = true) -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
    }
    
    /// Applies a secondary button style
    func secondaryButtonStyle() -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.secondaryBackground)
            .foregroundColor(.primaryText)
            .cornerRadius(12)
    }
}
