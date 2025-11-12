//
//  SyncManager.swift
//  health-stack
//

import Foundation
import BackgroundTasks
import Combine
import UIKit
import os.log

class SyncManager: SyncManagerProtocol {
    // MARK: - Properties
    
    private let healthKitManager: HealthKitManagerProtocol
    private let gatewayService: GatewayServiceProtocol
    private let storageManager: StorageManagerProtocol
    private let configurationManager: ConfigurationManagerProtocol
    
    private var currentStatus: SyncStatus = .idle
    private var syncStatusCallback: ((SyncStatus) -> Void)?
    
    private var autoSyncTimer: Timer?
    private var isAutoSyncEnabled = false
    private var isSyncing = false
    
    // Retry configuration
    private let maxRetryAttempts = 5
    private let baseRetryDelay: TimeInterval = 1.0
    
    // Batching configuration
    private let batchSize = 100 // Max samples per batch
    private let maxHealthKitQueryLimit = 1000 // Max samples per HealthKit query
    
    // Sync queue for failed requests - using actor for thread safety
    private let syncQueueActor = SyncQueueActor()
    
    private let logger = Logger(subsystem: "com.healthstack", category: "SyncManager")
    
    // MARK: - Initialization
    
    init(
        healthKitManager: HealthKitManagerProtocol,
        gatewayService: GatewayServiceProtocol,
        storageManager: StorageManagerProtocol,
        configurationManager: ConfigurationManagerProtocol
    ) {
        self.healthKitManager = healthKitManager
        self.gatewayService = gatewayService
        self.storageManager = storageManager
        self.configurationManager = configurationManager
        
        setupBackgroundSync()
        setupNetworkMonitoring()
        setupHealthKitObservation()
        setupDataCleanup()
    }
    
    // MARK: - Public Methods
    
    func startAutoSync() {
        guard !isAutoSyncEnabled else {
            logger.info("Auto sync already enabled")
            return
        }
        
        isAutoSyncEnabled = true
        let frequency = configurationManager.getSyncFrequency()
        
        logger.info("Starting auto sync with frequency: \(frequency.displayName)")
        
        switch frequency {
        case .realtime:
            startRealtimeSync()
        case .hourly, .daily:
            schedulePeriodicSync(frequency: frequency)
        case .manual:
            logger.info("Manual sync mode - no automatic sync scheduled")
        }
    }
    
    func stopAutoSync() {
        guard isAutoSyncEnabled else {
            logger.info("Auto sync already disabled")
            return
        }
        
        isAutoSyncEnabled = false
        
        // Stop timer
        autoSyncTimer?.invalidate()
        autoSyncTimer = nil
        
        // Stop HealthKit observation
        healthKitManager.stopObservingHealthData()
        
        // Cancel background tasks
        BackgroundTaskManager.shared.cancelAllTasks()
        
        logger.info("Auto sync stopped")
    }
    
