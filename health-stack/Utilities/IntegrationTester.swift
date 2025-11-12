//
//  IntegrationTester.swift
//  health-stack
//
//  Integration testing utility for final validation
//

import Foundation
import HealthKit
import SwiftUI
import Combine

@MainActor
final class IntegrationTester: ObservableObject {
    @Published var testResults: [TestResult] = []
    @Published var isRunning = false
    @Published var currentTest: String = ""
    
    private let healthKitManager: HealthKitManagerProtocol
    private let gatewayService: GatewayServiceProtocol
    private let storageManager: StorageManagerProtocol
    private let syncManager: SyncManagerProtocol
    private let configManager: ConfigurationManagerProtocol
    
    init(
        healthKitManager: HealthKitManagerProtocol,
        gatewayService: GatewayServiceProtocol,
        storageManager: StorageManagerProtocol,
        syncManager: SyncManagerProtocol,
        configManager: ConfigurationManagerProtocol
    ) {
        self.healthKitManager = healthKitManager
        self.gatewayService = gatewayService
        self.storageManager = storageManager
        self.syncManager = syncManager
        self.configManager = configManager
    }
    
    struct TestResult: Identifiable {
        let id = UUID()
        let name: String
        let category: TestCategory
        let status: TestStatus
        let message: String
        let timestamp: Date
        let duration: TimeInterval
        
        enum TestCategory: String {
            case healthKit = "HealthKit"
            case sync = "Sync Flow"
            case network = "Network"
            case storage = "Storage"
            case security = "Security"
            case permissions = "Permissions"
            case background = "Background"
            case errorHandling = "Error Handling"
        }
        
        enum TestStatus {
            case passed
            case failed
            case warning
            case skipped
            
            var icon: String {
                switch self {
                case .passed: return "✅"
                case .failed: return "❌"
                case .warning: return "⚠️"
                case .skipped: return "⏭️"
                }
            }
        }
    }
    
    // MARK: - Run All Tests
    
    func runAllTests() async {
        isRunning = true
        testResults.removeAll()
        
        await testHealthKitDataExtraction()
        await testStoragePersistence()
        await testHTTPSEnforcement()
        await testSyncFlow()
        await testErrorScenarios()
        await testPermissionFlows()
        await testDataRecovery()
        
        isRunning = false
        currentTest = "All tests completed"
    }
    
    // MARK: - HealthKit Tests
    
    func testHealthKitDataExtraction() async {
        currentTest = "Testing HealthKit data extraction..."
        
        // Test 1: Authorization status
        let authResult = await testHealthKitAuthorization()
        testResults.append(authResult)
        
        // Test 2: Data type extraction
        for dataType in [HealthDataType.stepCount, .heartRate, .sleepAnalysis] {
            let result = await testDataTypeExtraction(dataType)
            testResults.append(result)
        }
        
        // Test 3: Date range queries
        let dateRangeResult = await testDateRangeQuery()
        testResults.append(dateRangeResult)
    }
    
