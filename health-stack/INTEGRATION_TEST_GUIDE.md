# Integration Test Guide

This guide provides comprehensive testing procedures for the Health Data Kafka Gateway application.

## Overview

Task 19 focuses on final integration and testing to ensure all components work together correctly. This includes:

- Complete sync flow with real HealthKit data
- All health data types extraction
- Background sync with different frequencies
- Error scenarios (no network, invalid gateway, etc.)
- Permission flows (grant, deny, revoke)
- Data persistence and recovery
- HTTPS enforcement and security features
- Memory and battery usage verification

## Test Categories

### 1. HealthKit Data Extraction Tests

#### Test 1.1: Authorization Request
**Objective:** Verify HealthKit authorization works correctly

**Steps:**
1. Launch app for the first time
2. Navigate through onboarding
3. When prompted, grant HealthKit permissions
4. Verify authorization status is stored

**Expected Result:**
- Permission dialog appears
- App stores authorization status
- Settings screen shows granted permissions

**Requirements Tested:** 1.1, 1.2, 1.3

#### Test 1.2: All Data Types Extraction
**Objective:** Verify all supported health data types can be extracted

**Steps:**
1. Ensure you have health data in Health app for various types
2. Enable all data types in Settings
3. Trigger manual sync
4. Check sync history for data counts

**Data Types to Test:**
- Body Measurements: Height, Body Mass, BMI, Body Fat %, Waist Circumference
- Activity: Steps, Distance, Flights, Active Energy, Basal Energy, Exercise Time, Stand Hours
- Cardiovascular: Heart Rate, Resting HR, HRV, Blood Pressure, O2 Saturation
- Sleep: Sleep Analysis, Time in Bed
- Nutrition: Dietary Energy, Protein, Carbs, Fat, Water
- Respiratory: Respiratory Rate, VO2 Max
- Other: Blood Glucose, Body Temperature, Mindful Minutes

**Expected Result:**
- Each enabled data type is successfully extracted
- Data appears in sync history
- No extraction errors

**Requirements Tested:** 2.1, 2.3, 2.4, 2.5

#### Test 1.3: Date Range Queries
**Objective:** Verify data extraction respects date ranges

**Steps:**
1. Configure sync to fetch last 7 days
2. Trigger sync
3. Verify all samples are within date range

**Expected Result:**
- Only data from specified date range is fetched
- No samples outside the range

**Requirements Tested:** 3.1

### 2. Sync Flow Tests

#### Test 2.1: Complete Manual Sync
**Objective:** Verify end-to-end manual sync flow

**Steps:**
1. Configure valid gateway endpoint (HTTPS)
2. Enable desired data types
3. Tap "Sync Now" button
4. Monitor sync progress
5. Check sync history

**Expected Result:**
- Sync starts immediately
- Progress indicator shows activity
- Sync completes successfully
- History shows successful sync with timestamp
- Data is marked as synced in storage

**Requirements Tested:** 3.1, 5.1, 5.2, 5.3, 6.1, 6.2, 8.1, 8.2

#### Test 2.2: Automatic Sync - Real-time
**Objective:** Verify real-time sync works

**Steps:**
1. Set sync frequency to "Real-time"
2. Add new health data (e.g., log a workout)
3. Wait for background sync
4. Check sync history

**Expected Result:**
- New data triggers automatic sync
- Sync occurs within reasonable time
- History shows automatic sync

**Requirements Tested:** 3.1, 3.2, 10.3

#### Test 2.3: Automatic Sync - Hourly
**Objective:** Verify hourly sync scheduling

**Steps:**
1. Set sync frequency to "Hourly"
2. Wait for next hour boundary
3. Check sync history

**Expected Result:**
- Sync occurs approximately every hour
- Background task executes successfully

**Requirements Tested:** 3.2, 10.4

#### Test 2.4: Automatic Sync - Daily
**Objective:** Verify daily sync scheduling

