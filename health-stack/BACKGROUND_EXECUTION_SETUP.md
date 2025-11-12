# Background Execution Setup Guide

This guide explains how to configure the iOS project to enable background execution for health data synchronization.

## Overview

The app uses two mechanisms for background execution:
1. **BGProcessingTask** - For scheduled background sync operations
2. **HealthKit Background Delivery** - For real-time health data updates

## Required Configuration

### 1. Info.plist Configuration

Add the following keys to your `Info.plist` file (or configure in Xcode project settings):

#### Background Modes

Enable the following background modes:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>processing</string>
    <string>remote-notification</string>
</array>
```

**In Xcode:**
1. Select your target
2. Go to "Signing & Capabilities" tab
3. Click "+ Capability" and add "Background Modes"
4. Check the following boxes:
   - ✅ Background fetch
   - ✅ Background processing
   - ✅ Remote notifications (optional, for future push notification support)

#### Background Task Scheduler Identifiers

Register the background task identifier:

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.healthstack.sync</string>
</array>
```

**In Xcode:**
1. Select your target
2. Go to "Info" tab
3. Add a new row with key `BGTaskSchedulerPermittedIdentifiers`
4. Set type to `Array`
5. Add item: `com.healthstack.sync`

#### HealthKit Usage Descriptions

Ensure these are already configured (should be present):

```xml
<key>NSHealthShareUsageDescription</key>
<string>We need access to your health data to sync it with your personal health dashboard.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>This app does not write health data to HealthKit.</string>
```

### 2. Capabilities Configuration

#### HealthKit Capability

Already configured in `health-stack.entitlements`:

```xml
<key>com.apple.developer.healthkit</key>
<true/>
<key>com.apple.developer.healthkit.access</key>
<array/>
```

**Verify in Xcode:**
1. Select your target
2. Go to "Signing & Capabilities" tab
3. Ensure "HealthKit" capability is present

### 3. App Transport Security (ATS)

For secure HTTPS-only communication (already enforced in code):

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>
```

This ensures all network requests use HTTPS.

## How Background Execution Works

### 1. Scheduled Background Sync

When the user selects hourly or daily sync frequency:

- The app schedules a `BGProcessingTask` with the identifier `com.healthstack.sync`
- iOS will wake the app in the background at appropriate times
- The app performs a full sync operation
- After completion, the next background task is scheduled

**Limitations:**
- iOS decides when to actually run the task (not guaranteed to run at exact time)
- Tasks may be delayed if device is low on battery
- Tasks may not run if the app hasn't been used recently

### 2. Real-time Sync with HealthKit Background Delivery

When the user selects real-time sync frequency:

- The app enables HealthKit background delivery for all selected data types
- When new health data is added to HealthKit, iOS wakes the app
- The app fetches the new data and syncs it immediately
- This works even when the app is completely closed

**Limitations:**
- Requires HealthKit authorization
- Only works for data types the user has granted permission for
- May be throttled by iOS to preserve battery

### 3. Foreground Sync

When the app is in the foreground:

- A timer triggers periodic syncs based on the selected frequency
- Manual sync can be triggered by the user at any time
- No iOS limitations apply

## Testing Background Execution

### Testing BGProcessingTask

You cannot test background tasks by simply waiting - iOS will not run them during development. Use these methods:

#### Method 1: Xcode Debugger Commands

1. Run the app in Xcode
2. Trigger a sync to schedule the background task
3. Pause the app in the debugger
4. In the LLDB console, run:
   ```
   e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.healthstack.sync"]
   ```
5. Resume the app - the background task will execute

#### Method 2: Scheme Configuration

1. Edit your scheme (Product > Scheme > Edit Scheme)
2. Select "Run" on the left
3. Go to "Options" tab
4. Check "Background Fetch" or "Background Processing"
5. This will simulate background launches during development

### Testing HealthKit Background Delivery

1. Run the app and enable real-time sync
2. Grant HealthKit permissions
3. Stop the app in Xcode (don't just background it - actually stop debugging)
4. Use the Health app or another app to add health data
5. Check the device logs to see if your app was woken up:
   ```
   log stream --predicate 'subsystem == "com.healthstack"' --level debug
   ```

### Testing in Simulator

**Important:** Background tasks and HealthKit background delivery do NOT work reliably in the iOS Simulator. You must test on a physical device.

## Monitoring Background Execution

### Logging

The app uses `os.log` for logging. To view logs:

```bash
# On device
log stream --predicate 'subsystem == "com.healthstack"' --level debug

