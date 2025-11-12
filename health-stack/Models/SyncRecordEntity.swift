//
//  SyncRecordEntity.swift
//  health-stack
//

import Foundation
import CoreData

@objc(SyncRecordEntity)
public class SyncRecordEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Date
    @NSManaged public var status: String
    @NSManaged public var syncedCount: Int32
    @NSManaged public var errorMessage: String?
    @NSManaged public var duration: Double
}

extension SyncRecordEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SyncRecordEntity> {
        return NSFetchRequest<SyncRecordEntity>(entityName: "SyncRecordEntity")
    }
    
    func toSyncRecord() -> SyncRecord? {
        guard let recordStatus = SyncRecordStatus(rawValue: status) else {
            return nil
        }
        
        return SyncRecord(
            id: id,
            timestamp: timestamp,
            status: recordStatus,
            syncedCount: Int(syncedCount),
            errorMessage: errorMessage,
            duration: duration
        )
    }
    
    func update(from record: SyncRecord) {
        self.id = record.id
        self.timestamp = record.timestamp
        self.status = record.status.rawValue
        self.syncedCount = Int32(record.syncedCount)
        self.errorMessage = record.errorMessage
        self.duration = record.duration
    }
}
