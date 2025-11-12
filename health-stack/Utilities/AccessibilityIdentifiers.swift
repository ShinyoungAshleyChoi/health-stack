//
//  AccessibilityIdentifiers.swift
//  health-stack
//
//  Centralized accessibility identifiers for UI testing and VoiceOver support
//

import Foundation

enum AccessibilityIdentifiers {
    // MARK: - Main View
    enum MainView {
        static let syncStatusCard = "main_sync_status_card"
        static let syncStatusIndicator = "main_sync_status_indicator"
        static let syncStatusText = "main_sync_status_text"
        static let lastSyncCard = "main_last_sync_card"
        static let lastSyncText = "main_last_sync_text"
        static let dataTypeSummaryCard = "main_data_type_summary_card"
        static let dataTypeSummaryText = "main_data_type_summary_text"
        static let syncButton = "main_sync_button"
        static let settingsButton = "main_settings_button"
        static let historyButton = "main_history_button"
        static let networkWarningBanner = "main_network_warning_banner"
    }
    
    // MARK: - Settings View
    enum SettingsView {
        static let syncFrequencyPicker = "settings_sync_frequency_picker"
        static let dataTypeSection = "settings_data_type_section"
        static let categoryToggle = "settings_category_toggle"
        static let dataTypeToggle = "settings_data_type_toggle"
        static let healthKitAuthStatus = "settings_healthkit_auth_status"
        static let requestAuthButton = "settings_request_auth_button"
        static let openSettingsButton = "settings_open_settings_button"
        static let saveButton = "settings_save_button"
        static let cancelButton = "settings_cancel_button"
    }
    
    // MARK: - Onboarding View
    enum OnboardingView {
        static let welcomeScreen = "onboarding_welcome_screen"
        static let getStartedButton = "onboarding_get_started_button"
        static let permissionScreen = "onboarding_permission_screen"
        static let grantPermissionButton = "onboarding_grant_permission_button"
        static let skipButton = "onboarding_skip_button"
        static let dataTypeScreen = "onboarding_data_type_screen"
        static let categoryCard = "onboarding_category_card"
        static let finishButton = "onboarding_finish_button"
        static let pageIndicator = "onboarding_page_indicator"
    }
    
    // MARK: - Sync History View
    enum SyncHistoryView {
        static let historyList = "sync_history_list"
        static let recordRow = "sync_history_record_row"
        static let statusIcon = "sync_history_status_icon"
        static let emptyState = "sync_history_empty_state"
    }
}
