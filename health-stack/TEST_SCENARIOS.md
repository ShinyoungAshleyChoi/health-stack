# Test Scenarios

Detailed test scenarios for final integration testing (Task 19).

## Scenario 1: First-Time User Complete Flow

**Objective:** Test the complete user journey from installation to first successful sync

### Steps:
1. Install app on device with health data
2. Launch app for first time
3. Complete onboarding:
   - Read welcome screen
   - Grant HealthKit permissions (all types)
   - Configure gateway (HTTPS URL, credentials)
   - Select data types to sync
4. Reach main screen
5. Trigger manual sync
6. Verify sync completes successfully
7. Check sync history

### Expected Results:
- Onboarding flow is smooth and intuitive
- All permissions granted successfully
- Gateway configuration saved securely
- First sync completes without errors
- Sync history shows successful sync with timestamp
- Data appears in gateway/Kafka

### Requirements: 1.1, 1.2, 1.3, 1.5, 2.1, 2.2, 2.3, 4.1, 4.2, 4.3, 5.1, 5.2, 5.3, 6.1, 6.2, 8.1, 8.2

---

## Scenario 2: All Health Data Types Extraction

**Objective:** Verify all 30+ health data types can be extracted and synced

### Prerequisites:
- Device has sample data for all health types (use Health app to add test data)
- App has all HealthKit permissions

### Steps:
1. Open Settings
2. Enable all data type categories:
   - Body Measurements (5 types)
   - Activity (7 types)
   - Cardiovascular (6 types)
   - Sleep (2 types)
   - Nutrition (5 types)
   - Respiratory (2 types)
   - Other (3 types)
3. Return to main screen
4. Trigger manual sync
5. Monitor sync progress
6. Check sync history for details

### Expected Results:
- All enabled data types are extracted
- Each type shows sample count in logs
- No extraction errors
- Sync completes successfully
- Data payload includes all types

### Data Types to Verify:
```
Body Measurements:
✓ Height
✓ Body Mass
✓ Body Mass Index
✓ Body Fat Percentage
✓ Waist Circumference

Activity:
✓ Step Count
✓ Distance Walking/Running
✓ Flights Climbed
✓ Active Energy Burned
✓ Basal Energy Burned
✓ Exercise Time
✓ Stand Hours

Cardiovascular:
✓ Heart Rate
✓ Resting Heart Rate
✓ Heart Rate Variability
✓ Blood Pressure Systolic
✓ Blood Pressure Diastolic
✓ Oxygen Saturation

Sleep:
✓ Sleep Analysis
✓ Time in Bed

Nutrition:
✓ Dietary Energy
✓ Dietary Protein
✓ Dietary Carbohydrates
✓ Dietary Fat
✓ Dietary Water

Respiratory:
✓ Respiratory Rate
✓ VO2 Max

Other:
✓ Blood Glucose
✓ Body Temperature
✓ Mindful Minutes
```

### Requirements: 2.1, 2.3, 2.4, 2.5, 2.6

---

## Scenario 3: Background Sync - Real-time Mode

**Objective:** Verify real-time background sync works correctly

### Prerequisites:
- App configured with valid gateway
- Real-time sync enabled
- HealthKit permissions granted

### Steps:
1. Set sync frequency to "Real-time"
2. Put app in background (home button or swipe up)
3. Add new health data:
   - Log a workout in Fitness app
   - Add water intake in Health app
   - Record mindful minutes
4. Wait 5-10 minutes
5. Return to app
6. Check sync history

### Expected Results:
- HealthKit background delivery triggers sync
- New data is synced automatically
- Sync history shows background sync entries
- No user interaction required
- Battery impact is minimal

### Requirements: 3.1, 3.2, 10.3

---

## Scenario 4: Background Sync - Hourly Mode

**Objective:** Verify hourly background sync scheduling

### Prerequisites:
- App configured with valid gateway
- Hourly sync enabled

### Steps:
1. Set sync frequency to "Hourly"
2. Note current time
3. Put app in background
4. Wait for next hour boundary + 5 minutes
5. Return to app
6. Check sync history

