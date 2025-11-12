# Background Execution - Quick Start Guide

## TL;DR - Get Background Execution Working

### 1. Configure Xcode (5 minutes)

#### Add Background Task Identifier to Info.plist
1. Open Xcode project
2. Select target → Info tab
3. Add new row:
   - Key: `BGTaskSchedulerPermittedIdentifiers` (Array)
   - Add item: `com.healthstack.sync`

#### Enable Background Modes
1. Select target → Signing & Capabilities
2. Add "Background Modes" capability
3. Check:
   - ✅ Background fetch
   - ✅ Background processing

### 2. Build and Run on Physical Device

**IMPORTANT**: Background execution does NOT work in Simulator!

```bash
# Build for device
# Connect iPhone via USB
# Select your device in Xcode
# Press Cmd+R to build and run
```

### 3. Test Background Sync

#### Test Scheduled Sync (Hourly/Daily)
1. Launch app
2. Complete onboarding
3. Set sync frequency to "Hourly"
4. In Xcode debugger console, run:
   ```
   e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.healthstack.sync"]
   ```
5. Check logs for: `"Background sync completed successfully"`

#### Test Real-time Sync
1. Set sync frequency to "Real-time"
2. Stop the app in Xcode (Cmd+.)
3. Open Health app on device
4. Add health data (e.g., steps)
5. On your Mac, monitor logs:
   ```bash
   log stream --predicate 'subsystem == "com.healthstack"' --level debug
   ```
6. Look for: `"New data detected for [dataType]"`

### 4. Verify It's Working

Check for these log messages:

```
✅ "Registered background task: com.healthstack.sync"
✅ "Scheduled health sync task for Xs from now"
✅ "Enabled background delivery for [dataType]"
✅ "Background health sync task started"
✅ "Background sync completed successfully"
```

## Common Issues

### "Background task not registered"
→ Add `BGTaskSchedulerPermittedIdentifiers` to Info.plist

### "Background modes not working"
→ Enable Background Modes capability in Xcode

### "Task not executing"
→ Use debugger command to force execution during testing

### "HealthKit not waking app"
→ Ensure real-time sync is enabled and permissions are granted

## What Each Sync Frequency Does

| Frequency | Background Execution | Battery Impact | Data Freshness |
|-----------|---------------------|----------------|----------------|
| Real-time | HealthKit background delivery | High | Immediate |
| Hourly | BGProcessingTask every hour | Medium | 1 hour delay |
| Daily | BGProcessingTask every 24 hours | Low | 24 hour delay |
| Manual | None | None | User-controlled |

## Quick Debug Commands

```bash
# Stream all app logs
log stream --predicate 'subsystem == "com.healthstack"' --level debug

# Filter background task logs
log stream --predicate 'subsystem == "com.healthstack" AND category == "BackgroundTaskManager"' --level debug

# Save logs to file
log stream --predicate 'subsystem == "com.healthstack"' --level debug > logs.txt
```

## Need More Details?

- **Setup**: See `BACKGROUND_EXECUTION_SETUP.md`
- **Testing**: See `BACKGROUND_EXECUTION_TEST_SCENARIOS.md`
- **Implementation**: See `TASK_15_IMPLEMENTATION_SUMMARY.md`

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      health_stackApp                         │
│  (Registers background tasks on app launch)                  │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  BackgroundTaskManager                       │
│  • Registers BGProcessingTask                                │
│  • Schedules background sync                                 │
│  • Handles task execution and expiration                     │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                      SyncManager                             │
│  • Performs sync operations                                  │
│  • Manages sync queue                                        │
│  • Handles retry logic                                       │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   HealthKitManager                           │
│  • Enables background delivery                               │
│  • Observes health data changes                              │
│  • Fetches new health data                                   │
└─────────────────────────────────────────────────────────────┘
```

## Files You Need to Know About

- `BackgroundTaskManager.swift` - Manages background tasks
- `SyncManager.swift` - Orchestrates sync operations
- `HealthKitManager.swift` - Handles HealthKit background delivery
- `health_stackApp.swift` - Registers tasks on launch

## That's It!

You now have background execution working. The app will:
- ✅ Sync in the background based on selected frequency
- ✅ Wake up when new health data is available (real-time mode)
- ✅ Retry failed syncs automatically
- ✅ Handle network interruptions gracefully

Happy coding! 🚀