**Steps:**
1. Set sync frequency to "Daily"
2. Wait for next scheduled time
3. Check sync history

**Expected Result:**
- Sync occurs once per day
- Background task executes successfully

**Requirements Tested:** 3.2, 10.4

### 3. Background Execution Tests

#### Test 3.1: Background Fetch
**Objective:** Verify app can sync in background

**Steps:**
1. Enable automatic sync
2. Put app in background
3. Wait for background task execution
4. Return to app and check history

**Expected Result:**
- Background task executes
- Data is synced while app is backgrounded
- History shows background sync

**Requirements Tested:** 3.2, 10.3, 10.4

#### Test 3.2: HealthKit Background Delivery
**Objective:** Verify HealthKit background updates work

**Steps:**
1. Enable real-time sync
2. Put app in background
3. Add health data via Health app or Apple Watch
4. Check if sync occurs

**Expected Result:**
- HealthKit notifies app of new data
- Background sync is triggered
- Data is sent to gateway

**Requirements Tested:** 3.1, 3.2

#### Test 3.3: Background Task Expiration
**Objective:** Verify app handles background task expiration

**Steps:**
1. Trigger background sync with large dataset
2. Monitor background task execution
3. Verify graceful handling if task expires

**Expected Result:**
- App saves progress before expiration
- Remaining data queued for next sync
- No data loss

**Requirements Tested:** 3.4

### 4. Network and Gateway Tests

#### Test 4.1: HTTPS Enforcement
**Objective:** Verify only HTTPS connections are allowed

**Steps:**
1. Try to configure HTTP gateway URL
2. Attempt to save configuration

**Expected Result:**
- HTTP URL is rejected
- Error message explains HTTPS requirement
- Configuration is not saved

**Requirements Tested:** 4.2, 7.2

#### Test 4.2: Valid HTTPS Configuration
**Objective:** Verify HTTPS URLs are accepted

**Steps:**
1. Configure gateway with HTTPS URL
2. Save configuration
3. Test connection

**Expected Result:**
- HTTPS URL is accepted
- Configuration is saved
- Connection test succeeds (if gateway is reachable)

**Requirements Tested:** 4.1, 4.2, 7.2

#### Test 4.3: SSL Certificate Validation
**Objective:** Verify SSL certificates are validated

**Steps:**
1. Configure gateway with valid HTTPS URL
2. Attempt connection
3. Monitor network layer behavior

**Expected Result:**
- SSL certificate is validated
- Invalid certificates are rejected
- Secure connection established

**Requirements Tested:** 7.3

#### Test 4.4: Invalid Gateway Handling
**Objective:** Verify app handles unreachable gateway

**Steps:**
1. Configure gateway with non-existent domain
2. Trigger sync
3. Observe error handling

**Expected Result:**
- Connection fails gracefully
- User-friendly error message displayed
- Data queued for retry

**Requirements Tested:** 4.4, 5.4, 9.1

#### Test 4.5: Network Timeout
**Objective:** Verify timeout handling

**Steps:**
1. Configure gateway with slow/unresponsive endpoint
2. Trigger sync
3. Wait for timeout

**Expected Result:**
- Request times out after configured duration
- Error message displayed
- Retry logic activated

**Requirements Tested:** 5.4, 5.5

#### Test 4.6: Retry with Exponential Backoff
**Objective:** Verify retry mechanism works

**Steps:**
1. Configure invalid gateway
2. Trigger sync
3. Monitor retry attempts

**Expected Result:**
- Multiple retry attempts with increasing delays
- Exponential backoff pattern (1s, 2s, 4s, 8s, 16s)
- Eventually gives up after max retries

**Requirements Tested:** 3.4, 5.5

### 5. Error Scenario Tests

#### Test 5.1: No Network Connection
**Objective:** Verify offline handling

**Steps:**
1. Enable Airplane Mode
2. Trigger sync
3. Observe behavior
4. Disable Airplane Mode
5. Check if sync resumes