    private func testHealthKitAuthorization() async -> TestResult {
        let start = Date()
        
        do {
            // Clear authorization cache before testing
            if let healthKitManager = healthKitManager as? HealthKitManager {
                healthKitManager.clearAuthorizationCache()
            }
            
            let types: Set<HealthDataType> = [.stepCount, .heartRate]
            try await healthKitManager.requestAuthorization(for: types)
            
            // Wait a bit for authorization to settle
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Clear cache again to force fresh check
            if let healthKitManager = healthKitManager as? HealthKitManager {
                healthKitManager.clearAuthorizationCache()
            }
            
            return TestResult(
                name: "HealthKit Authorization",
                category: .healthKit,
                status: .passed,
                message: "Successfully requested authorization",
                timestamp: Date(),
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            return TestResult(
                name: "HealthKit Authorization",
                category: .healthKit,
                status: .failed,
                message: "Failed: \(error.localizedDescription)",
                timestamp: Date(),
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testDataTypeExtraction(_ dataType: HealthDataType) async -> TestResult {
        let start = Date()
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
        
        do {
            // Clear authorization cache before fetching
            if let healthKitManager = healthKitManager as? HealthKitManager {
                healthKitManager.clearAuthorizationCache()
            }
            
            let samples = try await healthKitManager.fetchHealthData(
                type: dataType,
                from: startDate,
                to: endDate
            )
            
            return TestResult(
                name: "Extract \(dataType.rawValue)",
                category: .healthKit,
                status: .passed,
                message: "Retrieved \(samples.count) samples",
                timestamp: Date(),
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            return TestResult(
                name: "Extract \(dataType.rawValue)",
                category: .healthKit,
                status: .warning,
                message: "No data or error: \(error.localizedDescription)",
                timestamp: Date(),
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testDateRangeQuery() async -> TestResult {
        let start = Date()
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -24, to: endDate)!
        
        do {
            let samples = try await healthKitManager.fetchHealthData(
                type: .stepCount,
                from: startDate,
                to: endDate
            )
            
            let allInRange = samples.allSatisfy { sample in
                sample.startDate >= startDate && sample.endDate <= endDate
            }
            
            return TestResult(
                name: "Date Range Query",
                category: .healthKit,
                status: allInRange ? .passed : .failed,
                message: allInRange ? "All samples within range" : "Some samples outside range",
                timestamp: Date(),
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            return TestResult(
                name: "Date Range Query",
                category: .healthKit,
                status: .failed,
                message: "Query failed: \(error.localizedDescription)",
                timestamp: Date(),
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    // MARK: - Storage Tests
    
    func testStoragePersistence() async {
        currentTest = "Testing storage persistence..."
        
        let result = await testSaveAndRetrieve()
        testResults.append(result)
        
        let cleanupResult = await testDataCleanup()
        testResults.append(cleanupResult)
    }
    
    private func testSaveAndRetrieve() async -> TestResult {
        let start = Date()
        
        do {
            // Create test sample
            let testSample = HealthDataSample(
                id: UUID(),
                type: .stepCount,
                value: 1000,
                unit: "count",
                startDate: Date(),
                endDate: Date(),
                sourceBundle: "test",
                metadata: nil,
                isSynced: false,
                createdAt: Date()
            )
            
            // Save
            try await storageManager.saveHealthData([testSample], userId: "test-user")
            
            // Retrieve
            let unsynced = try await storageManager.fetchUnsyncedData()
            
            let found = unsynced.contains { $0.id == testSample.id }
            
            return TestResult(
                name: "Save and Retrieve Data",
                category: .storage,
                status: found ? .passed : .failed,
                message: found ? "Data persisted correctly" : "Data not found after save",
                timestamp: Date(),
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            return TestResult(
                name: "Save and Retrieve Data",
                category: .storage,
                status: .failed,
                message: "Error: \(error.localizedDescription)",
                timestamp: Date(),
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testDataCleanup() async -> TestResult {
        let start = Date()
        
        do {
            let oldDate = Calendar.current.date(byAdding: .day, value: -31, to: Date())!
            try await storageManager.deleteOldData(olderThan: oldDate)
            
            return TestResult(
                name: "Data Cleanup",
                category: .storage,
                status: .passed,
                message: "Old data cleanup executed",
                timestamp: Date(),
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            return TestResult(
                name: "Data Cleanup",
                category: .storage,
                status: .failed,
                message: "Cleanup failed: \(error.localizedDescription)",
                timestamp: Date(),
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    // MARK: - Security Tests
    
    func testHTTPSEnforcement() async {
        currentTest = "Testing HTTPS enforcement..."
        
        let result = await testHTTPRejection()
        testResults.append(result)
        
        let httpsResult = await testHTTPSAcceptance()
        testResults.append(httpsResult)
    }
    
    private func testHTTPRejection() async -> TestResult {
        let start = Date()
        
        let httpConfig = GatewayConfig(
            baseURL: "http://insecure.example.com",
            port: 8080,
            apiKey: "test-key",
            username: nil,
            password: nil
        )
        
        do {
            try configManager.saveGatewayConfig(httpConfig)
            
            return TestResult(
                name: "HTTP Rejection",
                category: .security,
                status: .failed,
                message: "HTTP URL was accepted (should be rejected)",
                timestamp: Date(),
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            return TestResult(
                name: "HTTP Rejection",
                category: .security,
                status: .passed,
                message: "HTTP URL correctly rejected",
                timestamp: Date(),
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testHTTPSAcceptance() async -> TestResult {
        let start = Date()
        
        let httpsConfig = GatewayConfig(
            baseURL: "https://secure.example.com",
            port: 443,
            apiKey: "test-key",
            username: nil,
            password: nil
        )
        
        do {
            try configManager.saveGatewayConfig(httpsConfig)
            
            return TestResult(
                name: "HTTPS Acceptance",
                category: .security,
                status: .passed,
                message: "HTTPS URL correctly accepted",
                timestamp: Date(),
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            return TestResult(
                name: "HTTPS Acceptance",
                category: .security,
                status: .failed,
                message: "HTTPS URL rejected: \(error.localizedDescription)",
                timestamp: Date(),
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    // MARK: - Sync Flow Tests
    
    func testSyncFlow() async {
        currentTest = "Testing sync flow..."
        
        let result = await testCompleteSyncFlow()
        testResults.append(result)
    }
    
    private func testCompleteSyncFlow() async -> TestResult {
        let start = Date()
        
        do {
            // Perform manual sync
            try await syncManager.performManualSync()
            
            let status = syncManager.getSyncStatus()
            
            switch status {
            case .success:
                return TestResult(
                    name: "Complete Sync Flow",
                    category: .sync,
                    status: .passed,
                    message: "Sync completed successfully",
                    timestamp: Date(),
                    duration: Date().timeIntervalSince(start)
                )
            case .error(let error, _):
                return TestResult(
                    name: "Complete Sync Flow",
                    category: .sync,
                    status: .warning,
                    message: "Sync completed with error: \(error.message)",
                    timestamp: Date(),
                    duration: Date().timeIntervalSince(start)
                )
            default:
                return TestResult(
                    name: "Complete Sync Flow",
                    category: .sync,
                    status: .warning,
                    message: "Sync status: \(status)",
                    timestamp: Date(),
                    duration: Date().timeIntervalSince(start)
                )
            }
        } catch {
            return TestResult(
                name: "Complete Sync Flow",
                category: .sync,
                status: .failed,
                message: "Sync failed: \(error.localizedDescription)",
                timestamp: Date(),
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    // MARK: - Error Scenario Tests
    
    func testErrorScenarios() async {
        currentTest = "Testing error scenarios..."
        
        let invalidGatewayResult = await testInvalidGateway()
        testResults.append(invalidGatewayResult)
    }
    
    private func testInvalidGateway() async -> TestResult {
        let start = Date()
        
        // Configure invalid gateway
        let invalidConfig = GatewayConfig(
            baseURL: "https://invalid-gateway-that-does-not-exist.example.com",
            port: 9999,
            apiKey: "invalid-key",
            username: nil,
            password: nil
        )
        
        do {
            try configManager.saveGatewayConfig(invalidConfig)
            try gatewayService.configure(config: invalidConfig)
            
            let connected = try await gatewayService.testConnection()
            
            return TestResult(
                name: "Invalid Gateway Handling",
                category: .errorHandling,
                status: connected ? .failed : .passed,
                message: connected ? "Invalid gateway accepted" : "Invalid gateway correctly rejected",
                timestamp: Date(),
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            return TestResult(
                name: "Invalid Gateway Handling",
                category: .errorHandling,
                status: .passed,
                message: "Configuration save failed as expected",
                timestamp: Date(),
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    // MARK: - Permission Tests
    
    func testPermissionFlows() async {
        currentTest = "Testing permission flows..."
        
        let result = await testPermissionRequest()
        testResults.append(result)
    }
    
    private func testPermissionRequest() async -> TestResult {
        let start = Date()
        
        do {
            let types: Set<HealthDataType> = [.stepCount]
            try await healthKitManager.requestAuthorization(for: types)
            
            return TestResult(
                name: "Permission Request Flow",
                category: .permissions,
                status: .passed,
                message: "Permission request completed",
                timestamp: Date(),
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            return TestResult(
                name: "Permission Request Flow",
                category: .permissions,
                status: .failed,
                message: "Permission request failed: \(error.localizedDescription)",
                timestamp: Date(),
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    // MARK: - Data Recovery Tests
    
    func testDataRecovery() async {
        currentTest = "Testing data recovery..."
        
        let result = await testUnsyncedDataRecovery()
        testResults.append(result)
    }
    
    private func testUnsyncedDataRecovery() async -> TestResult {
        let start = Date()
        
        do {
            let unsyncedData = try await storageManager.fetchUnsyncedData()
            
            return TestResult(
                name: "Unsynced Data Recovery",
                category: .storage,
                status: .passed,
                message: "Found \(unsyncedData.count) unsynced samples",
                timestamp: Date(),
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            return TestResult(
                name: "Unsynced Data Recovery",
                category: .storage,
                status: .failed,
                message: "Recovery failed: \(error.localizedDescription)",
                timestamp: Date(),
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    // MARK: - Test Summary
    
    func getTestSummary() -> TestSummary {
        let passed = testResults.filter { $0.status == .passed }.count
        let failed = testResults.filter { $0.status == .failed }.count
        let warnings = testResults.filter { $0.status == .warning }.count
        let skipped = testResults.filter { $0.status == .skipped }.count
        
        return TestSummary(
            total: testResults.count,
            passed: passed,
            failed: failed,
            warnings: warnings,
            skipped: skipped,
            duration: testResults.reduce(0) { $0 + $1.duration }
        )
    }
    
    struct TestSummary {
        let total: Int
        let passed: Int
        let failed: Int
        let warnings: Int
        let skipped: Int
        let duration: TimeInterval
        
        var passRate: Double {
            guard total > 0 else { return 0 }
            return Double(passed) / Double(total) * 100
        }
    }
}