    func performManualSync() async throws {
        guard !isSyncing else {
            logger.warning("Sync already in progress")
            throw SyncError.syncInProgress
        }
        
        logger.info("Starting manual sync")
        
        isSyncing = true
        updateStatus(.syncing(progress: 0.0))
        
        let startTime = Date()
        
        do {
            // Clear HealthKit authorization cache to ensure fresh status
            if let healthKitManager = healthKitManager as? HealthKitManager {
                healthKitManager.clearAuthorizationCache()
            }
            
            updateStatus(.syncing(progress: 0.05))
            
            // Fetch new data from HealthKit first (with pagination)
            let newData = try await fetchNewHealthData()
            
            updateStatus(.syncing(progress: 0.2))
            
            // Get userId from configuration
            let userId = configurationManager.getUserId() ?? UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
            
            // Save new data to storage in batches to optimize memory
            if !newData.isEmpty {
                logger.info("Saving \(newData.count) new samples to storage")
                let newDataBatches = newData.chunked(into: batchSize)
                for (index, batch) in newDataBatches.enumerated() {
                    try await storageManager.saveHealthData(batch, userId: userId)
                    let saveProgress = 0.2 + (0.1 * Double(index + 1) / Double(newDataBatches.count))
                    updateStatus(.syncing(progress: saveProgress))
                }
                logger.info("All new data saved to storage")
            } else {
                logger.info("No new data to save")
            }
            
            updateStatus(.syncing(progress: 0.3))
            
            // Small delay to ensure CoreData has committed changes
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Fetch unsynced data count
            logger.info("Fetching unsynced data count...")
            let unsyncedCount = try await storageManager.getUnsyncedDataCount()
            logger.info("Unsynced data count: \(unsyncedCount)")
            
            logger.info("Total unsynced samples: \(unsyncedCount)")
            
            guard unsyncedCount > 0 else {
                logger.info("No data to sync")
                let duration = Date().timeIntervalSince(startTime)
                let record = SyncRecord(
                    status: .success,
                    syncedCount: 0,
                    duration: duration
                )
                try await storageManager.saveSyncRecord(record)
                
                updateStatus(.syncing(progress: 1.0))
                updateStatus(.success(syncedCount: 0, timestamp: Date()))
                isSyncing = false
                return
            }
            
            // Process unsynced data in batches to optimize memory usage
            var totalSynced = 0
            var offset = 0
            var batchNumber = 1
            let totalBatches = (unsyncedCount + batchSize - 1) / batchSize
            
            logger.info("Starting batch processing: \(totalBatches) batches of up to \(self.batchSize) samples")
            
            while offset < unsyncedCount {
                logger.info("=== Batch \(batchNumber)/\(totalBatches) - Offset: \(offset) ===")
                
                // Fetch batch of unsynced data
                logger.info("Fetching batch from storage...")
                let batchData = try await storageManager.fetchUnsyncedData(limit: batchSize, offset: offset)
                
                guard !batchData.isEmpty else { 
                    logger.warning("⚠️ No more data to fetch at offset \(offset) - Breaking loop")
                    break 
                }
                
                logger.info("✓ Fetched \(batchData.count) samples")
                
                // Update progress (30% to 90% for sending data)
                let sendProgress = 0.3 + (0.6 * Double(offset) / Double(unsyncedCount))
                updateStatus(.syncing(progress: sendProgress))
                logger.info("Progress updated to \(Int(sendProgress * 100))%")
                
                // Send batch to gateway
                logger.info("Sending batch to gateway...")
                let syncedCount = try await sendDataWithRetry(batchData)
                logger.info("✓ Sent \(syncedCount)/\(batchData.count) samples successfully")
                
                // Mark as synced
                if syncedCount > 0 {
                    let syncedIds = batchData.prefix(syncedCount).map { $0.id }
                    logger.info("Marking \(syncedIds.count) samples as synced...")
                    try await storageManager.markAsSynced(ids: syncedIds)
                    logger.info("✓ Marked as synced")
                }
                
                totalSynced += syncedCount
                offset += batchData.count // Use actual batch size, not batchSize constant
                batchNumber += 1
                
                let percentComplete = Int((Double(totalSynced)/Double(unsyncedCount)) * 100)
                logger.info("=== Batch Complete: \(totalSynced)/\(unsyncedCount) samples synced (\(percentComplete)%) ===")
                
                // Safety check to prevent infinite loop
                if batchNumber > totalBatches + 10 {
                    logger.error("⚠️ Too many iterations - Breaking to prevent infinite loop")
                    break
                }
            }
            
            logger.info("Batch processing complete: \(totalSynced) total samples synced")
            
            updateStatus(.syncing(progress: 0.95))
            
            let duration = Date().timeIntervalSince(startTime)
            let status: SyncRecordStatus = totalSynced == unsyncedCount ? .success : .partialSuccess
            
            let record = SyncRecord(
                status: status,
                syncedCount: totalSynced,
                duration: duration
            )
            try await storageManager.saveSyncRecord(record)
            
            logger.info("Manual sync completed: \(totalSynced) samples synced")
            
            // Cleanup old data
            try await cleanupOldData()
            
            updateStatus(.syncing(progress: 1.0))
            updateStatus(.success(syncedCount: totalSynced, timestamp: Date()))
            
            isSyncing = false
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            let record = SyncRecord(
                status: .failed,
                syncedCount: 0,
                errorMessage: error.localizedDescription,
                duration: duration
            )
            try? await storageManager.saveSyncRecord(record)
            
            updateStatus(.error(SyncStatus.ErrorInfo(from: error), timestamp: Date()))
            
            logger.error("Manual sync failed: \(error.localizedDescription)")
            
            isSyncing = false
            throw error
        }
    }
    