# Or filter by category
log stream --predicate 'subsystem == "com.healthstack" AND category == "BackgroundTaskManager"' --level debug
```

### Key Log Messages

- `"Registered background task: com.healthstack.sync"` - Task registered successfully
- `"Scheduled health sync task for Xs from now"` - Background task scheduled
- `"Background health sync task started"` - Background task is executing
- `"Background sync completed successfully in Xs"` - Sync completed
- `"Background task expired, cancelling sync operation"` - Task ran out of time
- `"Enabled background delivery for [dataType]"` - HealthKit background delivery enabled
- `"New data detected for [dataType]"` - HealthKit notified app of new data

## Troubleshooting

### Background Tasks Not Running

1. **Check if task is registered:**
   - Look for log message: `"Registered background task: com.healthstack.sync"`
   - Verify `BGTaskSchedulerPermittedIdentifiers` in Info.plist

2. **Check if task is scheduled:**
   - Look for log message: `"Scheduled health sync task for Xs from now"`
   - Verify sync frequency is set to hourly or daily (not manual)

3. **iOS may delay or skip tasks:**
   - Use the device regularly to show iOS the app is important
   - Keep the device charged
   - Use the debugger commands to force execution during testing

### HealthKit Background Delivery Not Working

1. **Check permissions:**
   - Ensure HealthKit authorization is granted
   - Check authorization status in Settings > Health > Data Access & Devices

2. **Check if background delivery is enabled:**
   - Look for log message: `"Enabled background delivery for [dataType]"`
   - Verify real-time sync is enabled in app settings

3. **Check if observers are running:**
   - Look for log message: `"Started observing X health data types"`
   - Verify data types are selected in app settings

### App Not Waking Up

1. **Verify background modes are enabled:**
   - Check Xcode project settings under "Signing & Capabilities"
   - Ensure "Background fetch" and "Background processing" are checked

2. **Check device restrictions:**
   - Low Power Mode disables background execution
   - Background App Refresh must be enabled in Settings
   - Check Settings > General > Background App Refresh

3. **Test on physical device:**
   - Background execution is unreliable in Simulator
   - Always test on a real iPhone

## Performance Considerations

### Battery Impact

- Real-time sync uses more battery than scheduled sync
- Hourly sync is a good balance between freshness and battery life
- Daily sync is most battery-efficient
- Manual sync gives users complete control

### Network Usage

- Background tasks require network connectivity
- Large amounts of health data may use significant data
- Consider implementing data compression for future optimization

### Background Execution Time Limits

- BGProcessingTask has approximately 30 seconds to complete
- If sync takes longer, it will be terminated
- The app implements proper cleanup on expiration
- Failed syncs are queued and retried later

## Best Practices

1. **Always call completion handlers:**
   - HealthKit observer queries must call `completionHandler()`
   - Background tasks must call `task.setTaskCompleted(success:)`

2. **Handle task expiration:**
   - Set `task.expirationHandler` to clean up gracefully
   - Cancel ongoing operations when expiration occurs

3. **Schedule next task:**
   - After completing a background task, schedule the next one
   - This ensures continuous background sync

4. **Test thoroughly:**
   - Test on physical devices, not just Simulator
   - Test with different sync frequencies
   - Test with various health data types
   - Test with network interruptions

5. **Monitor battery usage:**
   - Use Xcode's Energy Log to monitor impact
   - Optimize sync frequency based on user needs
   - Provide clear information about battery impact

## Future Enhancements

Potential improvements for background execution:

1. **Adaptive sync frequency:**
   - Adjust sync frequency based on data availability
   - Reduce frequency when no new data is detected

2. **Intelligent scheduling:**
   - Sync during optimal times (e.g., when device is charging)
   - Avoid syncing during active use

3. **Data compression:**
   - Compress payloads before transmission
   - Reduce network usage and sync time

4. **Differential sync:**
   - Only sync changed data
   - Reduce processing time and network usage

5. **Push notifications:**
   - Notify users of sync status
   - Alert on sync failures

## References

- [Apple Documentation: Background Execution](https://developer.apple.com/documentation/uikit/app_and_environment/scenes/preparing_your_ui_to_run_in_the_background)
- [Apple Documentation: BGTaskScheduler](https://developer.apple.com/documentation/backgroundtasks/bgtaskscheduler)
- [Apple Documentation: HealthKit Background Delivery](https://developer.apple.com/documentation/healthkit/hkhealthstore/1614175-enablebackgrounddelivery)
- [WWDC 2019: Advances in Background Execution](https://developer.apple.com/videos/play/wwdc2019/707/)
