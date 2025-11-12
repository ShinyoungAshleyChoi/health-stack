# Project Setup Guide

This guide will help you complete the iOS project configuration for the Health Data Kafka Gateway app.

## Completed Setup

✅ Folder structure created:
- Models/
- ViewModels/
- Views/
- Services/
- Managers/
- Utilities/

✅ Info.plist created with:
- HealthKit usage descriptions
- Background modes configuration
- App Transport Security settings

✅ Entitlements file created with HealthKit capability

## Required Manual Configuration in Xcode

Please complete the following steps in Xcode:

### 1. Update Deployment Target to iOS 16.0

1. Open `health-stack.xcodeproj` in Xcode
2. Select the project in the navigator
3. Select the "health-stack" target
4. In the "General" tab, set "Minimum Deployments" to **iOS 16.0**

### 2. Link Info.plist File

1. In the project settings, select the "health-stack" target
2. Go to the "Build Settings" tab
3. Search for "Info.plist"
4. Set "Info.plist File" to: `health-stack/Info.plist`
5. Set "Generate Info.plist File" to **NO**

### 3. Link Entitlements File

1. In the project settings, select the "health-stack" target
2. Go to the "Build Settings" tab
3. Search for "Code Signing Entitlements"
4. Set the value to: `health-stack/health-stack.entitlements`

### 4. Enable HealthKit Capability

1. Select the "health-stack" target
2. Go to the "Signing & Capabilities" tab
3. Click the "+ Capability" button
4. Add "HealthKit"
5. Verify that the entitlements file is linked

### 5. Enable Background Modes

1. In the "Signing & Capabilities" tab
2. Click the "+ Capability" button
3. Add "Background Modes"
4. Check the following options:
   - ☑️ Background fetch
   - ☑️ Background processing

**Note**: HealthKit background delivery is enabled programmatically in the code, not through this capability setting.

### 6. Add HealthKit Framework

1. Select the "health-stack" target
2. Go to the "General" tab
3. Scroll to "Frameworks, Libraries, and Embedded Content"
4. Click the "+" button
5. Search for "HealthKit.framework"
6. Add it to the project

### 7. Verify Build Settings

Ensure the following build settings are configured:

- **Swift Language Version**: Swift 5.0
- **iOS Deployment Target**: 16.0
- **Enable Previews**: YES
- **Code Sign Style**: Automatic

### 8. Configure Background Task Identifiers

For background execution to work, you must register the background task identifier:

1. Select the "health-stack" target
2. Go to the "Info" tab
3. Add a new row with key: `BGTaskSchedulerPermittedIdentifiers`
4. Set type to **Array**
5. Add item with value: `com.healthstack.sync`

**Important**: This step is required for BGProcessingTask to work. Without it, background tasks will not execute.

### 9. Configure App Transport Security (ATS)

Since the app requires HTTPS-only connections, configure ATS in the project:

1. Select the "health-stack" target
2. Go to the "Info" tab
3. Add the following key-value pairs:
   - Key: `NSAppTransportSecurity` (Dictionary)
     - Key: `NSAllowsArbitraryLoads` (Boolean) = **NO**
     - Key: `NSAllowsLocalNetworking` (Boolean) = **NO** (for production)

**Note**: The NetworkClient class enforces HTTPS-only connections at the code level, but this ATS configuration provides an additional security layer at the system level.

## Verification

After completing the above steps:

1. Build the project (⌘+B) to ensure there are no errors
2. Verify that the Info.plist is properly linked
3. Verify that the entitlements file shows HealthKit capability
4. Check that Background Modes are enabled in capabilities
5. Verify App Transport Security settings are configured

## Background Execution Setup

For detailed information about background execution configuration and testing, see:
- **BACKGROUND_EXECUTION_SETUP.md** - Complete setup guide for background execution
- **BACKGROUND_EXECUTION_TEST_SCENARIOS.md** - Test scenarios and verification steps

Key points:
- Background tasks must be registered before app finishes launching (already implemented in code)
- HealthKit background delivery is enabled programmatically when real-time sync is selected
- Background execution must be tested on a physical device (not Simulator)
- Use debugger commands to simulate background task execution during development

## Next Steps

Once the project setup is complete, you can proceed to implement the next tasks:
- Task 2: Implement core data models and enums
- Task 3: Implement Configuration Manager
- And so on...

## Troubleshooting

### Issue: "HealthKit is not available on this device"
- Make sure you're testing on a real device or iOS Simulator with HealthKit support
- Verify that HealthKit capability is properly enabled

### Issue: "Background modes not working"
- Ensure all three background modes are checked in capabilities
- Verify Info.plist contains UIBackgroundModes array

### Issue: Build errors related to Info.plist
- Make sure GENERATE_INFOPLIST_FILE is set to NO
- Verify the Info.plist path is correct in build settings
