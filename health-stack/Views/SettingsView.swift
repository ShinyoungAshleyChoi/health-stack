//
//  SettingsView.swift
//  health-stack
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Dependencies for integration tests
    let healthKitManager: HealthKitManager
    let gatewayService: GatewayServiceProtocol
    let storageManager: StorageManagerProtocol
    let syncManager: SyncManagerProtocol
    let configurationManager: ConfigurationManagerProtocol
    
    init(
        configurationManager: ConfigurationManagerProtocol,
        healthKitManager: HealthKitManager,
        gatewayService: GatewayServiceProtocol,
        storageManager: StorageManagerProtocol,
        syncManager: SyncManagerProtocol
    ) {
        self.configurationManager = configurationManager
        self.healthKitManager = healthKitManager
        self.gatewayService = gatewayService
        self.storageManager = storageManager
        self.syncManager = syncManager
        
        _viewModel = StateObject(wrappedValue: SettingsViewModel(
            configurationManager: configurationManager,
            healthKitManager: healthKitManager
        ))
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Sync Frequency Section
                syncFrequencySection
                
                // Data Type Selection Section
                dataTypeSelectionSection
                
                // HealthKit Permissions Section
                healthKitPermissionsSection
                
                // Developer Tools Section
                developerToolsSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        HapticFeedback.light.generate()
                        dismiss()
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.SettingsView.cancelButton)
                    .accessibilityHint("Closes settings without saving changes")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        HapticFeedback.success.generate()
                        viewModel.saveSettings()
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.SettingsView.saveButton)
                    .accessibilityHint("Saves settings and closes")
                }
            }
            .errorAlert(error: $viewModel.errorInfo) {
                Task {
                    await viewModel.requestHealthKitAuthorization()
                }
            }
            .alert("Success", isPresented: $viewModel.showSuccess) {
                Button("OK", role: .cancel) {
                    HapticFeedback.success.generate()
                    dismiss()
                }
            } message: {
                Text(viewModel.successMessage)
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Sync Frequency Section
    
    private var syncFrequencySection: some View {
        Section {
            Picker("Sync Frequency", selection: $viewModel.selectedSyncFrequency) {
                ForEach(SyncFrequency.allCases, id: \.self) { frequency in
                    Text(frequency.displayName).tag(frequency)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier(AccessibilityIdentifiers.SettingsView.syncFrequencyPicker)
            .accessibilityLabel("Sync frequency")
            .accessibilityValue(viewModel.selectedSyncFrequency.displayName)
            .accessibilityHint("Select how often to sync health data")
            .onChange(of: viewModel.selectedSyncFrequency) { _ in
                HapticFeedback.selection.generate()
            }
        } header: {
            Text("Sync Frequency")
        } footer: {
            Text(syncFrequencyDescription)
                .accessibilityLabel("Sync frequency description: \(syncFrequencyDescription)")
        }
    }
    
    private var syncFrequencyDescription: String {
        switch viewModel.selectedSyncFrequency {
        case .realtime:
            return "Data will sync immediately when new health data is available."
        case .hourly:
            return "Data will sync automatically every hour."
        case .daily:
            return "Data will sync automatically once per day."
        case .manual:
            return "Data will only sync when you manually trigger it."
        }
    }
    
    // MARK: - Data Type Selection Section
    
    private var dataTypeSelectionSection: some View {
        Section {
            ForEach(HealthDataCategory.allCases, id: \.self) { category in
                DisclosureGroup {
                    ForEach(category.dataTypes, id: \.self) { dataType in
                        Toggle(dataType.rawValue.capitalized, isOn: Binding(
                            get: { viewModel.dataTypePreferences[dataType] ?? false },
                            set: { _ in
                                HapticFeedback.selection.generate()
                                viewModel.toggleDataType(dataType)
                            }
                        ))
                        .accessibilityIdentifier("\(AccessibilityIdentifiers.SettingsView.dataTypeToggle)_\(dataType.rawValue)")
                        .accessibilityLabel("\(dataType.rawValue.capitalized) data type")
                        .accessibilityValue(viewModel.dataTypePreferences[dataType] ?? false ? "enabled" : "disabled")
                    }
                } label: {
                    HStack {
                        Toggle(category.displayName, isOn: Binding(
                            get: { viewModel.categoryStates[category] ?? false },
                            set: { _ in
                                HapticFeedback.selection.generate()
                                viewModel.toggleCategory(category)
                            }
                        ))
                        .accessibilityIdentifier("\(AccessibilityIdentifiers.SettingsView.categoryToggle)_\(category.rawValue)")
                        .accessibilityLabel("\(category.displayName) category")
                        .accessibilityValue(viewModel.categoryStates[category] ?? false ? "enabled" : "disabled")
                        .accessibilityHint("Toggles all data types in this category")
                        
                        Spacer()
                        
                        Text("\(viewModel.getEnabledDataTypesCount(for: category))/\(viewModel.getTotalDataTypesCount(for: category))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityLabel("\(viewModel.getEnabledDataTypesCount(for: category)) of \(viewModel.getTotalDataTypesCount(for: category)) enabled")
                    }
                }
            }
        } header: {
            Text("Data Types")
        } footer: {
            Text("Select which health data types to sync. Toggle categories to enable/disable all types within that category.")
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.SettingsView.dataTypeSection)
    }
    
    // MARK: - HealthKit Permissions Section
    
    private var healthKitPermissionsSection: some View {
        Section {
            HStack {
                Text("Authorization Status")
                Spacer()
                Text(viewModel.healthKitAuthorizationStatus)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Authorization status: \(viewModel.healthKitAuthorizationStatus)")
            .accessibilityIdentifier(AccessibilityIdentifiers.SettingsView.healthKitAuthStatus)
            
            Button("Request HealthKit Authorization") {
                HapticFeedback.medium.generate()
                Task {
                    await viewModel.requestHealthKitAuthorization()
                }
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.SettingsView.requestAuthButton)
            .accessibilityHint("Requests permission to access HealthKit data")
            
            Button("Open iOS Settings") {
                HapticFeedback.light.generate()
                viewModel.openAppSettings()
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.SettingsView.openSettingsButton)
            .accessibilityHint("Opens iOS Settings app to manage app permissions")
        } header: {
            Text("HealthKit Permissions")
        } footer: {
            Text("To grant HealthKit permissions, use 'Open iOS Settings' button and enable the required health data types in Settings > Health > Data Access & Devices.")
        }
    }
    
    // MARK: - Developer Tools Section
    
    private var developerToolsSection: some View {
        Section {
            NavigationLink(destination: IntegrationTestView(
                healthKitManager: healthKitManager,
                gatewayService: gatewayService,
                storageManager: storageManager,
                syncManager: syncManager,
                configManager: configurationManager
            )) {
                HStack {
                    Image(systemName: "checkmark.circle.badge.xmark")
                        .foregroundColor(.blue)
                    Text("Run Integration Tests")
                }
            }
            .accessibilityIdentifier("runIntegrationTestsButton")
            .accessibilityHint("Opens integration test suite")
        } header: {
            Text("Developer Tools")
        } footer: {
            Text("Run comprehensive integration tests to verify all functionality. Tests include HealthKit extraction, sync flow, security, and error handling.")
        }
    }
}

// MARK: - Preview

#Preview {
    let configManager = ConfigurationManager()
    let healthKitManager = HealthKitManager()
    let networkClient = NetworkClient()
    let gatewayService = GatewayService(networkClient: networkClient, configurationManager: configManager)
    let storageManager = StorageManager.shared
    let syncManager = SyncManager(
        healthKitManager: healthKitManager,
        gatewayService: gatewayService,
        storageManager: storageManager,
        configurationManager: configManager
    )
    
    SettingsView(
        configurationManager: configManager,
        healthKitManager: healthKitManager,
        gatewayService: gatewayService,
        storageManager: storageManager,
        syncManager: syncManager
    )
}