### Expected Results:
- Background task executes approximately every hour
- Sync history shows hourly sync entries
- Background processing task registered correctly
- Sync completes within 30 seconds

### Debugging:
Use this lldb command to simulate background task:
```
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.app.healthsync"]
```

### Requirements: 3.2, 10.4

---

## Scenario 5: Background Sync - Daily Mode

**Objective:** Verify daily background sync scheduling

### Prerequisites:
- App configured with valid gateway
- Daily sync enabled

### Steps:
1. Set sync frequency to "Daily"
2. Note current time
3. Put app in background
4. Wait 24 hours (or simulate with debugger)
5. Return to app
6. Check sync history

### Expected Results:
- Background task executes once per day
- Sync history shows daily sync entry
- Consistent timing each day
- Efficient battery usage

### Requirements: 3.2, 10.4

---

## Scenario 6: No Network Connection

**Objective:** Verify app handles offline state gracefully

### Steps:
1. Enable Airplane Mode on device
2. Open app
3. Trigger manual sync
4. Observe error handling
5. Check that data is queued locally
6. Disable Airplane Mode
7. Wait for automatic retry or trigger manual sync
8. Verify queued data is sent

### Expected Results:
- Clear "No network connection" error message
- Sync button shows appropriate state
- Data is saved locally for later sync
- When network restored, automatic retry occurs
- All queued data syncs successfully
- No data loss

### Requirements: 3.4, 5.4, 5.5, 9.1

---

## Scenario 7: Invalid Gateway Configuration

**Objective:** Verify handling of unreachable or invalid gateway

### Steps:
1. Configure gateway with non-existent domain:
   - URL: `https://invalid-gateway-12345.example.com`
   - Port: 9999
   - API Key: `test-key`
2. Save configuration
3. Test connection
4. Observe error
5. Trigger sync
6. Check error handling and retry logic

### Expected Results:
- Connection test fails with clear error
- User-friendly error message displayed
- Sync fails gracefully
- Retry logic activates with exponential backoff
- Data queued for later retry
- User can reconfigure gateway

### Requirements: 4.4, 5.4, 5.5, 9.1

---

## Scenario 8: HTTPS Enforcement

**Objective:** Verify only HTTPS connections are allowed

### Steps:
1. Open gateway configuration
2. Attempt to enter HTTP URL:
   - URL: `http://insecure.example.com`
   - Port: 8080
3. Try to save configuration
4. Observe validation error
5. Change to HTTPS URL:
   - URL: `https://secure.example.com`
   - Port: 443
6. Save configuration
7. Verify acceptance

### Expected Results:
- HTTP URL is rejected immediately
- Clear error message: "Only HTTPS connections are allowed"
- Configuration cannot be saved with HTTP
- HTTPS URL is accepted
- Configuration saves successfully
- App Transport Security enforced

### Requirements: 4.2, 7.2, 7.3

---

## Scenario 9: Permission Denial and Recovery

**Objective:** Verify app handles permission denial gracefully

### Steps:
1. Fresh install or reset permissions
2. Launch app
3. Go through onboarding
4. When HealthKit permission dialog appears, tap "Don't Allow"
5. Observe app behavior
6. Navigate to Settings screen
7. Tap "Open Health Settings"
8. Grant permissions in iOS Settings
9. Return to app
10. Trigger sync

### Expected Results:
- Clear message explains why permissions needed
- Link to iOS Settings provided
- App doesn't crash or hang
- After granting permissions, app detects change
- Sync works after permissions granted
- User experience is smooth

### Requirements: 1.3, 1.4, 9.2

---

## Scenario 10: Permission Revocation

**Objective:** Verify app detects and handles permission revocation

### Steps:
1. App working normally with permissions granted
2. Go to iOS Settings > Health > Data Access & Devices
3. Find the app
4. Turn off all data access
5. Return to app
6. Trigger sync
7. Observe error handling

### Expected Results:
- App detects revoked permissions
- Clear error message displayed
- User prompted to re-enable permissions
- Link to Settings provided
- Sync cannot proceed without permissions
- No crash or data corruption

