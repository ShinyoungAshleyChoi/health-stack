# Background Execution Test Scenarios

This document outlines test scenarios for verifying background execution functionality.

## Prerequisites

Before testing, ensure:
1. ✅ Background modes are enabled in Xcode project settings
2. ✅ `BGTaskSchedulerPermittedIdentifiers` is configured in Info.plist
3. ✅ Testing on a physical iOS device (not Simulator)
4. ✅ HealthKit permissions are granted
5. ✅ Gateway is configured with valid HTTPS endpoint
6. ✅ Background App Refresh is enabled in device Settings

## Test Scenario 1: BGProcessingTask - Hourly Sync

**Objective:** Verify that scheduled background tasks execute correctly for hourly sync.

### Setup
1. Launch the app
2. Complete onboarding
3. Configure gateway with valid HTTPS endpoint
4. Select at least one health data type
5. Set sync frequency to "Hourly"
6. Perform initial manual sync to verify gateway connectivity

### Test Steps

#### Step 1: Schedule Background Task
1. Ensure sync frequency is set to "Hourly"
2. Check logs for: `"Scheduled health sync task for 3600s from now"`
3. ✅ **Expected:** Task is scheduled successfully

#### Step 2: Simulate Background Task (Debugger Method)
1. Keep app running in Xcode
2. Open LLDB console
3. Run command:
   ```
   e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.healthstack.sync"]
   ```
4. Check logs for:
   - `"Background health sync task started"`
   - `"Background sync completed successfully in Xs"`
5. ✅ **Expected:** Background task executes and completes

#### Step 3: Verify Sync Results
1. Check sync history in the app
2. Verify new sync record was created
3. Check that timestamp matches background execution time
4. ✅ **Expected:** Sync record shows successful background sync

#### Step 4: Verify Task Rescheduling
1. After background task completes, check logs
2. Look for: `"Scheduled health sync task for 3600s from now"`
3. ✅ **Expected:** Next background task is scheduled automatically

### Success Criteria
- ✅ Background task is scheduled
- ✅ Background task executes when simulated
- ✅ Sync completes successfully
- ✅ Next task is rescheduled
- ✅ Sync history is updated

---

## Test Scenario 2: BGProcessingTask - Daily Sync

**Objective:** Verify that scheduled background tasks work for daily sync frequency.

### Setup
1. Launch the app
2. Set sync frequency to "Daily"
3. Verify gateway configuration

### Test Steps

#### Step 1: Schedule Background Task
1. Set sync frequency to "Daily"
2. Check logs for: `"Scheduled health sync task for 86400s from now"`
3. ✅ **Expected:** Task is scheduled with 24-hour interval

#### Step 2: Simulate Background Task
1. Use debugger command to simulate task launch
2. Verify task executes successfully
3. ✅ **Expected:** Background sync completes

#### Step 3: Verify Interval
1. Check that next task is scheduled for 24 hours later
2. ✅ **Expected:** Correct interval is maintained

### Success Criteria
- ✅ Daily interval is correctly configured (86400s)
- ✅ Background task executes successfully
- ✅ Next task is rescheduled with correct interval

---

## Test Scenario 3: HealthKit Background Delivery - Real-time Sync

**Objective:** Verify that HealthKit background delivery wakes the app when new health data is available.

### Setup
1. Launch the app
2. Set sync frequency to "Real-time"
3. Grant HealthKit permissions for at least one data type (e.g., Step Count)
4. Verify gateway configuration

### Test Steps

#### Step 1: Enable Background Delivery
1. Set sync frequency to "Real-time"
2. Check logs for: `"Enabled background delivery for [dataType]"`
3. Check logs for: `"Started observing X health data types"`
4. ✅ **Expected:** Background delivery is enabled for all selected data types