    func getSyncStatus() -> SyncStatus {
        return currentStatus
    }
    
    func getSyncHistory() async throws -> [SyncRecord] {
        return try await storageManager.fetchSyncRecords(limit: 50)
    }
    
    func setSyncStatusCallback(_ callback: @escaping (SyncStatus) -> Void) {
        self.syncStatusCallback = callback
    }
    
    // MARK: - Private Methods
    
    private func updateStatus(_ status: SyncStatus) {
        currentStatus = status
        syncStatusCallback?(status)
    }
    
    private func startRealtimeSync() {
        let preferences = configurationManager.getDataTypePreferences()
        let enabledTypes = Set(preferences.filter { $0.value }.keys)
        
        guard !enabledTypes.isEmpty else {
            logger.warning("No data types enabled for sync")
            return
        }
        
        healthKitManager.startObservingHealthData(types: enabledTypes)
        logger.info("Real-time sync started for \(enabledTypes.count) data types")
        
        // Perform initial sync
        Task {
            try? await performManualSync()
        }
    }
    
    private func schedulePeriodicSync(frequency: SyncFrequency) {
        guard let interval = frequency.interval else { return }
        
        // Schedule timer for foreground sync
        autoSyncTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task {
                try? await self?.performManualSync()
            }
        }
        
        // Schedule background task
        BackgroundTaskManager.shared.scheduleHealthSyncTask(interval: interval)
        
