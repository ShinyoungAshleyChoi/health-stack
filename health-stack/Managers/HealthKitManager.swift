//
//  HealthKitManager.swift
//  health-stack
//

import Foundation
import HealthKit
import UIKit
import os.log

class HealthKitManager: HealthKitManagerProtocol {
    private let healthStore = HKHealthStore()
    private var observers: [HKObserverQuery] = []
    private var observationHandler: ((HealthDataType) -> Void)?
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "health-stack", category: "HealthKitManager")
    
    // Cache for authorization status
    private var authorizationCache: [HealthDataType: (status: HKAuthorizationStatus, timestamp: Date)] = [:]
    private let authorizationCacheTimeout: TimeInterval = 300 // 5 minutes
    
    init() {}
    
    // MARK: - Authorization
    
    func requestAuthorization(for types: Set<HealthDataType>) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            logger.error("HealthKit is not available on this device")
            throw HealthKitError.notAvailable
        }
        
        logger.info("Requesting authorization for \(types.count) health data types")
        
        let hkTypes = types.compactMap { dataType -> HKObjectType? in
            if let quantityTypeId = dataType.hkQuantityType {
                return HKObjectType.quantityType(forIdentifier: quantityTypeId)
            } else if dataType == .sleepAnalysis {
                return HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
            }
            return nil
        }
        
        let typesToRead = Set(hkTypes)
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            logger.info("HealthKit authorization request completed")
        } catch {
            logger.error("HealthKit authorization failed: \(error.localizedDescription)")
            throw HealthKitError.queryFailed(error)
        }
    }
    
    // MARK: - Fetch Health Data
    
    func fetchHealthData(type: HealthDataType, from startDate: Date, to endDate: Date) async throws -> [HealthDataSample] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        // Note: HealthKit's authorization status is intentionally vague for privacy reasons
        // Even when authorized, it may return .notDetermined
        // The only reliable way to check is to attempt the query
        logger.info("Fetching \(type.rawValue) data from \(startDate) to \(endDate)")
        
        // Handle special case for sleep analysis (category type)
        if type == .sleepAnalysis {
            return try await fetchSleepData(from: startDate, to: endDate)
        }
        
        // Handle quantity types
        guard let quantityTypeId = type.hkQuantityType,
              let quantityType = HKObjectType.quantityType(forIdentifier: quantityTypeId) else {
            throw HealthKitError.dataNotAvailable
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    self.logger.error("Query failed for \(type.rawValue): \(error.localizedDescription)")
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                
                guard let samples = samples as? [HKQuantitySample] else {
                    self.logger.info("No samples found for \(type.rawValue)")
                    continuation.resume(returning: [])
                    return
                }
                
                self.logger.info("Fetched \(samples.count) samples for \(type.rawValue)")
                let healthDataSamples = samples.map { self.convertToHealthDataSample($0, type: type) }
                continuation.resume(returning: healthDataSamples)
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchHealthData(type: HealthDataType, from startDate: Date, to endDate: Date, limit: Int) async throws -> [HealthDataSample] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        // Note: HealthKit's authorization status is intentionally vague for privacy reasons
        // Even when authorized, it may return .notDetermined
        // The only reliable way to check is to attempt the query
        logger.info("Fetching \(type.rawValue) data (limit: \(limit)) from \(startDate) to \(endDate)")
        
        // Handle special case for sleep analysis (category type)
        if type == .sleepAnalysis {
            return try await fetchSleepData(from: startDate, to: endDate, limit: limit)
        }
        
        // Handle quantity types
        guard let quantityTypeId = type.hkQuantityType,
              let quantityType = HKObjectType.quantityType(forIdentifier: quantityTypeId) else {
            throw HealthKitError.dataNotAvailable
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    self.logger.error("Query failed for \(type.rawValue): \(error.localizedDescription)")
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                
                guard let samples = samples as? [HKQuantitySample] else {
                    self.logger.info("No samples found for \(type.rawValue)")
                    continuation.resume(returning: [])
                    return
                }
                
                self.logger.info("Fetched \(samples.count) samples for \(type.rawValue)")
                let healthDataSamples = samples.map { self.convertToHealthDataSample($0, type: type) }
                continuation.resume(returning: healthDataSamples)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Background Observation
    
    func startObservingHealthData(types: Set<HealthDataType>) {
        stopObservingHealthData() // Clean up existing observers
        
        logger.info("Starting observation for \(types.count) health data types")
        
        for dataType in types {
            // Handle quantity types
            if let quantityTypeId = dataType.hkQuantityType,
               let quantityType = HKObjectType.quantityType(forIdentifier: quantityTypeId) {
                startObservingQuantityType(quantityType, dataType: dataType)
            }
            // Handle category types (e.g., sleep)
            else if dataType == .sleepAnalysis,
                    let categoryType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
                startObservingCategoryType(categoryType, dataType: dataType)
            }
        }
        
        logger.info("Started observing \(self.observers.count) health data types")
    }
    
    func stopObservingHealthData() {
        logger.info("Stopping observation for \(self.observers.count) health data types")
        
        // Stop all observer queries
        for observer in observers {
            healthStore.stop(observer)
        }
        observers.removeAll()
        
        // Disable background delivery for all types
        // Note: We don't disable background delivery here to allow other apps to continue receiving updates
        // Background delivery will be automatically disabled when the app is uninstalled
        
        logger.info("Stopped all health data observation")
    }
    
    // MARK: - Private Observation Methods
    
    private func startObservingQuantityType(_ quantityType: HKQuantityType, dataType: HealthDataType) {
        // Enable background delivery first
        healthStore.enableBackgroundDelivery(for: quantityType, frequency: .immediate) { [weak self] success, error in
            if let error = error {
                self?.logger.error("Failed to enable background delivery for \(dataType.rawValue): \(error.localizedDescription)")
            } else if success {
                self?.logger.info("Enabled background delivery for \(dataType.rawValue)")
            }
        }
        
        // Create observer query
        let query = HKObserverQuery(sampleType: quantityType, predicate: nil) { [weak self] _, completionHandler, error in
            guard let self = self else {
                completionHandler()
                return
            }
            
            if let error = error {
                self.logger.error("Observer query error for \(dataType.rawValue): \(error.localizedDescription)")
                completionHandler()
                return
            }
            
            self.logger.info("New data detected for \(dataType.rawValue)")
            
            // Notify that new data is available
            self.observationHandler?(dataType)
            
            // Call completion handler to let HealthKit know we're done
            completionHandler()
        }
        
        observers.append(query)
        healthStore.execute(query)
    }
    
    private func startObservingCategoryType(_ categoryType: HKCategoryType, dataType: HealthDataType) {
        // Enable background delivery first
        healthStore.enableBackgroundDelivery(for: categoryType, frequency: .immediate) { [weak self] success, error in
            if let error = error {
                self?.logger.error("Failed to enable background delivery for \(dataType.rawValue): \(error.localizedDescription)")
            } else if success {
                self?.logger.info("Enabled background delivery for \(dataType.rawValue)")
            }
        }
        
        // Create observer query
        let query = HKObserverQuery(sampleType: categoryType, predicate: nil) { [weak self] _, completionHandler, error in
            guard let self = self else {
                completionHandler()
                return
            }
            
            if let error = error {
                self.logger.error("Observer query error for \(dataType.rawValue): \(error.localizedDescription)")
                completionHandler()
                return
            }
            
            self.logger.info("New data detected for \(dataType.rawValue)")
            
            // Notify that new data is available
            self.observationHandler?(dataType)
            
            // Call completion handler to let HealthKit know we're done
            completionHandler()
        }
        
        observers.append(query)
        healthStore.execute(query)
    }
    
    func setObservationHandler(_ handler: @escaping (HealthDataType) -> Void) {
        self.observationHandler = handler
    }
    
    // MARK: - Private Helper Methods
    
    private func getAuthorizationStatus(for type: HealthDataType) -> HKAuthorizationStatus {
        // Check cache first
        if let cached = authorizationCache[type],
           Date().timeIntervalSince(cached.timestamp) < authorizationCacheTimeout {
            return cached.status
        }
        
        // Fetch fresh status
        let status: HKAuthorizationStatus
        if let quantityTypeId = type.hkQuantityType,
           let quantityType = HKObjectType.quantityType(forIdentifier: quantityTypeId) {
            status = healthStore.authorizationStatus(for: quantityType)
        } else if type == .sleepAnalysis,
                  let categoryType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            status = healthStore.authorizationStatus(for: categoryType)
        } else {
            status = .notDetermined
        }
        
        // Update cache
        authorizationCache[type] = (status, Date())
        
        return status
    }
    
    func clearAuthorizationCache() {
        authorizationCache.removeAll()
        logger.info("Authorization cache cleared")
    }
    
    private func fetchSleepData(from startDate: Date, to endDate: Date, limit: Int = HKObjectQueryNoLimit) async throws -> [HealthDataSample] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.dataNotAvailable
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let healthDataSamples = samples.map { self.convertSleepSampleToHealthDataSample($0) }
                continuation.resume(returning: healthDataSamples)
            }
            
            healthStore.execute(query)
        }
    }
    
    private func convertToHealthDataSample(_ sample: HKQuantitySample, type: HealthDataType) -> HealthDataSample {
        let value = sample.quantity.doubleValue(for: type.unit)
        let unitString = type.unit.unitString
        
        var metadata: [String: String]?
        if let sampleMetadata = sample.metadata {
            metadata = sampleMetadata.compactMapValues { "\($0)" }
        }
        
        return HealthDataSample(
            id: UUID(uuidString: sample.uuid.uuidString) ?? UUID(),
            type: type,
            value: value,
            unit: unitString,
            startDate: sample.startDate,
            endDate: sample.endDate,
            sourceBundle: sample.sourceRevision.source.bundleIdentifier,
            metadata: metadata,
            isSynced: false,
            createdAt: Date()
        )
    }
    
    private func convertSleepSampleToHealthDataSample(_ sample: HKCategorySample) -> HealthDataSample {
        // Calculate duration in minutes
        let duration = sample.endDate.timeIntervalSince(sample.startDate) / 60.0
        
        var metadata: [String: String]?
        if let sampleMetadata = sample.metadata {
            metadata = sampleMetadata.compactMapValues { "\($0)" }
        }
        
        // Add sleep category value to metadata
        var enrichedMetadata = metadata ?? [:]
        enrichedMetadata["sleepCategory"] = sleepCategoryString(for: sample.value)
        
        return HealthDataSample(
            id: UUID(uuidString: sample.uuid.uuidString) ?? UUID(),
            type: .sleepAnalysis,
            value: duration,
            unit: "min",
            startDate: sample.startDate,
            endDate: sample.endDate,
            sourceBundle: sample.sourceRevision.source.bundleIdentifier,
            metadata: enrichedMetadata,
            isSynced: false,
            createdAt: Date()
        )
    }
    
    private func sleepCategoryString(for value: Int) -> String {
        switch value {
        case HKCategoryValueSleepAnalysis.inBed.rawValue:
            return "inBed"
        case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
            return "asleep"
        case HKCategoryValueSleepAnalysis.awake.rawValue:
            return "awake"
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
            return "asleepCore"
        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
            return "asleepDeep"
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
            return "asleepREM"
        default:
            return "unknown"
        }
    }
}