### Requirements: 1.4, 9.2

---

## Scenario 11: Data Persistence and Recovery

**Objective:** Verify data persists and recovers correctly

### Steps:
1. Configure gateway with invalid URL
2. Trigger sync (will fail)
3. Verify data is stored locally as unsynced
4. Force quit app (swipe up in app switcher)
5. Relaunch app
6. Check sync history (should show failed sync)
7. Reconfigure gateway with valid URL
8. Trigger sync again
9. Verify previously failed data is now synced

### Expected Results:
- Failed sync data persists locally
- App state persists across restarts
- Sync history persists
- Configuration persists
- Unsynced data is retried on next sync
- All data eventually synced
- No data loss

### Requirements: 5.4, 5.5, 6.3

---

## Scenario 12: Large Dataset Sync

**Objective:** Verify app handles large datasets efficiently

### Prerequisites:
- Device with 30+ days of health data
- Multiple data types with frequent samples (e.g., heart rate every minute)

### Steps:
1. Enable all data types
2. Configure sync to fetch last 30 days
3. Trigger manual sync
4. Monitor:
   - Memory usage (Xcode Instruments)
   - Sync duration
   - Progress updates
5. Verify completion

### Expected Results:
- Sync completes successfully
- Memory usage stays under 100 MB
- Data is batched (max 100 samples per request)
- Progress updates shown
- No memory leaks
- Reasonable completion time (< 2 minutes)
- All data synced correctly

### Requirements: 5.1, 9.4

---

## Scenario 13: Retry with Exponential Backoff

**Objective:** Verify retry mechanism works correctly

### Steps:
1. Configure gateway that returns 500 error
2. Trigger sync
3. Monitor retry attempts with timestamps
4. Observe backoff pattern

### Expected Results:
- First retry after 1 second
- Second retry after 2 seconds
- Third retry after 4 seconds
- Fourth retry after 8 seconds
- Fifth retry after 16 seconds
- Eventually gives up after max retries
- User notified of failure
- Data queued for later retry

### Requirements: 3.4, 5.5

---

## Scenario 14: Credential Security

**Objective:** Verify credentials are stored securely

### Steps:
1. Configure gateway with credentials:
   - API Key: `secret-api-key-12345`
   - Or Username/Password
2. Save configuration
3. Force quit app
4. Use Keychain Access (on Mac) or debugging to verify storage
5. Relaunch app
6. Verify credentials are loaded correctly
7. Trigger sync to verify credentials work

### Expected Results:
- Credentials stored in iOS Keychain
- Not visible in UserDefaults
- Not stored in plain text
- Credentials persist across app restarts
- Credentials encrypted at rest
- Credentials used correctly in API requests

### Requirements: 4.3, 7.1

---

## Scenario 15: Data Encryption

**Objective:** Verify local data is encrypted

### Steps:
1. Sync health data
2. Check Core Data storage location
3. Verify Data Protection is enabled
4. Lock device
5. Try to access data (should fail)
6. Unlock device
7. Access data (should succeed)

### Expected Results:
- Core Data uses Data Protection
- Data encrypted at rest
- Cannot access data when device locked
- Data accessible when device unlocked
- Encryption transparent to user

### Requirements: 7.1, 7.2

---

## Scenario 16: App Uninstall Data Cleanup

**Objective:** Verify data is deleted on app uninstall

### Steps:
1. Sync some health data
2. Note data stored locally
3. Uninstall app
4. Reinstall app
5. Launch app

### Expected Results:
- All local data deleted on uninstall
- Fresh onboarding on reinstall
- No residual data
- Clean slate for new user

### Requirements: 7.4

---

## Scenario 17: Memory and Performance

**Objective:** Verify memory usage and performance are acceptable

### Tools:
- Xcode Instruments (Time Profiler, Allocations, Leaks)

### Steps:
1. Launch Instruments
2. Run app with Time Profiler
3. Perform complete sync flow
4. Monitor:
   - CPU usage
   - Memory allocations
   - Memory leaks
   - Network activity
