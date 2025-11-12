# Security Features Documentation

This document describes the security features implemented in the health-stack application.

## Overview

The health-stack app implements multiple layers of security to protect sensitive health data:

1. **Keychain Integration** - Secure credential storage
2. **Core Data Encryption** - Encrypted local data storage
3. **App Transport Security** - HTTPS-only network communication
4. **SSL Certificate Validation** - Server identity verification
5. **Certificate Pinning** - Optional enhanced security for production
6. **Data Deletion on Uninstall** - Automatic cleanup

## 1. Keychain Integration

### Implementation
- Location: `ConfigurationManager.swift`
- Credentials stored: API keys, usernames, passwords
- Protection level: `kSecAttrAccessibleAfterFirstUnlock`

### What is Protected
- Gateway API keys
- Gateway usernames
- Gateway passwords

### Verification
```swift
// Test keychain access
let isAccessible = SecurityValidator.shared.validateKeychainAccess()
print("Keychain accessible: \(isAccessible)")
```

### Security Properties
- Data is encrypted by iOS
- Data is isolated per app (cannot be accessed by other apps)
- Data persists across app updates
- Data is automatically deleted when app is uninstalled
- Data is backed up to iCloud Keychain (if enabled by user)

## 2. Core Data Encryption

### Implementation
- Location: `StorageManager.swift`
- Protection type: `FileProtectionType.complete`
- Applies to: All health data and sync records

### What is Protected
- Health data samples (HealthDataEntity)
- Sync records (SyncRecordEntity)
- All Core Data persistent stores

### Code Reference
```swift
// In StorageManager.swift
let storeDescription = container.persistentStoreDescriptions.first
storeDescription?.setOption(
    FileProtectionType.complete as NSObject,
    forKey: NSPersistentStoreFileProtectionKey
)
```

### Security Properties
- Data is encrypted when device is locked
- Data is only accessible when device is unlocked
- Uses hardware encryption (Secure Enclave on supported devices)
- Automatic encryption/decryption by iOS
- Data is automatically deleted when app is uninstalled

### Verification
```swift
// Test data protection
let isProtected = SecurityValidator.shared.validateDataProtection()
print("Data protection enabled: \(isProtected)")
```

## 3. App Transport Security (ATS)

### Implementation
- Location: Xcode project build settings
- Configuration: `INFOPLIST_KEY_NSAppTransportSecurity`
- Default: HTTPS-only, no exceptions

### What is Protected
- All network communications
- Gateway API requests
- Connection tests

### Enforcement
The app enforces HTTPS at multiple levels:

1. **Configuration validation** (ConfigurationManager):
```swift
func saveGatewayConfig(_ config: GatewayConfig) throws {
    try config.validate() // Checks for HTTPS
}
```

2. **Network layer validation** (NetworkClient):
```swift
private func validateHTTPS(url: URL) throws {
    guard url.scheme?.lowercased() == "https" else {
        throw GatewayError.insecureConnection
    }
}
```

3. **iOS system level** (App Transport Security):
- Configured in build settings
- Enforced by iOS at runtime
- No HTTP connections allowed

### Current Configuration
```
INFOPLIST_KEY_UIBackgroundModes = "fetch processing"
// ATS is enabled by default with no exceptions
// All connections must use HTTPS with TLS 1.2+
```

## 4. SSL Certificate Validation

### Implementation
- Location: `NetworkClient.swift`
- Method: `URLSessionDelegate.urlSession(_:didReceive:completionHandler:)`

### What is Validated
- Server identity
- Certificate chain
- Certificate expiration
- Certificate revocation (via iOS)

### Code Reference
```swift
extension NetworkClient: URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Validates server trust
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Additional certificate pinning validation if enabled
        // ...
    }
}
```

### Security Properties
- Prevents man-in-the-middle attacks
- Validates certificate chain
- Checks certificate expiration
- Uses iOS system trust store

## 5. Certificate Pinning (Optional)

### Implementation
- Location: `SecurityValidator.swift` and `NetworkClient.swift`
- Status: **Disabled by default** (recommended for production)

### How to Enable

For production environments, enable certificate pinning:

```swift
// In your app initialization or configuration
let certificateHashes = [
    "sha256_hash_of_your_certificate_1",
    "sha256_hash_of_your_certificate_2"
]
SecurityValidator.shared.enableCertificatePinning(hashes: certificateHashes)
```

### How to Get Certificate Hash

```bash
# Get certificate from server
openssl s_client -connect your-gateway.com:443 -showcerts < /dev/null | openssl x509 -outform DER > cert.der

# Calculate SHA256 hash
openssl dgst -sha256 cert.der
```

### When to Use
- **Production environments**: Recommended for maximum security
- **Development/Testing**: Disable to allow self-signed certificates
- **Staging environments**: Optional, depends on security requirements

