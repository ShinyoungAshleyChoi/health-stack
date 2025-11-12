//
//  SettingsViewModel.swift
//  health-stack
//

import Foundation
import Combine
import HealthKit
import UIKit
import os.log

@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var selectedSyncFrequency: SyncFrequency = .manual
    @Published var dataTypePreferences: [HealthDataType: Bool] = [:]
    @Published var categoryStates: [HealthDataCategory: Bool] = [:]
    
    @Published var healthKitAuthorizationStatus: String = "Not Determined"
    @Published var errorInfo: ErrorInfo?
    @Published var showSuccess: Bool = false
    @Published var successMessage: String = ""
    
    // MARK: - Dependencies
    
    private let configurationManager: ConfigurationManagerProtocol
    private let healthKitManager: HealthKitManager
    private let errorHandler = ErrorHandler.shared
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "health-stack", category: "SettingsViewModel")
    
    // MARK: - Initialization
    
    init(configurationManager: ConfigurationManagerProtocol, healthKitManager: HealthKitManager) {
        self.configurationManager = configurationManager
        self.healthKitManager = healthKitManager
        
        loadSettings()
        updateCategoryStates()
        updateHealthKitAuthorizationStatus()
    }
    
    // MARK: - Load Settings
    
    func loadSettings() {
        // Load sync frequency
        selectedSyncFrequency = configurationManager.getSyncFrequency()
        
        // Load data type preferences
        dataTypePreferences = configurationManager.getDataTypePreferences()
        
        // Initialize all data types if not set
        for dataType in HealthDataType.allCases {
            if dataTypePreferences[dataType] == nil {
                dataTypePreferences[dataType] = false
            }
        }
        
        updateCategoryStates()
    }
    
    // MARK: - Save Settings
    
    func saveSettings() {
        // Save sync frequency
        configurationManager.saveSyncFrequency(selectedSyncFrequency)
        
        // Save data type preferences
        configurationManager.saveDataTypePreferences(dataTypePreferences)
        
        showSuccessMessage("Settings saved successfully")
    }
    
    // MARK: - Data Type Management
    
    func toggleDataType(_ dataType: HealthDataType) {
        dataTypePreferences[dataType]?.toggle()
        updateCategoryStates()
    }
    
    func toggleCategory(_ category: HealthDataCategory) {
        let newState = !(categoryStates[category] ?? false)
        
        for dataType in category.dataTypes {
            dataTypePreferences[dataType] = newState
        }
        
        updateCategoryStates()
    }
    
    private func updateCategoryStates() {
        for category in HealthDataCategory.allCases {
            let dataTypes = category.dataTypes
            let enabledCount = dataTypes.filter { dataTypePreferences[$0] == true }.count
            
            if enabledCount == 0 {
                categoryStates[category] = false
            } else if enabledCount == dataTypes.count {
                categoryStates[category] = true
            } else {
                // Partial selection - treat as enabled
                categoryStates[category] = true
            }
        }
    }
    
    func getEnabledDataTypesCount(for category: HealthDataCategory) -> Int {
        category.dataTypes.filter { dataTypePreferences[$0] == true }.count
    }
    
    func getTotalDataTypesCount(for category: HealthDataCategory) -> Int {
        category.dataTypes.count
    }
    
    // MARK: - HealthKit Authorization
    
    func updateHealthKitAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthKitAuthorizationStatus = "Not Available"
            return
        }
        
        let enabledTypes = dataTypePreferences.filter { $0.value }.map { $0.key }
        
        if enabledTypes.isEmpty {
            healthKitAuthorizationStatus = "No data types selected"
            return
        }
        
        // Check authorization status for enabled types
        var authorizedCount = 0
        var deniedCount = 0
        var notDeterminedCount = 0
        
        for dataType in enabledTypes {
            let status = getAuthorizationStatus(for: dataType)
            switch status {
            case .sharingAuthorized:
                authorizedCount += 1
            case .sharingDenied:
                deniedCount += 1
            case .notDetermined:
                notDeterminedCount += 1
            @unknown default:
                notDeterminedCount += 1
            }
        }
        
        if authorizedCount == enabledTypes.count {
            healthKitAuthorizationStatus = "Authorized"
        } else if deniedCount > 0 {
            healthKitAuthorizationStatus = "Denied (\(deniedCount) types)"
        } else if notDeterminedCount > 0 {
            healthKitAuthorizationStatus = "Not Determined"
        } else {
            healthKitAuthorizationStatus = "Partial Authorization"
        }
    }
    
    private func getAuthorizationStatus(for type: HealthDataType) -> HKAuthorizationStatus {
        let healthStore = HKHealthStore()
        
        if let quantityTypeId = type.hkQuantityType,
           let quantityType = HKObjectType.quantityType(forIdentifier: quantityTypeId) {
            return healthStore.authorizationStatus(for: quantityType)
        } else if type == .sleepAnalysis,
                  let categoryType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            return healthStore.authorizationStatus(for: categoryType)
        }
        return .notDetermined
    }
    
    func requestHealthKitAuthorization() async {
        let enabledTypes = Set(dataTypePreferences.filter { $0.value }.map { $0.key })
        
        guard !enabledTypes.isEmpty else {
            errorInfo = ErrorInfo(
                title: "No Data Types Selected",
                message: "Please select at least one data type before requesting authorization.",
                recoverySuggestion: "Enable one or more data types in the list below."
            )
            return
        }
        
        logger.info("Requesting HealthKit authorization for \(enabledTypes.count) data types")
        
        do {
            try await healthKitManager.requestAuthorization(for: enabledTypes)
            updateHealthKitAuthorizationStatus()
            showSuccessMessage("HealthKit authorization requested")
            logger.info("HealthKit authorization request completed")
        } catch {
            errorInfo = ErrorInfo.from(error, context: "HealthKit Authorization")
        }
    }
    
    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Error/Success Handling
    
    private func showSuccessMessage(_ message: String) {
        successMessage = message
        showSuccess = true
    }
}
