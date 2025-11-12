//
//  SecurityValidator.swift
//  health-stack
//
//  Security validation utilities for the app
//

import Foundation
import Security

/// Validates security configurations and provides security-related utilities
class SecurityValidator {
    
    static let shared = SecurityValidator()
    
    private init() {}
    
    // MARK: - Keychain Validation
    
    /// Verifies that Keychain is accessible and working correctly
    func validateKeychainAccess() -> Bool {
        let testKey = "security_test_key"
        let testValue = "test_value"
        let service = "com.healthstack.security.test"
        
        // Try to save a test value
        let saveQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: testKey,
            kSecValueData as String: testValue.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // Delete any existing test item
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: testKey
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Try to add
        let addStatus = SecItemAdd(saveQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            return false
        }
        
        // Try to read
        let readQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: testKey,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let readStatus = SecItemCopyMatching(readQuery as CFDictionary, &result)
        
        // Clean up
        SecItemDelete(deleteQuery as CFDictionary)
        
        return readStatus == errSecSuccess
    }
    
    // MARK: - Data Protection Validation
    
    /// Verifies that file protection is enabled for the app's data
    func validateDataProtection() -> Bool {
        // Check if device supports data protection
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        // Create a test file with protection
        let testFilePath = documentsPath.appendingPathComponent("security_test.dat")
        let testData = "test".data(using: .utf8)!
        
        do {
            try testData.write(to: testFilePath, options: .completeFileProtection)
            
            // Verify protection level
            let attributes = try FileManager.default.attributesOfItem(atPath: testFilePath.path)
            let protectionLevel = attributes[.protectionKey] as? FileProtectionType
            
            // Clean up
            try? FileManager.default.removeItem(at: testFilePath)
            
            return protectionLevel == .complete
        } catch {
            return false
        }
    }
    
    // MARK: - HTTPS Validation
    
    /// Validates that a URL uses HTTPS protocol
    func validateHTTPS(url: URL) throws {
        guard url.scheme?.lowercased() == "https" else {
            throw GatewayError.insecureConnection
        }
    }
    
    /// Validates that a URL string uses HTTPS protocol
    func validateHTTPS(urlString: String) throws {
        guard let url = URL(string: urlString) else {
            throw GatewayError.invalidConfiguration
        }
        try validateHTTPS(url: url)
    }
    
    // MARK: - Certificate Pinning
    
    /// Certificate pinning configuration for production environments
    /// Set this to your server's certificate public key hashes
    private var pinnedCertificateHashes: Set<String> = []
    
    /// Enable certificate pinning with the provided certificate hashes
    /// - Parameter hashes: SHA256 hashes of the pinned certificates
    func enableCertificatePinning(hashes: [String]) {
        pinnedCertificateHashes = Set(hashes)
    }
    
    /// Disable certificate pinning (for development/testing)
    func disableCertificatePinning() {
        pinnedCertificateHashes.removeAll()
    }
    
    /// Check if certificate pinning is enabled
    var isCertificatePinningEnabled: Bool {
        return !pinnedCertificateHashes.isEmpty
    }
    
    /// Validates server trust against pinned certificates
    /// - Parameters:
    ///   - serverTrust: The server trust to validate
    ///   - domain: The domain being validated
    /// - Returns: True if validation passes, false otherwise
    func validatePinnedCertificate(serverTrust: SecTrust, domain: String) -> Bool {
        // If pinning is not enabled, allow the connection
        guard isCertificatePinningEnabled else {
            return true
        }
        
        // Get the certificate chain
        guard let certificateChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] else {
            return false
        }
        
        // Check each certificate in the chain
        for certificate in certificateChain {
            guard let certificateData = SecCertificateCopyData(certificate) as Data? else {
                continue
            }
            
            // Calculate SHA256 hash
            let hash = sha256(data: certificateData)
            
            // Check if this hash is in our pinned set
            if pinnedCertificateHashes.contains(hash) {
                return true
            }
        }
        
        // No matching certificate found
        return false
    }
    
    /// Calculate SHA256 hash of data
    private func sha256(data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Security Report
    
    /// Generate a security status report
    func generateSecurityReport() -> SecurityReport {
        return SecurityReport(
            keychainAccessible: validateKeychainAccess(),
            dataProtectionEnabled: validateDataProtection(),
            certificatePinningEnabled: isCertificatePinningEnabled
        )
    }
}

// MARK: - Security Report

struct SecurityReport {
    let keychainAccessible: Bool
    let dataProtectionEnabled: Bool
    let certificatePinningEnabled: Bool
    
    var allSecurityFeaturesEnabled: Bool {
        return keychainAccessible && dataProtectionEnabled
    }
    
    var description: String {
        var lines: [String] = []
        lines.append("Security Status Report:")
        lines.append("- Keychain Access: \(keychainAccessible ? "✓" : "✗")")
        lines.append("- Data Protection: \(dataProtectionEnabled ? "✓" : "✗")")
        lines.append("- Certificate Pinning: \(certificatePinningEnabled ? "Enabled" : "Disabled")")
        return lines.joined(separator: "\n")
    }
}

// MARK: - CommonCrypto Import

import CommonCrypto