### Security Properties
- Prevents man-in-the-middle attacks even with compromised CAs
- Validates specific certificates, not just trust chain
- Requires manual updates when certificates change

## 6. Data Deletion on App Uninstall

### Automatic Deletion

iOS automatically deletes the following when the app is uninstalled:

1. **App Sandbox Data**
   - Core Data databases (health data, sync records)
   - UserDefaults (preferences, settings)
   - Documents directory
   - Caches directory
   - Temporary files

2. **Keychain Data**
   - API keys
   - Usernames
   - Passwords
   - All keychain items with the app's service identifier

### What is NOT Deleted

The following data may persist after uninstall:

1. **iCloud Keychain** (if user has iCloud Keychain enabled)
   - Keychain items may sync to other devices
   - User must manually delete from iCloud settings

2. **HealthKit Data**
   - Health data remains in HealthKit
   - Managed by iOS Health app
   - User must manually delete from Health app

### Verification

To verify data deletion:

1. Install the app
2. Configure gateway and sync some data
3. Check data exists:
   ```swift
   let hasData = try await StorageManager.shared.fetchUnsyncedData()
   print("Data count: \(hasData.count)")
   ```
4. Uninstall the app
5. Reinstall the app
6. Verify data is gone (app should show onboarding)

### Manual Cleanup (if needed)

If you need to manually clear data without uninstalling:

```swift
// Clear Core Data
let context = StorageManager.shared.viewContext
// Delete all entities...

// Clear UserDefaults
UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)

// Clear Keychain
// Use ConfigurationManager's deleteFromKeychain methods
```

## Security Validation

### Running Security Checks

Use the SecurityValidator to check security status:

```swift
let report = SecurityValidator.shared.generateSecurityReport()
print(report.description)
```

Output:
```
Security Status Report:
- Keychain Access: ✓
- Data Protection: ✓
- Certificate Pinning: Disabled
```

### Integration in App

You can add security validation to your app startup:

```swift
// In health_stackApp.swift or MainViewModel
func validateSecurity() {
    let report = SecurityValidator.shared.generateSecurityReport()
    
    if !report.keychainAccessible {
        // Handle keychain access issue
        print("Warning: Keychain not accessible")
    }
    
    if !report.dataProtectionEnabled {
        // Handle data protection issue
        print("Warning: Data protection not enabled")
    }
}
```

## Security Best Practices

### For Development
1. Use HTTPS even for local testing (use self-signed certificates)
2. Keep certificate pinning disabled
3. Test with real devices (not simulator) for full security features
4. Regularly test data deletion

### For Production
1. **Enable certificate pinning** with your production certificates
2. Use strong API keys (minimum 32 characters, random)
3. Rotate credentials regularly
4. Monitor for security updates
5. Keep iOS deployment target up to date

### For Users
1. Keep device updated to latest iOS version
2. Use device passcode/biometric authentication
3. Enable automatic app updates
4. Review app permissions regularly

## Compliance

### HIPAA Considerations

This app implements security controls that support HIPAA compliance:

- ✓ Encryption at rest (Core Data with FileProtection)
- ✓ Encryption in transit (HTTPS/TLS)
- ✓ Access controls (iOS device authentication)
- ✓ Audit logging (sync records)
- ✓ Data integrity (SSL certificate validation)

**Note**: Full HIPAA compliance requires additional organizational and technical controls beyond the app itself.

### GDPR Considerations

- ✓ Data minimization (user selects data types)
- ✓ Right to erasure (data deleted on uninstall)
- ✓ Data portability (JSON export format)
- ✓ Consent management (explicit permissions)
- ✓ Security measures (encryption, HTTPS)

## Troubleshooting

### "Keychain access failed"
- Check device has passcode enabled
- Verify app is signed correctly
- Check entitlements file includes keychain access

### "Data protection not available"
- Device must have passcode/biometric authentication enabled
- Test on real device (not simulator)
- Check iOS version (iOS 16.0+)

### "SSL validation failed"
- Verify server certificate is valid
- Check certificate expiration date
- Ensure server supports TLS 1.2+
- If using certificate pinning, verify hashes are correct

### "Insecure connection error"
- Verify gateway URL uses HTTPS (not HTTP)
- Check for typos in URL
- Ensure port is correct (typically 443 for HTTPS)

## References

- [Apple Security Documentation](https://developer.apple.com/documentation/security)
- [App Transport Security](https://developer.apple.com/documentation/bundleresources/information_property_list/nsapptransportsecurity)
- [Data Protection](https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy/encrypting_your_app_s_files)
- [Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
- [Certificate Pinning](https://developer.apple.com/news/?id=g9ejcf8y)