5. Run Leaks instrument
6. Check for memory leaks

### Expected Results:
- CPU usage reasonable during sync
- Memory usage < 100 MB
- No memory leaks detected
- Proper cleanup after sync
- Efficient network usage
- No blocking operations on main thread

### Requirements: 9.4

---

## Scenario 18: Battery Usage

**Objective:** Verify battery impact is minimal

### Steps:
1. Fully charge device
2. Enable hourly automatic sync
3. Use device normally for 24 hours
4. Check battery usage:
   - Settings > Battery
   - Find app in battery usage list
5. Note percentage

### Expected Results:
- Battery usage < 5% per day
- Background sync doesn't drain battery
- Efficient scheduling
- No excessive wake-ups
- Reasonable for health monitoring app

### Requirements: 10.3, 10.4

---

## Scenario 19: Accessibility with VoiceOver

**Objective:** Verify app is accessible with VoiceOver

### Steps:
1. Enable VoiceOver (Settings > Accessibility > VoiceOver)
2. Navigate through app:
   - Main screen
   - Settings screen
   - Gateway configuration
   - Sync history
3. Trigger sync with VoiceOver
4. Listen to announcements

### Expected Results:
- All buttons have accessibility labels
- All text is readable
- Navigation is logical
- Actions are announced
- Sync status announced
- Error messages announced
- Full functionality with VoiceOver

### Requirements: All UI requirements

---

## Scenario 20: Error Message Quality

**Objective:** Verify all error messages are user-friendly

### Errors to Test:
1. No network connection
2. Invalid gateway URL
3. Authentication failure
4. Server error (500)
5. Timeout
6. HealthKit permission denied
7. HealthKit permission revoked
8. Storage full
9. Invalid configuration

### Expected Results:
- Clear, non-technical language
- Explains what went wrong
- Provides actionable next steps
- Appropriate tone (helpful, not alarming)
- Consistent formatting
- No technical jargon

### Requirements: 9.1, 9.2, 9.3

---

## Test Execution Checklist

### Pre-Testing Setup
- [ ] Device with iOS 16.0+
- [ ] Health app populated with sample data
- [ ] Valid test gateway endpoint available
- [ ] Xcode Instruments ready for performance testing
- [ ] Network Link Conditioner configured for network testing

### Core Functionality
- [ ] Scenario 1: First-time user flow
- [ ] Scenario 2: All data types extraction
- [ ] Scenario 12: Large dataset sync

### Background Execution
- [ ] Scenario 3: Real-time background sync
- [ ] Scenario 4: Hourly background sync
- [ ] Scenario 5: Daily background sync

### Error Handling
- [ ] Scenario 6: No network connection
- [ ] Scenario 7: Invalid gateway
- [ ] Scenario 13: Retry with backoff
- [ ] Scenario 20: Error message quality

### Security
- [ ] Scenario 8: HTTPS enforcement
- [ ] Scenario 14: Credential security
- [ ] Scenario 15: Data encryption
- [ ] Scenario 16: Uninstall cleanup

### Permissions
- [ ] Scenario 9: Permission denial
- [ ] Scenario 10: Permission revocation

### Data Management
- [ ] Scenario 11: Data persistence and recovery

### Performance
- [ ] Scenario 17: Memory and performance
- [ ] Scenario 18: Battery usage

### Accessibility
- [ ] Scenario 19: VoiceOver support

---

## Success Criteria

All scenarios must pass with:
- ✅ No crashes
- ✅ No data loss
- ✅ No memory leaks
- ✅ Acceptable performance
- ✅ User-friendly error messages
- ✅ Secure data handling
- ✅ Proper background execution
- ✅ Full accessibility support

## Reporting

Document results for each scenario:
- Pass/Fail status
- Actual vs expected results
- Screenshots of issues
- Performance metrics
- Any deviations from requirements

---

**All Requirements Covered:** 1.1-1.5, 2.1-2.6, 3.1-3.4, 4.1-4.4, 5.1-5.5, 6.1-6.4, 7.1-7.4, 8.1-8.4, 9.1-9.4, 10.1-10.4
