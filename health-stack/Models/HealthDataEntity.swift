//
//  HealthDataEntity.swift
//  health-stack
//

import Foundation
import CoreData

@objc(HealthDataEntity)
public class HealthDataEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var userId: String
    @NSManaged public var type: String
    @NSManaged public var value: Double
    @NSManaged public var unit: String
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date
    @NSManaged public var sourceBundle: String?
    @NSManaged public var metadata: [String: String]?
    @NSManaged public var isSynced: Bool
    @NSManaged public var createdAt: Date
}

extension HealthDataEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<HealthDataEntity> {
        return NSFetchRequest<HealthDataEntity>(entityName: "HealthDataEntity")
    }
    
    func toHealthDataSample() -> HealthDataSample? {
        guard let healthDataType = HealthDataType(rawValue: type) else {
            return nil
        }
        
        return HealthDataSample(
            id: id,
            type: healthDataType,
            value: value,
            unit: unit,
            startDate: startDate,
            endDate: endDate,
            sourceBundle: sourceBundle,
            metadata: metadata,
            isSynced: isSynced,
            createdAt: createdAt
        )
    }
    
    func update(from sample: HealthDataSample, userId: String) {
        self.id = sample.id
        self.userId = userId
        self.type = sample.type.rawValue
        self.value = sample.value
        self.unit = sample.unit
        self.startDate = sample.startDate
        self.endDate = sample.endDate
        self.sourceBundle = sample.sourceBundle
        self.metadata = sample.metadata
        self.isSynced = sample.isSynced
        self.createdAt = sample.createdAt
    }
}
