//
//  health_stackApp.swift
//  health-stack
//
//  Created by shinyoung choi on 11/10/25.
//

import SwiftUI

@main
struct health_stackApp: App {
    // MARK: - Dependencies
    
    private let healthKitManager: HealthKitManagerProtocol
    private let gatewayService: GatewayServiceProtocol
    private let storageManager: StorageManagerProtocol
    private let configurationManager: ConfigurationManagerProtocol
    private let syncManager: SyncManagerProtocol
    
    // MARK: - State
    
    @State private var hasCompletedOnboarding: Bool
    
    init() {
        // Register background tasks BEFORE any other initialization
        // This must be done before application finishes launching
        BackgroundTaskManager.shared.registerBackgroundTasks()
        
        // Initialize managers
        let configManager = ConfigurationManager()
        let storageManager = StorageManager.shared
        let healthKitManager = HealthKitManager()
        let networkClient = NetworkClient()
        let gatewayService = GatewayService(
            networkClient: networkClient,
            configurationManager: configManager
        )
        let syncManager = SyncManager(
            healthKitManager: healthKitManager,
            gatewayService: gatewayService,
            storageManager: storageManager,
            configurationManager: configManager
        )
        
        self.configurationManager = configManager
        self.storageManager = storageManager
        self.healthKitManager = healthKitManager
        self.gatewayService = gatewayService
        self.syncManager = syncManager
        
        // Check if onboarding has been completed
        let completed = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        _hasCompletedOnboarding = State(initialValue: completed)
    }
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainView(
                    viewModel: MainViewModel(
                        syncManager: syncManager,
                        configurationManager: configurationManager
                    ),
                    configurationManager: configurationManager,
                    healthKitManager: healthKitManager as! HealthKitManager,
                    gatewayService: gatewayService,
                    storageManager: storageManager,
                    syncManager: syncManager
                )
            } else {
                OnboardingView(
                    isOnboardingComplete: $hasCompletedOnboarding,
                    configurationManager: configurationManager,
                    healthKitManager: healthKitManager as! HealthKitManager
                )
            }
        }
    }
}