**Expected Result:**
- Offline error displayed
- Data queued locally
- Automatic retry when network restored
- Queued data sent successfully

**Requirements Tested:** 3.4, 5.4, 5.5, 9.1

#### Test 5.2: Gateway Authentication Failure
**Objective:** Verify authentication error handling

**Steps:**
1. Configure gateway with invalid credentials
2. Trigger sync
3. Observe error

**Expected Result:**
- Authentication error displayed
- User prompted to check credentials
- Sync does not proceed

**Requirements Tested:** 4.4, 9.1

#### Test 5.3: Gateway Server Error
**Objective:** Verify server error handling

**Steps:**
1. Configure gateway that returns 500 error
2. Trigger sync
3. Observe behavior

**Expected Result:**
- Server error detected
- User-friendly error message
- Retry logic activated

**Requirements Tested:** 5.4, 9.1, 9.3

#### Test 5.4: Storage Full
**Objective:** Verify storage limit handling

**Steps:**
1. Fill device storage near capacity
2. Trigger sync with large dataset
3. Observe behavior

**Expected Result:**
- Storage error detected
- Old synced data automatically cleaned up
- Sync continues with available space

**Requirements Tested:** 9.4

### 6. Permission Flow Tests

#### Test 6.1: Grant Permissions
**Objective:** Verify permission grant flow

**Steps:**
1. Fresh install or reset permissions
2. Launch app
3. Go through onboarding
4. Grant all HealthKit permissions

**Expected Result:**
- Permission dialog appears
- All requested permissions granted
- App can access health data
- Settings show granted status

**Requirements Tested:** 1.1, 1.2, 1.3

#### Test 6.2: Deny Permissions
**Objective:** Verify permission denial handling

**Steps:**
1. Fresh install
2. Launch app
3. Deny HealthKit permissions

**Expected Result:**
- Informative message explains why permissions needed
- Link to Settings provided
- App gracefully handles denial
- Sync cannot proceed without permissions

**Requirements Tested:** 1.3, 1.4, 9.2

#### Test 6.3: Revoke Permissions
**Objective:** Verify permission revocation handling

**Steps:**
1. Grant permissions initially
2. Go to iOS Settings > Health > Data Access & Devices
3. Revoke permissions for app
4. Return to app and trigger sync

**Expected Result:**
- App detects revoked permissions
- User prompted to re-enable
- Link to Settings provided
- Sync cannot proceed

**Requirements Tested:** 1.4, 9.2

#### Test 6.4: Partial Permissions
**Objective:** Verify partial permission handling

**Steps:**
1. Grant some but not all HealthKit permissions
2. Enable all data types in app
3. Trigger sync

**Expected Result:**
- Only data with granted permissions is synced
- No errors for denied permissions
- User can see which permissions are missing

**Requirements Tested:** 1.2, 2.3, 2.4

### 7. Data Persistence and Recovery Tests

#### Test 7.1: Data Persistence
**Objective:** Verify data persists across app restarts

**Steps:**
1. Trigger sync
2. Force quit app
3. Relaunch app
4. Check sync history

**Expected Result:**
- Sync history persists
- Configuration persists
- Unsynced data persists

**Requirements Tested:** 5.4, 6.3

#### Test 7.2: Unsynced Data Recovery
**Objective:** Verify unsynced data is retried

**Steps:**
1. Trigger sync with invalid gateway
2. Verify data is stored locally
3. Configure valid gateway
4. Trigger sync again

**Expected Result:**
- Previously failed data is retried
- All data eventually synced
- No data loss

**Requirements Tested:** 5.4, 5.5

#### Test 7.3: Data Cleanup
**Objective:** Verify old data is cleaned up

**Steps:**
1. Sync data successfully
2. Wait for cleanup period (30 days)
3. Check storage

**Expected Result:**
- Old synced data is automatically deleted
- Recent data retained
- Storage space freed

**Requirements Tested:** 9.4

#### Test 7.4: App Uninstall
**Objective:** Verify data deletion on uninstall

