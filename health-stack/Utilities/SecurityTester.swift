//
//  SecurityTester.swift
//  health-stack
//
//  Utility for testing security features
//

import Foundation
import os.log

/// Utility class for testing and validating security features
class SecurityTester {
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "health-stack", category: "SecurityTester")
    
    // MARK: - Comprehensive Security Test
    
    /// Run all security tests and return a detailed report
    func runAllSecurityTests() -> SecurityTestReport {
        logger.info("Running comprehensive security tests...")
        
        let keychainTest = testKeychainIntegration()
        let dataProtectionTest = testDataProtection()
        let httpsValidationTest = testHTTPSValidation()
        let certificatePinningTest = testCertificatePinning()
        
        let report = SecurityTestReport(
            keychainTest: keychainTest,
            dataProtectionTest: dataProtectionTest,
            httpsValidationTest: httpsValidationTest,
            certificatePinningTest: certificatePinningTest
        )
        
        logger.info("Security tests completed. Passed: \(report.passedCount)/\(report.totalTests)")
        
        return report
    }
    
    // MARK: - Individual Tests
    
    /// Test Keychain integration
    private func testKeychainIntegration() -> SecurityTestResult {
        logger.info("Testing Keychain integration...")
        
        let validator = SecurityValidator.shared
        let isAccessible = validator.validateKeychainAccess()
        
        return SecurityTestResult(
            name: "Keychain Integration",
            passed: isAccessible,
            message: isAccessible ? "Keychain is accessible and working correctly" : "Keychain access failed",
            details: isAccessible ? "Successfully saved, read, and deleted test data from Keychain" : "Unable to access Keychain. Check device passcode and app entitlements."
        )
    }
    
    /// Test Core Data encryption
    private func testDataProtection() -> SecurityTestResult {
        logger.info("Testing Data Protection...")
        
        let validator = SecurityValidator.shared
        let isProtected = validator.validateDataProtection()
        
        return SecurityTestResult(
            name: "Core Data Encryption",
            passed: isProtected,
            message: isProtected ? "Data protection is enabled" : "Data protection is not enabled",
            details: isProtected ? "Files are protected with FileProtectionType.complete" : "Unable to enable file protection. Check device passcode and iOS version."
        )
    }
    
    /// Test HTTPS validation
    private func testHTTPSValidation() -> SecurityTestResult {
        logger.info("Testing HTTPS validation...")
        
        let validator = SecurityValidator.shared
        
        // Test valid HTTPS URL
        do {
            try validator.validateHTTPS(urlString: "https://example.com")
        } catch {
            return SecurityTestResult(
                name: "HTTPS Validation",
                passed: false,
                message: "HTTPS validation failed for valid URL",
                details: "Error: \(error.localizedDescription)"
            )
        }
        
        // Test invalid HTTP URL (should fail)
        do {
            try validator.validateHTTPS(urlString: "http://example.com")
            return SecurityTestResult(
                name: "HTTPS Validation",
                passed: false,
                message: "HTTPS validation did not reject HTTP URL",
                details: "HTTP URLs should be rejected but were accepted"
            )
        } catch GatewayError.insecureConnection {
            // Expected error
            return SecurityTestResult(
                name: "HTTPS Validation",
                passed: true,
                message: "HTTPS validation working correctly",
                details: "Successfully validates HTTPS URLs and rejects HTTP URLs"
            )
        } catch {
            return SecurityTestResult(
                name: "HTTPS Validation",
                passed: false,
                message: "Unexpected error during HTTPS validation",
                details: "Error: \(error.localizedDescription)"
            )
        }
    }
    
    /// Test certificate pinning configuration
    private func testCertificatePinning() -> SecurityTestResult {
        logger.info("Testing Certificate Pinning configuration...")
        
        let validator = SecurityValidator.shared
        let initialState = validator.isCertificatePinningEnabled
        
        // Test enabling pinning
        validator.enableCertificatePinning(hashes: ["test_hash_1", "test_hash_2"])
        let enabledState = validator.isCertificatePinningEnabled
        
        // Test disabling pinning
        validator.disableCertificatePinning()
        let disabledState = validator.isCertificatePinningEnabled
        
        // Restore initial state
        if initialState {
            validator.enableCertificatePinning(hashes: ["restored"])
        }
        
        let passed = enabledState && !disabledState
        
        return SecurityTestResult(
            name: "Certificate Pinning",
            passed: passed,
            message: passed ? "Certificate pinning configuration working" : "Certificate pinning configuration failed",
            details: passed ? "Successfully enabled and disabled certificate pinning" : "Unable to configure certificate pinning correctly"
        )
    }
}

// MARK: - Test Results

struct SecurityTestResult {
    let name: String
    let passed: Bool
    let message: String
    let details: String
    
    var statusIcon: String {
        return passed ? "✓" : "✗"
    }
    
    var description: String {
        return "\(statusIcon) \(name): \(message)"
    }
}

struct SecurityTestReport {
    let keychainTest: SecurityTestResult
    let dataProtectionTest: SecurityTestResult
    let httpsValidationTest: SecurityTestResult
    let certificatePinningTest: SecurityTestResult
    
    var allTests: [SecurityTestResult] {
        return [keychainTest, dataProtectionTest, httpsValidationTest, certificatePinningTest]
    }
    
    var totalTests: Int {
        return allTests.count
    }
    
    var passedCount: Int {
        return allTests.filter { $0.passed }.count
    }
    
    var failedCount: Int {
        return totalTests - passedCount
    }
    
    var allPassed: Bool {
        return passedCount == totalTests
    }
    
    var description: String {
        var lines: [String] = []
        lines.append("=== Security Test Report ===")
        lines.append("")
        
        for test in allTests {
            lines.append(test.description)
            lines.append("  Details: \(test.details)")
            lines.append("")
        }
        
        lines.append("=== Summary ===")
        lines.append("Total Tests: \(totalTests)")
        lines.append("Passed: \(passedCount)")
        lines.append("Failed: \(failedCount)")
        lines.append("Status: \(allPassed ? "✓ ALL TESTS PASSED" : "✗ SOME TESTS FAILED")")
        
        return lines.joined(separator: "\n")
    }
}

