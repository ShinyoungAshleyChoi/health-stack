//
//  StorageMonitor.swift
//  health-stack
//

import Foundation
import os.log

/// Monitors device storage space availability
class StorageMonitor {
    static let shared = StorageMonitor()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "health-stack", category: "StorageMonitor")
    
    // Minimum required free space in bytes (100 MB)
    private let minimumFreeSpace: Int64 = 100 * 1024 * 1024
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Check if there is sufficient storage space available
    func hasAvailableSpace() -> Bool {
        guard let freeSpace = getAvailableSpace() else {
            logger.warning("Unable to determine available storage space")
            return true // Assume space is available if we can't determine
        }
        
        let hasSpace = freeSpace >= minimumFreeSpace
        
        if !hasSpace {
            logger.warning("Insufficient storage space: \(freeSpace) bytes available, \(self.minimumFreeSpace) bytes required")
        }
        
        return hasSpace
    }
    
    /// Get available storage space in bytes
    func getAvailableSpace() -> Int64? {
        do {
            let fileURL = URL(fileURLWithPath: NSHomeDirectory())
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            
            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                return capacity
            }
            
            // Fallback to regular available capacity
            let fallbackValues = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            return fallbackValues.volumeAvailableCapacity.map { Int64($0) }
            
        } catch {
            logger.error("Failed to get available storage space: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Get total storage space in bytes
    func getTotalSpace() -> Int64? {
        do {
            let fileURL = URL(fileURLWithPath: NSHomeDirectory())
            let values = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey])
            return values.volumeTotalCapacity.map { Int64($0) }
        } catch {
            logger.error("Failed to get total storage space: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Get used storage space in bytes
    func getUsedSpace() -> Int64? {
        guard let total = getTotalSpace(),
              let available = getAvailableSpace() else {
            return nil
        }
        return total - available
    }
    
    /// Get storage usage percentage (0.0 to 1.0)
    func getStorageUsagePercentage() -> Double? {
        guard let total = getTotalSpace(),
              let used = getUsedSpace(),
              total > 0 else {
            return nil
        }
        return Double(used) / Double(total)
    }
    
    /// Log current storage status
    func logStorageStatus() {
        guard let available = getAvailableSpace(),
              let total = getTotalSpace() else {
            logger.warning("Unable to retrieve storage information")
            return
        }
        
        let availableMB = Double(available) / 1024.0 / 1024.0
        let totalMB = Double(total) / 1024.0 / 1024.0
        let usedMB = totalMB - availableMB
        let usagePercentage = (usedMB / totalMB) * 100.0
        
        logger.info("Storage: \(String(format: "%.2f", usedMB)) MB used / \(String(format: "%.2f", totalMB)) MB total (\(String(format: "%.1f", usagePercentage))%)")
        logger.info("Available: \(String(format: "%.2f", availableMB)) MB")
    }
}