#### Step 2: Add Health Data While App is Closed
1. **IMPORTANT:** Stop the app in Xcode (don't just background it)
2. Open the Health app on the device
3. Manually add a health data entry (e.g., add steps)
4. Wait 1-2 minutes for HealthKit to process

#### Step 3: Monitor Device Logs
1. On your Mac, run:
   ```bash
   log stream --predicate 'subsystem == "com.healthstack"' --level debug
   ```
2. Look for:
   - `"New data detected for [dataType]"`
   - `"Starting manual sync"`
   - `"Manual sync completed: X samples synced"`
3. ✅ **Expected:** App is woken up and syncs new data

#### Step 4: Verify in App
1. Launch the app
2. Check sync history
3. Verify that a sync occurred while app was closed
4. ✅ **Expected:** Sync record shows background sync with correct timestamp

### Success Criteria
- ✅ Background delivery is enabled
- ✅ App wakes up when new health data is added
- ✅ New data is synced automatically
- ✅ Sync history reflects background sync

---

## Test Scenario 4: Background Task Expiration Handling

**Objective:** Verify that the app handles background task expiration gracefully.

### Setup
1. Launch the app
2. Configure for hourly sync
3. Prepare to simulate a long-running sync

### Test Steps

#### Step 1: Simulate Task Expiration
1. Set a breakpoint in `BackgroundTaskManager.handleHealthSyncTask`
2. Simulate background task launch
3. When task starts, wait for expiration handler to be called
4. Check logs for: `"Background task expired, cancelling sync operation"`
5. ✅ **Expected:** Expiration is handled gracefully

#### Step 2: Verify Cleanup
1. Verify that sync operation is cancelled
2. Check that `task.setTaskCompleted(success: false)` is called
3. ✅ **Expected:** Task completes with failure status

#### Step 3: Verify Retry
1. Check that failed data is added to sync queue
2. Verify that next sync attempt will retry failed data
3. ✅ **Expected:** Failed data is queued for retry

### Success Criteria
- ✅ Expiration handler is called
- ✅ Sync operation is cancelled
- ✅ Task completes with failure status
- ✅ Failed data is queued for retry

---

## Test Scenario 5: Network Restoration and Retry

**Objective:** Verify that the app retries failed syncs when network is restored.

### Setup
1. Launch the app
2. Configure for real-time or hourly sync
3. Ensure some health data is available

### Test Steps

#### Step 1: Simulate Network Failure
1. Enable Airplane Mode on device
2. Trigger a manual sync
3. Verify sync fails with network error
4. Check logs for: `"Sync attempt X failed, retrying in Ys"`
5. ✅ **Expected:** Sync fails and data is queued

#### Step 2: Restore Network
1. Disable Airplane Mode
2. Post network restoration notification (automatic in app)
3. Check logs for: `"Network restored, processing sync queue"`
4. ✅ **Expected:** Queued data is automatically synced

#### Step 3: Verify Sync Success
1. Check sync history
2. Verify that previously failed data was synced
3. ✅ **Expected:** All data is successfully synced after network restoration

### Success Criteria
- ✅ Failed syncs are queued
- ✅ Network restoration triggers retry
- ✅ Queued data is successfully synced
- ✅ Sync history reflects retry attempts

---

## Test Scenario 6: Multiple Data Types Background Sync

**Objective:** Verify that background sync works correctly with multiple health data types.

### Setup
1. Launch the app
2. Enable multiple data types from different categories:
   - Body Measurements: Body Mass
   - Activity: Step Count
   - Cardiovascular: Heart Rate
   - Sleep: Sleep Analysis
3. Set sync frequency to "Real-time"

### Test Steps

#### Step 1: Verify All Types Are Observed
1. Check logs for each data type
2. Look for: `"Enabled background delivery for [dataType]"`
3. ✅ **Expected:** All selected types have background delivery enabled

#### Step 2: Add Data for Multiple Types
1. Stop the app
2. Add health data for multiple types (use Health app or fitness tracker)
3. Monitor device logs

#### Step 3: Verify Multi-Type Sync
1. Check that app wakes up for each data type
2. Verify all new data is synced
3. ✅ **Expected:** App handles multiple data types correctly

### Success Criteria
- ✅ All data types have background delivery enabled
- ✅ App wakes up for each data type
- ✅ All data is synced correctly
- ✅ No data loss or duplication

---

## Test Scenario 7: Sync Frequency Changes

**Objective:** Verify that changing sync frequency properly updates background execution.

### Setup
1. Launch the app
2. Start with "Hourly" sync frequency

### Test Steps

#### Step 1: Change from Hourly to Real-time
1. Set sync frequency to "Real-time"
2. Check logs for:
   - `"Auto sync stopped"` (old mode)
   - `"Cancelled all background tasks"`
   - `"Starting auto sync with frequency: Real-time"`
   - `"Enabled background delivery for [dataType]"`
3. ✅ **Expected:** Smooth transition to real-time mode

#### Step 2: Change from Real-time to Daily
1. Set sync frequency to "Daily"
2. Check logs for:
   - `"Auto sync stopped"`
   - `"Stopped all health data observation"`
   - `"Starting auto sync with frequency: Daily"`
   - `"Scheduled health sync task for 86400s from now"`
3. ✅ **Expected:** Smooth transition to daily mode

#### Step 3: Change to Manual
1. Set sync frequency to "Manual Only"
2. Check logs for:
   - `"Auto sync stopped"`
   - `"Cancelled all background tasks"`
   - `"Manual sync mode - no automatic sync scheduled"`
3. ✅ **Expected:** All background execution is disabled

### Success Criteria
- ✅ Old mode is properly stopped
- ✅ New mode is properly started
- ✅ No orphaned observers or tasks
- ✅ Correct background execution for each mode

---

## Test Scenario 8: App Lifecycle and Background Execution

**Objective:** Verify background execution works across different app states.

### Setup
1. Launch the app
2. Configure for hourly sync
3. Ensure health data is available

### Test Steps

#### Step 1: App in Foreground
1. Keep app in foreground
2. Wait for scheduled sync (or trigger manually)
3. ✅ **Expected:** Sync works normally

#### Step 2: App in Background
1. Press home button to background the app
2. Wait for scheduled sync time
3. Check device logs
4. ✅ **Expected:** Background task executes

#### Step 3: App Terminated by User
1. Swipe up to terminate the app
2. Wait for scheduled sync time
3. Check device logs
4. ✅ **Expected:** Background task still executes (iOS may delay)

#### Step 4: App Terminated by System
1. Launch app
2. Launch many other apps to force system to terminate
3. Wait for scheduled sync time
4. ✅ **Expected:** Background task executes when scheduled

### Success Criteria
- ✅ Sync works in foreground
- ✅ Sync works when backgrounded
- ✅ Sync works after user termination
- ✅ Sync works after system termination

---

## Test Scenario 9: Battery and Performance Impact

**Objective:** Measure battery and performance impact of background execution.

### Setup
1. Fully charge device
2. Configure app with different sync frequencies
3. Use device normally for 24 hours

### Test Steps

#### Test 1: Real-time Sync
1. Enable real-time sync
2. Use device normally for 24 hours
3. Check battery usage in Settings > Battery
4. Note percentage used by health-stack app
5. ✅ **Expected:** Reasonable battery usage (< 5% for typical use)

#### Test 2: Hourly Sync
1. Enable hourly sync
2. Use device normally for 24 hours
3. Check battery usage
4. ✅ **Expected:** Lower battery usage than real-time

#### Test 3: Daily Sync
1. Enable daily sync
2. Use device normally for 24 hours
3. Check battery usage
4. ✅ **Expected:** Minimal battery usage

### Success Criteria
- ✅ Battery usage is acceptable for each mode
- ✅ Real-time uses more battery than scheduled
- ✅ Daily sync has minimal impact
- ✅ No excessive CPU usage

---

## Test Scenario 10: Error Handling in Background

**Objective:** Verify that errors during background execution are handled properly.

### Setup
1. Launch the app
2. Configure for hourly sync

### Test Steps

#### Test 1: Gateway Unreachable
1. Configure invalid gateway URL
2. Simulate background task
3. Check logs for error handling
4. ✅ **Expected:** Error is logged, data is queued

#### Test 2: HealthKit Permission Revoked
1. Revoke HealthKit permissions in Settings
2. Simulate background task
3. Check logs for authorization error
4. ✅ **Expected:** Error is handled gracefully

#### Test 3: Storage Full
1. Fill device storage (difficult to test)
2. Attempt background sync
3. ✅ **Expected:** Error is handled, old data is cleaned up

### Success Criteria
- ✅ Errors don't crash the app
- ✅ Errors are logged properly
- ✅ Failed data is queued for retry
- ✅ User is notified of persistent errors

---

## Debugging Tips

### View Real-time Logs

```bash
# Stream all app logs
log stream --predicate 'subsystem == "com.healthstack"' --level debug

# Filter by category
log stream --predicate 'subsystem == "com.healthstack" AND category == "BackgroundTaskManager"' --level debug

# Save logs to file
log stream --predicate 'subsystem == "com.healthstack"' --level debug > health-stack-logs.txt
```

### Check Background Task Status

In Xcode debugger console:
```
# List all pending background tasks
po BGTaskScheduler.shared

# Check if task is registered
po BGTaskScheduler.shared.getPendingTaskRequests { tasks in print(tasks) }
```

### Verify Configuration

Add this to a debug menu in your app:
```swift
#if DEBUG
BackgroundExecutionTester.printConfigurationStatus()
#endif
```

### Common Issues

1. **Task not running:**
   - Check Info.plist configuration
   - Verify background modes are enabled
   - Test on physical device, not Simulator
   - Use debugger command to force execution

2. **HealthKit not waking app:**
   - Verify permissions are granted
   - Check that background delivery is enabled
   - Ensure app hasn't been force-quit recently
   - Test with different data types

3. **Sync failing in background:**
   - Check network connectivity
   - Verify gateway configuration
   - Check logs for specific errors
   - Ensure HTTPS is used (not HTTP)

## Reporting Results

For each test scenario, document:
- ✅ Pass / ❌ Fail
- Actual behavior observed
- Any errors or warnings in logs
- Screenshots or log excerpts
- Device model and iOS version
- Any deviations from expected behavior

## Automated Testing

While background execution is difficult to test automatically, you can create unit tests for:
- BackgroundTaskManager registration
- SyncManager background sync logic
- HealthKitManager observer setup
- Error handling and retry logic

See `health-stackTests/` for test examples.
