# Testing Quick Start Guide

Quick reference for running Task 19 integration tests.

## Automated Testing (Fastest)

### Run the Built-in Test Suite

1. **Open the app** on a real iOS device (iOS 16.0+)
2. **Navigate to Settings** screen
3. **Scroll down** to "Developer Tools" section
4. **Tap "Run Integration Tests"**
5. **Wait** for tests to complete (~30 seconds)
6. **Review results** in the test view

### What Gets Tested
- ✅ HealthKit authorization and data extraction
- ✅ Storage persistence and recovery
- ✅ HTTPS enforcement and security
- ✅ Complete sync flow
- ✅ Error handling scenarios
- ✅ Permission flows
- ✅ Data recovery

### Expected Results
- **Total Tests:** ~11 tests
- **Pass Rate:** > 80%
- **Duration:** < 30 seconds

---

## Manual Testing (Comprehensive)

### Essential Tests (30 minutes)

#### 1. First-Time User Flow (5 min)
```
1. Fresh install
2. Complete onboarding
3. Grant HealthKit permissions
4. Configure gateway (use HTTPS URL)
5. Trigger manual sync
6. Verify success in sync history
```

#### 2. All Data Types (10 min)
```
1. Open Settings
2. Enable all data type categories
3. Return to main screen
4. Trigger manual sync
5. Check sync history for data counts
6. Verify all types extracted
```

#### 3. Background Sync (10 min)
```
1. Set sync frequency to "Real-time"
2. Put app in background
3. Add health data (workout, water, etc.)
4. Wait 5 minutes
5. Return to app
6. Check sync history for background sync
```

#### 4. Error Handling (5 min)
```
1. Enable Airplane Mode
2. Trigger sync
3. Verify error message
4. Disable Airplane Mode
5. Verify automatic retry
6. Check sync succeeds
```

---

## Critical Security Tests (15 minutes)

### HTTPS Enforcement
```
1. Open gateway configuration
2. Try to enter: http://insecure.example.com
3. Attempt to save
4. Verify rejection with error message
5. Change to: https://secure.example.com
6. Verify acceptance
```

### Credential Security
```
1. Configure gateway with API key
2. Save configuration
3. Force quit app
4. Relaunch app
5. Verify credentials loaded
6. Trigger sync to verify they work
```

---

## Performance Tests (1 hour)

### Memory Usage (30 min)
```
1. Open Xcode
2. Product > Profile
3. Select "Allocations" instrument
4. Run app
5. Trigger sync with large dataset
6. Monitor memory usage
7. Verify < 100 MB
8. Check for leaks
```

### Battery Usage (24 hours)
```
1. Fully charge device
2. Enable hourly sync
3. Use device normally for 24 hours
4. Check Settings > Battery
5. Find app in battery usage
6. Verify < 5% usage
```

---

## Test Scenarios Reference

For detailed step-by-step instructions, see:

- **INTEGRATION_TEST_GUIDE.md** - Complete testing documentation
- **TEST_SCENARIOS.md** - 20 detailed test scenarios
- **TASK_19_COMPLETION_CHECKLIST.md** - Full completion checklist

---

## Quick Test Commands

### Simulate Background Task (Xcode Debugger)
```
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.app.healthsync"]
```

### Enable Network Link Conditioner
```
Settings > Developer > Network Link Conditioner
Select: 3G, LTE, or 100% Loss
```

---

## Common Issues

### Tests Failing?

**HealthKit Authorization Fails**
- Check Info.plist has NSHealthShareUsageDescription
- Verify HealthKit capability is enabled
- Test on real device (not simulator)

**Network Tests Fail**
- Check internet connectivity
- Verify gateway is reachable
- Check firewall settings

**Background Tests Don't Run**
- Use BGTaskScheduler debugger command
- Verify background modes enabled
- Check device isn't in Low Power Mode

---

## Test Results Checklist

### Automated Tests
- [ ] All tests executed
- [ ] Pass rate > 80%
- [ ] No crashes
- [ ] Results documented

### Manual Tests
- [ ] First-time user flow works
- [ ] All data types extract
- [ ] Background sync works
- [ ] Error handling graceful
- [ ] HTTPS enforced
- [ ] Permissions handled correctly

### Performance Tests
- [ ] Memory < 100 MB
- [ ] No memory leaks
- [ ] Battery < 5% per day
- [ ] Sync duration reasonable

---

## Success Criteria

✅ **All automated tests pass**
✅ **All manual scenarios pass**
✅ **No crashes during testing**
✅ **Performance benchmarks met**
✅ **Security requirements verified**
✅ **All requirements covered**

---

## Need Help?

### Documentation
- `INTEGRATION_TEST_GUIDE.md` - Full testing guide
- `TEST_SCENARIOS.md` - Detailed scenarios
- `TASK_19_COMPLETION_CHECKLIST.md` - Complete checklist

### Test Tools
- `IntegrationTester.swift` - Automated test suite
- `IntegrationTestView.swift` - Test UI

### Requirements
- `requirements.md` - All requirements
- `design.md` - System design
- `tasks.md` - Implementation tasks

---

## Ready to Test!

1. **Start with automated tests** (fastest validation)
2. **Run essential manual tests** (core functionality)
3. **Perform security tests** (critical for production)
4. **Run performance tests** (ensure quality)
5. **Document results** (track progress)

**Estimated Total Time:**
- Automated: 30 seconds
- Essential Manual: 30 minutes
- Security: 15 minutes
- Performance: 1 hour + 24 hours battery
- **Total Active Testing: ~2 hours**

Good luck with testing! 🚀
