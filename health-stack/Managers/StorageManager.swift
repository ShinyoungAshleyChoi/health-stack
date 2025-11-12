//
//  StorageManager.swift
//  health-stack
//

import Foundation
import CoreData
import os.log

class StorageManager: StorageManagerProtocol {
    static let shared = StorageManager()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "health-stack", category: "StorageManager")
    private let storageMonitor = StorageMonitor.shared
    
    // MARK: - Core Data Stack
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "HealthDataModel")
        
        // Enable persistent store encryption with Data Protection
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.setOption(
            FileProtectionType.complete as NSObject,
            forKey: NSPersistentStoreFileProtectionKey
        )
        
        // Enable persistent history tracking for better sync management
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { description, error in
            if let error = error {
                // In production, handle this error appropriately
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        
        // Automatically merge changes from parent context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    private var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init() {}
    
    // MARK: - Private Helper Methods
    
    private func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    private func saveContext(_ context: NSManagedObjectContext) throws {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                throw StorageError.saveFailed(error)
            }
        }
    }
    
    // MARK: - StorageManagerProtocol Implementation
    
    func saveHealthData(_ data: [HealthDataSample], userId: String) async throws {
        // Check storage space before saving
        guard storageMonitor.hasAvailableSpace() else {
            logger.error("Insufficient storage space available")
            throw StorageError.saveFailed(NSError(
                domain: "StorageManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Insufficient storage space. Please free up space on your device."]
            ))
        }
        
        logger.info("Saving \(data.count) health data samples for user \(userId)")
        
        let context = newBackgroundContext()
        
        try await context.perform {
            for sample in data {
                // Check if entity already exists
                let fetchRequest: NSFetchRequest<HealthDataEntity> = HealthDataEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", sample.id as CVarArg)
                fetchRequest.fetchLimit = 1
                
                let existingEntities = try context.fetch(fetchRequest)
                
                let entity: HealthDataEntity
                if let existing = existingEntities.first {
                    entity = existing
                } else {
                    entity = HealthDataEntity(context: context)
                }
                
                entity.update(from: sample, userId: userId)
            }
            
            try self.saveContext(context)
            self.logger.info("Successfully saved \(data.count) health data samples")
        }
    }
    
    func fetchUnsyncedData() async throws -> [HealthDataSample] {
        let context = newBackgroundContext()
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<HealthDataEntity> = HealthDataEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "isSynced == NO")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            
            do {
                let entities = try context.fetch(fetchRequest)
                return entities.compactMap { $0.toHealthDataSample() }
            } catch {
                throw StorageError.fetchFailed(error)
            }
        }
    }
    
    func fetchUnsyncedData(limit: Int, offset: Int) async throws -> [HealthDataSample] {
        let context = newBackgroundContext()
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<HealthDataEntity> = HealthDataEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "isSynced == NO")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            fetchRequest.fetchLimit = limit
            fetchRequest.fetchOffset = offset
            
            do {
                let entities = try context.fetch(fetchRequest)
                return entities.compactMap { $0.toHealthDataSample() }
            } catch {
                throw StorageError.fetchFailed(error)
            }
        }
    }
    
    func getUnsyncedDataCount() async throws -> Int {
        let context = newBackgroundContext()
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<HealthDataEntity> = HealthDataEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "isSynced == NO")
            
            do {
                return try context.count(for: fetchRequest)
            } catch {
                throw StorageError.fetchFailed(error)
            }
        }
    }
    
    func markAsSynced(ids: [UUID]) async throws {
        let context = newBackgroundContext()
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<HealthDataEntity> = HealthDataEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id IN %@", ids)
            
            do {
                let entities = try context.fetch(fetchRequest)
                for entity in entities {
                    entity.isSynced = true
                }
                try self.saveContext(context)
            } catch let error as StorageError {
                throw error
            } catch {
                throw StorageError.saveFailed(error)
            }
        }
    }
    
    func deleteOldData(olderThan date: Date) async throws {
        let context = newBackgroundContext()
        
        try await context.perform {
            // Only delete synced data that is older than the specified date
            let fetchRequest: NSFetchRequest<HealthDataEntity> = HealthDataEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(
                format: "isSynced == YES AND createdAt < %@",
                date as NSDate
            )
            
            do {
                let entities = try context.fetch(fetchRequest)
                for entity in entities {
                    context.delete(entity)
                }
                try self.saveContext(context)
            } catch let error as StorageError {
                throw error
            } catch {
                throw StorageError.saveFailed(error)
            }
        }
    }
    
    func saveSyncRecord(_ record: SyncRecord) async throws {
        let context = newBackgroundContext()
        
        try await context.perform {
            let entity = SyncRecordEntity(context: context)
            entity.update(from: record)
            try self.saveContext(context)
        }
    }
    
    func fetchSyncRecords(limit: Int = 50) async throws -> [SyncRecord] {
        let context = newBackgroundContext()
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<SyncRecordEntity> = SyncRecordEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            fetchRequest.fetchLimit = limit
            
            do {
                let entities = try context.fetch(fetchRequest)
                return entities.compactMap { $0.toSyncRecord() }
            } catch {
                throw StorageError.fetchFailed(error)
            }
        }
    }
}