**Steps:**
1. Sync some data
2. Uninstall app
3. Reinstall app

**Expected Result:**
- All local data deleted on uninstall
- Fresh start on reinstall
- No residual data

**Requirements Tested:** 7.4

### 8. Security Tests

#### Test 8.1: Credential Storage
**Objective:** Verify credentials stored securely

**Steps:**
1. Configure gateway with credentials
2. Save configuration
3. Verify credentials in Keychain (using Keychain Access or debugging)

**Expected Result:**
- Credentials stored in iOS Keychain
- Not stored in UserDefaults or plain text
- Encrypted at rest

**Requirements Tested:** 4.3, 7.1

#### Test 8.2: Data Encryption
**Objective:** Verify local data is encrypted

**Steps:**
1. Sync health data
2. Check Core Data storage
3. Verify encryption is enabled

**Expected Result:**
- Core Data uses Data Protection
- Data encrypted at rest
- Cannot be read without device unlock

**Requirements Tested:** 7.1, 7.2

#### Test 8.3: TLS/SSL Encryption
**Objective:** Verify data transmission is encrypted

**Steps:**
1. Configure HTTPS gateway
2. Trigger sync
3. Monitor network traffic (using proxy or network tools)

**Expected Result:**
- All traffic uses TLS/SSL
- Data encrypted in transit
- No plain text transmission

**Requirements Tested:** 5.2, 7.2, 7.3

#### Test 8.4: App Transport Security
**Objective:** Verify ATS configuration

**Steps:**
1. Check Info.plist for ATS settings
2. Attempt HTTP connection
3. Verify rejection

**Expected Result:**
- ATS enabled with no exceptions
- HTTP connections blocked
- Only HTTPS allowed

**Requirements Tested:** 7.2

### 9. Performance Tests

#### Test 9.1: Large Dataset Sync
**Objective:** Verify app handles large datasets

**Steps:**
1. Enable all data types
2. Sync 30 days of data
3. Monitor performance

**Expected Result:**
- Sync completes successfully
- No memory issues
- Reasonable completion time
- Data batching works correctly

**Requirements Tested:** 5.1, 9.4

#### Test 9.2: Memory Usage
**Objective:** Verify memory usage is reasonable

**Steps:**
1. Use Xcode Instruments
2. Run complete sync flow
3. Monitor memory allocation

**Expected Result:**
- Memory usage stays within limits
- No memory leaks
- Proper cleanup after sync

**Requirements Tested:** 9.4

#### Test 9.3: Battery Usage
**Objective:** Verify battery impact is minimal

**Steps:**
1. Enable automatic sync
2. Use app normally for 24 hours
3. Check battery usage in Settings

**Expected Result:**
- Battery usage is reasonable
- Background tasks don't drain battery
- Efficient sync scheduling

**Requirements Tested:** 10.3, 10.4

### 10. UI and User Experience Tests

#### Test 10.1: Loading States
**Objective:** Verify loading indicators work

**Steps:**
1. Trigger sync
2. Observe UI during sync

**Expected Result:**
- Loading indicator appears
- Sync button disabled during sync
- Progress feedback provided

**Requirements Tested:** 6.1, 6.2, 8.3

#### Test 10.2: Error Messages
**Objective:** Verify error messages are user-friendly

**Steps:**
1. Trigger various error scenarios
2. Read error messages

**Expected Result:**
- Clear, non-technical language
- Actionable guidance provided
- Appropriate error context

**Requirements Tested:** 9.1, 9.2, 9.3

#### Test 10.3: Accessibility
**Objective:** Verify VoiceOver support

**Steps:**
1. Enable VoiceOver
2. Navigate through app
3. Trigger sync

**Expected Result:**
- All elements have labels
- Navigation is logical
- Actions are announced

**Requirements Tested:** All UI requirements

## Automated Testing

### Running Integration Tests

The app includes an automated integration test suite accessible from the Settings screen:

