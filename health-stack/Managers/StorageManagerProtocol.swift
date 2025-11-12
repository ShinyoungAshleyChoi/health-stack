//
//  StorageManagerProtocol.swift
//  health-stack
//

import Foundation

protocol StorageManagerProtocol {
    /// Save health data samples to local storage
    func saveHealthData(_ data: [HealthDataSample], userId: String) async throws
    
    /// Fetch all unsynced health data samples
    func fetchUnsyncedData() async throws -> [HealthDataSample]
    
    /// Fetch unsynced health data samples with pagination
    func fetchUnsyncedData(limit: Int, offset: Int) async throws -> [HealthDataSample]
    
    /// Get count of unsynced data samples
    func getUnsyncedDataCount() async throws -> Int
    
    /// Mark health data samples as synced
    func markAsSynced(ids: [UUID]) async throws
    
    /// Delete old synced data older than the specified date
    func deleteOldData(olderThan date: Date) async throws
    
    /// Save a sync record
    func saveSyncRecord(_ record: SyncRecord) async throws
    
    /// Fetch recent sync records
    func fetchSyncRecords(limit: Int) async throws -> [SyncRecord]
}
