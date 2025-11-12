//
//  ConfigurationManagerProtocol.swift
//  health-stack
//

import Foundation

protocol ConfigurationManagerProtocol {
    func saveGatewayConfig(_ config: GatewayConfig) throws
    func getGatewayConfig() throws -> GatewayConfig?
    func saveDataTypePreferences(_ preferences: [HealthDataType: Bool])
    func getDataTypePreferences() -> [HealthDataType: Bool]
    func saveSyncFrequency(_ frequency: SyncFrequency)
    func getSyncFrequency() -> SyncFrequency
    func saveUserId(_ userId: String)
    func getUserId() -> String?
    func clearConfigurationCache()
}