1. Open Settings
2. Scroll to "Developer Tools" section
3. Tap "Run Integration Tests"
4. Review test results

### Test Categories in Automated Suite

- **HealthKit Tests:** Authorization, data extraction, date ranges
- **Storage Tests:** Save/retrieve, cleanup, persistence
- **Security Tests:** HTTPS enforcement, SSL validation
- **Sync Tests:** Complete sync flow, status tracking
- **Error Tests:** Invalid gateway, network errors
- **Permission Tests:** Authorization flows
- **Recovery Tests:** Unsynced data recovery

## Manual Testing Checklist

Use this checklist to ensure comprehensive testing:

- [ ] Fresh install and onboarding flow
- [ ] Grant all HealthKit permissions
- [ ] Configure valid HTTPS gateway
- [ ] Test manual sync with all data types
- [ ] Enable real-time sync and verify background updates
- [ ] Test hourly sync scheduling
- [ ] Test daily sync scheduling
- [ ] Put app in background and verify background sync
- [ ] Test with no network connection
- [ ] Test with invalid gateway configuration
- [ ] Test HTTP URL rejection
- [ ] Test HTTPS URL acceptance
- [ ] Deny permissions and verify handling
- [ ] Revoke permissions and verify detection
- [ ] Force quit and verify data persistence
- [ ] Trigger sync failure and verify retry
- [ ] Check sync history accuracy
- [ ] Verify old data cleanup
- [ ] Test with large dataset (30 days)
- [ ] Monitor memory usage with Instruments
- [ ] Check battery usage over 24 hours
- [ ] Test VoiceOver navigation
- [ ] Verify all error messages are clear
- [ ] Test on different iOS versions (16.0+)
- [ ] Test on different device sizes

## Performance Benchmarks

### Expected Performance

- **Authorization Request:** < 2 seconds
- **Data Extraction (1000 samples):** < 5 seconds
- **Network Request (100 samples):** < 3 seconds
- **Complete Sync (7 days data):** < 30 seconds
- **Background Task:** < 30 seconds
- **Memory Usage:** < 100 MB during sync
- **Battery Impact:** < 5% per day with hourly sync

### Performance Monitoring

Use Xcode Instruments to monitor:
- Time Profiler: CPU usage
- Allocations: Memory usage
- Leaks: Memory leaks
- Energy Log: Battery impact
- Network: Network activity

## Known Limitations

1. **HealthKit Simulator:** Limited health data in simulator, test on real device
2. **Background Tasks:** Difficult to test exact timing, use BGTaskScheduler debugging
3. **Network Conditions:** Use Network Link Conditioner for slow network testing
4. **Battery Testing:** Requires extended real-world usage

## Troubleshooting

### Tests Failing

**Issue:** HealthKit authorization fails
- **Solution:** Check Info.plist has usage descriptions
- **Solution:** Verify HealthKit capability is enabled

**Issue:** Network tests fail
- **Solution:** Check network connectivity
- **Solution:** Verify gateway is reachable
- **Solution:** Check firewall settings

**Issue:** Background tests don't run
- **Solution:** Use `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.app.healthsync"]` in debugger
- **Solution:** Verify background modes are enabled

### Performance Issues

**Issue:** Sync takes too long
- **Solution:** Check data batching is working
- **Solution:** Verify network speed
- **Solution:** Reduce date range

**Issue:** High memory usage
- **Solution:** Check for memory leaks
- **Solution:** Verify proper cleanup
- **Solution:** Reduce batch sizes

## Conclusion

This comprehensive test guide ensures all requirements are validated. Complete all test categories before considering the app production-ready.

For automated testing, use the built-in Integration Test suite. For manual testing, follow the checklist and verify all scenarios.

**All Requirements Tested:** 1.1-1.5, 2.1-2.6, 3.1-3.4, 4.1-4.4, 5.1-5.5, 6.1-6.4, 7.1-7.4, 8.1-8.4, 9.1-9.4, 10.1-10.4
