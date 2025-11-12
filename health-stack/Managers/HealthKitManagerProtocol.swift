//
//  HealthKitManagerProtocol.swift
//  health-stack
//

import Foundation

protocol HealthKitManagerProtocol {
    func requestAuthorization(for types: Set<HealthDataType>) async throws
    func fetchHealthData(type: HealthDataType, from: Date, to: Date) async throws -> [HealthDataSample]
    func fetchHealthData(type: HealthDataType, from: Date, to: Date, limit: Int) async throws -> [HealthDataSample]
    func startObservingHealthData(types: Set<HealthDataType>)
    func stopObservingHealthData()
    func clearAuthorizationCache()
}