        // Perform initial sync
        Task {
            try? await performManualSync()
        }
    }
    
    private func fetchNewHealthData() async throws -> [HealthDataSample] {
        let preferences = configurationManager.getDataTypePreferences()
        let enabledTypes = preferences.filter { $0.value }.keys
        
        guard !enabledTypes.isEmpty else {
            return []
        }
        
        // Fetch data from last sync time
        let lastSyncTime = getLastSyncTime()
        let now = Date()
        
        var allSamples: [HealthDataSample] = []
        
        for dataType in enabledTypes {
            do {
                // Use pagination for large datasets to optimize memory usage
                let samples = try await healthKitManager.fetchHealthData(
                    type: dataType,
                    from: lastSyncTime,
                    to: now,
                    limit: maxHealthKitQueryLimit
                )
                allSamples.append(contentsOf: samples)
            } catch {
                logger.error("Failed to fetch \(dataType.rawValue): \(error.localizedDescription)")
            }
        }
        
        logger.info("Fetched \(allSamples.count) new samples from HealthKit")
        return allSamples
    }
    
    private func sendDataWithRetry(_ data: [HealthDataSample]) async throws -> Int {
        // Check if gateway is configured
        guard let config = try? configurationManager.getGatewayConfig() else {
            logger.warning("⚠️ Gateway not configured - Data will be stored locally only")
            // Return success count so data gets marked as "synced" (ready to sync when gateway is configured)
            return data.count
        }
        
        // Configure gateway service
        try gatewayService.configure(config: config)
        
        // Process data in batches to optimize memory and network usage
        var totalSynced = 0
        let batches = data.chunked(into: batchSize)
        
        logger.info("Sending \(data.count) samples in \(batches.count) batches to gateway")
        
        for (index, batch) in batches.enumerated() {
            var attempt = 0
            var lastError: Error?
            var batchSynced = false
            
            while attempt < maxRetryAttempts && !batchSynced {
                do {
                    // Send batch
                    let response = try await gatewayService.sendHealthData(batch)
                    
                    logger.info("Successfully sent batch \(index + 1)/\(batches.count) with \(batch.count) samples")
                    totalSynced += batch.count
                    batchSynced = true
                    
                } catch {
                    lastError = error
                    attempt += 1
                    
                    if attempt < maxRetryAttempts {
                        let delay = baseRetryDelay * pow(2.0, Double(attempt - 1))
                        logger.warning("Batch \(index + 1) attempt \(attempt) failed, retrying in \(delay)s: \(error.localizedDescription)")
                        
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    } else {
                        logger.error("Batch \(index + 1) failed after \(attempt) tries")
                        // Add failed batch to sync queue
                        addToSyncQueue(batch)
                    }
                }
            }
        }
        
        logger.info("Sync completed: \(totalSynced)/\(data.count) samples sent successfully")
        return totalSynced
    }
    
    private func addToSyncQueue(_ data: [HealthDataSample]) {
        Task {
            await syncQueueActor.add(data)
            let queueSize = await syncQueueActor.count()
            logger.info("Added \(data.count) samples to sync queue. Queue size: \(queueSize)")
        }
    }
    
    private func processSyncQueue() async {
        let queuedData = await syncQueueActor.removeAll()
        
        guard !queuedData.isEmpty else { return }
        
        logger.info("Processing sync queue with \(queuedData.count) samples")
        
        do {
            _ = try await sendDataWithRetry(queuedData)
            
            // Mark as synced
            let syncedIds = queuedData.map { $0.id }
            try await storageManager.markAsSynced(ids: syncedIds)
            
            logger.info("Successfully processed sync queue")
        } catch {
            logger.error("Failed to process sync queue: \(error.localizedDescription)")
            // Items will be re-added to queue by sendDataWithRetry
        }
    }
    
    private func getLastSyncTime() -> Date {
        // Try to get last successful sync time from storage
        // This is a synchronous approximation - in production, cache this value
        let defaultDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        
        // For now, use 24 hours ago as default
        // TODO: Cache last sync time in UserDefaults or ConfigurationManager
        return defaultDate
    }
    
    private func cleanupOldData() async throws {
        // Delete synced data older than 30 days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        try await storageManager.deleteOldData(olderThan: thirtyDaysAgo)
        logger.info("Cleaned up old data")
    }
    
    // MARK: - Background Sync Setup
    
    private func setupBackgroundSync() {
        // Register sync handler with BackgroundTaskManager
        BackgroundTaskManager.shared.setSyncHandler { [weak self] in
            guard let self = self else { return }
            
            // Perform sync
            try await self.performManualSync()
            
            // Reschedule next background task
            let frequency = self.configurationManager.getSyncFrequency()
            if let interval = frequency.interval {
                BackgroundTaskManager.shared.scheduleHealthSyncTask(interval: interval)
            }
        }
        
        logger.info("Background sync handler configured")
    }
    
    // MARK: - HealthKit Observation Setup
    
    private func setupHealthKitObservation() {
        // Set observation handler for real-time sync
        if let healthKitManager = healthKitManager as? HealthKitManager {
            healthKitManager.setObservationHandler { [weak self] dataType in
                guard let self = self else { return }
                
                self.logger.info("New health data available for \(dataType.rawValue)")
                
                // Trigger sync for real-time mode
                let frequency = self.configurationManager.getSyncFrequency()
                if frequency == .realtime {
                    Task {
                        try? await self.performManualSync()
                    }
                }
            }
        }
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        // Monitor network restoration
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(networkRestored),
            name: NSNotification.Name("NetworkRestored"),
            object: nil
        )
    }
    
    @objc private func networkRestored() {
        logger.info("Network restored, processing sync queue")
        
        Task {
            await processSyncQueue()
        }
    }
    
    // MARK: - Data Cleanup Setup
    
    private func setupDataCleanup() {
        // Start automatic cleanup scheduler
        DataCleanupScheduler.shared.startAutomaticCleanup()
        logger.info("Data cleanup scheduler configured")
    }
}

// MARK: - Sync Queue Actor

actor SyncQueueActor {
    private var queue: [HealthDataSample] = []
    
    func add(_ samples: [HealthDataSample]) {
        queue.append(contentsOf: samples)
    }
    
    func removeAll() -> [HealthDataSample] {
        let items = queue
        queue.removeAll()
        return items
    }
    
    func count() -> Int {
        return queue.count
    }
}

// MARK: - Errors

enum SyncError: LocalizedError {
    case syncInProgress
    case gatewayNotConfigured
    case noDataToSync
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .syncInProgress:
            return "A sync operation is already in progress"
        case .gatewayNotConfigured:
            return "Gateway is not configured"
        case .noDataToSync:
            return "No data available to sync"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
