//
//  BackgroundExecutionTester.swift
//  health-stack
//
//  Utility for testing background execution functionality
//

import Foundation
import BackgroundTasks
import os.log

#if DEBUG
/// Utility class for testing background execution during development
class BackgroundExecutionTester {
    private let logger = Logger(subsystem: "com.healthstack", category: "BackgroundExecutionTester")
    
    /// Simulate a background task launch
    /// Call this from the debugger console or a debug menu
    static func simulateBackgroundTaskLaunch() {
        let identifier = BackgroundTaskManager.healthSyncTaskIdentifier
        
        // This can only be called from the debugger
        // In LLDB console, run:
        // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.healthstack.sync"]
        
        print("To simulate background task launch, run this in LLDB console:")
        print("e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@\"\(identifier)\"]")
    }
    
    /// Check if background tasks are properly configured
    static func verifyBackgroundConfiguration() -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        // Check if background modes are enabled
        if let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] {
            results["Background Fetch Enabled"] = backgroundModes.contains("fetch")
            results["Background Processing Enabled"] = backgroundModes.contains("processing")
        } else {
            results["Background Modes Configured"] = false
        }
        
        // Check if task identifier is registered
        if let permittedIdentifiers = Bundle.main.object(forInfoDictionaryKey: "BGTaskSchedulerPermittedIdentifiers") as? [String] {
            results["Task Identifier Registered"] = permittedIdentifiers.contains(BackgroundTaskManager.healthSyncTaskIdentifier)
        } else {
            results["BGTaskScheduler Configured"] = false
        }
        
        // Check HealthKit capability
        if let healthKitEnabled = Bundle.main.object(forInfoDictionaryKey: "NSHealthShareUsageDescription") as? String {
            results["HealthKit Configured"] = !healthKitEnabled.isEmpty
        } else {
            results["HealthKit Configured"] = false
        }
        
        return results
    }
    
    /// Print background configuration status
    static func printConfigurationStatus() {
        let results = verifyBackgroundConfiguration()
        
        print("\n=== Background Execution Configuration ===")
        for (key, value) in results.sorted(by: { $0.key < $1.key }) {
            let status = value ? "✅" : "❌"
            print("\(status) \(key)")
        }
        print("==========================================\n")
        
        // Print instructions if any checks failed
        if results.values.contains(false) {
            print("⚠️  Some configuration items are missing.")
            print("Please refer to BACKGROUND_EXECUTION_SETUP.md for setup instructions.\n")
        }
    }
    
    /// Log current background task status
    static func logBackgroundTaskStatus(syncManager: SyncManagerProtocol, configManager: ConfigurationManagerProtocol) {
        let frequency = configManager.getSyncFrequency()
        let syncStatus = syncManager.getSyncStatus()
        
        print("\n=== Background Task Status ===")
        print("Sync Frequency: \(frequency.displayName)")
        print("Current Status: \(syncStatus)")
        
        if let interval = frequency.interval {
            print("Next sync scheduled in: ~\(Int(interval))s")
        } else {
            print("No automatic sync scheduled")
        }
        print("==============================\n")
    }
}
#endif
