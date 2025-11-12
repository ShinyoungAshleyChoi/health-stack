//
//  SyncManagerProtocol.swift
//  health-stack
//

import Foundation

protocol SyncManagerProtocol {
    /// Start automatic synchronization based on configured frequency
    func startAutoSync()
    
    /// Stop automatic synchronization
    func stopAutoSync()
    
    /// Perform a manual sync immediately
    func performManualSync() async throws
    
    /// Get the current sync status
    func getSyncStatus() -> SyncStatus
    
    /// Get sync history records
    func getSyncHistory() async throws -> [SyncRecord]
    
    /// Set a callback for sync status updates
    func setSyncStatusCallback(_ callback: @escaping (SyncStatus) -> Void)
}
