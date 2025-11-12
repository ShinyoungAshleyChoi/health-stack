//
//  DataCleanupScheduler.swift
//  health-stack
//

import Foundation
import os.log

/// Schedules and manages automatic data cleanup operations
class DataCleanupScheduler {
    static let shared = DataCleanupScheduler()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "health-stack", category: "DataCleanupScheduler")
    private let storageManager: StorageManagerProtocol
    
    private var cleanupTimer: Timer?
    private let cleanupInterval: TimeInterval = 86400 // 24 hours
    private let dataRetentionDays = 30 // Keep synced data for 30 days
    
    private init(storageManager: StorageManagerProtocol = StorageManager.shared) {
        self.storageManager = storageManager
    }
    
    // MARK: - Public Methods
    
    /// Start automatic cleanup scheduling
    func startAutomaticCleanup() {
        stopAutomaticCleanup()
        
        logger.info("Starting automatic data cleanup scheduler")
        
        // Perform initial cleanup
        Task {
            await performCleanup()
        }
        
        // Schedule periodic cleanup
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: cleanupInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.performCleanup()
            }
        }
    }
    
    /// Stop automatic cleanup scheduling
    func stopAutomaticCleanup() {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
        logger.info("Stopped automatic data cleanup scheduler")
    }
    
    /// Perform immediate cleanup
    func performCleanup() async {
        logger.info("Starting data cleanup")
        
        let startTime = Date()
        
        do {
            // Calculate cutoff date
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -dataRetentionDays, to: Date()) ?? Date()
            
            logger.info("Deleting synced data older than \(cutoffDate)")
            
            // Delete old synced data
            try await storageManager.deleteOldData(olderThan: cutoffDate)
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Data cleanup completed in \(String(format: "%.3f", duration))s")
            
        } catch {
            logger.error("Data cleanup failed: \(error.localizedDescription)")
        }
    }
    
    /// Get next scheduled cleanup time
    func getNextCleanupTime() -> Date? {
        guard let timer = cleanupTimer else { return nil }
        return timer.fireDate
    }
    
    /// Check if cleanup is scheduled
    var isScheduled: Bool {
        return cleanupTimer != nil
    }
}
