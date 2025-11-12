//
//  OnboardingViewModel.swift
//  health-stack
//

import SwiftUI
import Combine
import os.log

@MainActor
class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentStep: OnboardingStep = .welcome
    @Published var isComplete = false
    @Published var errorInfo: ErrorInfo?
    
    // HealthKit Permission
    @Published var isRequestingPermission = false
    @Published var hasGrantedHealthKitPermission = false
    
    // Data Type Selection
    @Published var selectedDataTypes: [HealthDataType: Bool] = [:]
    
    // MARK: - Dependencies
    
    private let configurationManager: ConfigurationManagerProtocol
    private let healthKitManager: HealthKitManager
    private let errorHandler = ErrorHandler.shared
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "health-stack", category: "OnboardingViewModel")
    
    // MARK: - Initialization
    
    init(
        configurationManager: ConfigurationManagerProtocol,
        healthKitManager: HealthKitManager
    ) {
        self.configurationManager = configurationManager
        self.healthKitManager = healthKitManager
        
        // Initialize all data types as enabled by default
        for dataType in HealthDataType.allCases {
            selectedDataTypes[dataType] = true
        }
    }
    
    // MARK: - Navigation
    
    func moveToNextStep() {
        guard let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
            return
        }
        
        withAnimation {
            currentStep = nextStep
        }
    }
    
    func moveToPreviousStep() {
        guard currentStep.rawValue > 0,
              let previousStep = OnboardingStep(rawValue: currentStep.rawValue - 1) else {
            return
        }
        
        withAnimation {
            currentStep = previousStep
        }
    }
    
    // MARK: - HealthKit Permission
    
    func requestHealthKitPermission() {
        isRequestingPermission = true
        errorInfo = nil
        
        logger.info("Requesting HealthKit permissions during onboarding")
        
        Task {
            do {
                // Request authorization for all data types
                let allTypes = Set(HealthDataType.allCases)
                try await healthKitManager.requestAuthorization(for: allTypes)
                
                hasGrantedHealthKitPermission = true
                logger.info("HealthKit permissions granted")
                
                // Move to next step after a brief delay
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                moveToNextStep()
            } catch {
                errorInfo = ErrorInfo.from(error, context: "Onboarding - HealthKit Permission")
            }
            
            isRequestingPermission = false
        }
    }
    
    func skipHealthKitPermission() {
        moveToNextStep()
    }
    
    // MARK: - Data Type Selection
    
    func isCategoryEnabled(_ category: HealthDataCategory) -> Bool {
        let dataTypes = category.dataTypes
        let enabledCount = dataTypes.filter { selectedDataTypes[$0] == true }.count
        return enabledCount == dataTypes.count
    }
    
    func toggleCategory(_ category: HealthDataCategory) {
        let isCurrentlyEnabled = isCategoryEnabled(category)
        let newValue = !isCurrentlyEnabled
        
        for dataType in category.dataTypes {
            selectedDataTypes[dataType] = newValue
        }
    }
    
    func completeOnboarding() {
        // Save data type preferences
        configurationManager.saveDataTypePreferences(selectedDataTypes)
        
        // Set default sync frequency to manual
        configurationManager.saveSyncFrequency(.manual)
        
        // Mark onboarding as complete
        isComplete = true
    }
}
