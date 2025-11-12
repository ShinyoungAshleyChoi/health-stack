//
//  ConfigurationManager.swift
//  health-stack
//

import Foundation
import Security

class ConfigurationManager: ConfigurationManagerProtocol {
    
    // MARK: - Constants
    
    private enum UserDefaultsKeys {
        static let gatewayBaseURL = "gateway_base_url"
        static let gatewayPort = "gateway_port"
        static let dataTypePreferences = "data_type_preferences"
        static let syncFrequency = "sync_frequency"
        static let userId = "user_id"
    }
    
    private enum KeychainKeys {
        static let apiKey = "gateway_api_key"
        static let username = "gateway_username"
        static let password = "gateway_password"
    }
    
    private let userDefaults: UserDefaults
    private let keychainService = "com.healthstack.gateway"
    
    // Cache for configuration
    private var gatewayConfigCache: (config: GatewayConfig?, timestamp: Date)?
    private var dataTypePreferencesCache: (preferences: [HealthDataType: Bool], timestamp: Date)?
    private let configCacheTimeout: TimeInterval = 60 // 1 minute
    
    // MARK: - Initialization
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Gateway Configuration
    
    // Default gateway configuration
    private let defaultGatewayConfig = GatewayConfig(
        baseURL: "https://localhost",
        port: 8080,
        apiKey: "default-api-key",
        username: nil,
        password: nil
    )
    
    func saveGatewayConfig(_ config: GatewayConfig) throws {
        // Validate HTTPS requirement
        try config.validate()
        
        // Save non-sensitive data to UserDefaults
        userDefaults.set(config.baseURL, forKey: UserDefaultsKeys.gatewayBaseURL)
        
        if let port = config.port {
            userDefaults.set(port, forKey: UserDefaultsKeys.gatewayPort)
        } else {
            userDefaults.removeObject(forKey: UserDefaultsKeys.gatewayPort)
        }
        
        // Save credentials to Keychain
        if let apiKey = config.apiKey {
            try saveToKeychain(key: KeychainKeys.apiKey, value: apiKey)
        } else {
            try deleteFromKeychain(key: KeychainKeys.apiKey)
        }
        
        if let username = config.username {
            try saveToKeychain(key: KeychainKeys.username, value: username)
        } else {
            try deleteFromKeychain(key: KeychainKeys.username)
        }
        
        if let password = config.password {
            try saveToKeychain(key: KeychainKeys.password, value: password)
        } else {
            try deleteFromKeychain(key: KeychainKeys.password)
        }
        
        // Invalidate cache
        gatewayConfigCache = nil
    }
    
    func getGatewayConfig() throws -> GatewayConfig? {
        // Check cache first
        if let cached = gatewayConfigCache,
           Date().timeIntervalSince(cached.timestamp) < configCacheTimeout {
            return cached.config
        }
        
        // Check if user has saved a custom configuration
        let config: GatewayConfig?
        if let baseURL = userDefaults.string(forKey: UserDefaultsKeys.gatewayBaseURL) {
            let port = userDefaults.object(forKey: UserDefaultsKeys.gatewayPort) as? Int
            let apiKey = try? loadFromKeychain(key: KeychainKeys.apiKey)
            let username = try? loadFromKeychain(key: KeychainKeys.username)
            let password = try? loadFromKeychain(key: KeychainKeys.password)
            
            config = GatewayConfig(
                baseURL: baseURL,
                port: port,
                apiKey: apiKey,
                username: username,
                password: password
            )
        } else {
            // Return default configuration
            config = defaultGatewayConfig
        }
        
        // Update cache
        gatewayConfigCache = (config, Date())
        
        return config
    }
    
    // MARK: - Data Type Preferences
    
    func saveDataTypePreferences(_ preferences: [HealthDataType: Bool]) {
        let encodedPreferences = preferences.mapKeys { $0.rawValue }
        userDefaults.set(encodedPreferences, forKey: UserDefaultsKeys.dataTypePreferences)
        
        // Invalidate cache
        dataTypePreferencesCache = nil
    }
    
    func getDataTypePreferences() -> [HealthDataType: Bool] {
        // Check cache first
        if let cached = dataTypePreferencesCache,
           Date().timeIntervalSince(cached.timestamp) < configCacheTimeout {
            return cached.preferences
        }
        
        let preferences: [HealthDataType: Bool]
        
        guard let savedPreferences = userDefaults.dictionary(forKey: UserDefaultsKeys.dataTypePreferences) as? [String: Bool] else {
            // Return default preferences (all enabled)
            preferences = Dictionary(uniqueKeysWithValues: HealthDataType.allCases.map { ($0, true) })
            dataTypePreferencesCache = (preferences, Date())
            return preferences
        }
        
        var loadedPreferences: [HealthDataType: Bool] = [:]
        for (key, value) in savedPreferences {
            if let dataType = HealthDataType(rawValue: key) {
                loadedPreferences[dataType] = value
            }
        }
        
        // Add any missing data types with default value true
        for dataType in HealthDataType.allCases {
            if loadedPreferences[dataType] == nil {
                loadedPreferences[dataType] = true
            }
        }
        
        // Update cache
        dataTypePreferencesCache = (loadedPreferences, Date())
        
        return loadedPreferences
    }
    
    func clearConfigurationCache() {
        gatewayConfigCache = nil
        dataTypePreferencesCache = nil
    }
    
    // MARK: - Sync Frequency
    
    func saveSyncFrequency(_ frequency: SyncFrequency) {
        userDefaults.set(frequency.rawValue, forKey: UserDefaultsKeys.syncFrequency)
    }
    
    func getSyncFrequency() -> SyncFrequency {
        guard let rawValue = userDefaults.string(forKey: UserDefaultsKeys.syncFrequency),
              let frequency = SyncFrequency(rawValue: rawValue) else {
            return .manual // Default to manual sync
        }
        return frequency
    }
    
    // MARK: - User ID
    
    func saveUserId(_ userId: String) {
        userDefaults.set(userId, forKey: UserDefaultsKeys.userId)
    }
    
    func getUserId() -> String? {
        return userDefaults.string(forKey: UserDefaultsKeys.userId)
    }
    
    // MARK: - Keychain Helpers
    
    private func saveToKeychain(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw StorageError.saveFailed(NSError(domain: "ConfigurationManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode value"]))
        }
        
        // Delete existing item first
        try? deleteFromKeychain(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw StorageError.saveFailed(NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to save to Keychain"]))
        }
    }
    
    private func loadFromKeychain(key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw StorageError.fetchFailed(NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to load from Keychain"]))
        }
        
        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw StorageError.fetchFailed(NSError(domain: "ConfigurationManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode value"]))
        }
        
        return value
    }
    
    private func deleteFromKeychain(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        // Ignore error if item doesn't exist
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw StorageError.saveFailed(NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to delete from Keychain"]))
        }
    }
}

// MARK: - Dictionary Extension

private extension Dictionary {
    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        return Dictionary<T, Value>(uniqueKeysWithValues: map { (transform($0.key), $0.value) })
    }
}
