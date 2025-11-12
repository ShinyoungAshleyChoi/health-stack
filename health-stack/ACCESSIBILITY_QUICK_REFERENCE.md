# Accessibility Quick Reference

Quick reference guide for developers working on the Health Sync app.

## Using Accessibility Identifiers

```swift
// Import the identifiers
import AccessibilityIdentifiers

// Use in views
.accessibilityIdentifier(AccessibilityIdentifiers.MainView.syncButton)
```

### Available Identifiers

**Main View:**
- `MainView.syncStatusCard`
- `MainView.syncButton`
- `MainView.settingsButton`
- `MainView.historyButton`

**Settings View:**
- `SettingsView.syncFrequencyPicker`
- `SettingsView.categoryToggle`
- `SettingsView.dataTypeToggle`
- `SettingsView.saveButton`

**Onboarding View:**
- `OnboardingView.getStartedButton`
- `OnboardingView.grantPermissionButton`
- `OnboardingView.finishButton`

**Sync History View:**
- `SyncHistoryView.historyList`
- `SyncHistoryView.recordRow`

## Using Haptic Feedback

```swift
// Import the utility
import HapticFeedback

// Use in button actions
Button("Sync") {
    HapticFeedback.medium.generate()
    performSync()
}

// Available types:
HapticFeedback.success.generate()  // For successful operations
HapticFeedback.error.generate()    // For errors
HapticFeedback.warning.generate()  // For warnings
HapticFeedback.medium.generate()   // For primary actions
HapticFeedback.light.generate()    // For secondary actions
HapticFeedback.selection.generate() // For toggles/pickers
```

## Using Semantic Colors

```swift
// Use semantic colors for dark mode support
.foregroundColor(.primaryText)
.background(Color.secondaryBackground)

// Available colors:
Color.primaryBackground
Color.secondaryBackground
Color.tertiaryBackground
Color.primaryText
Color.secondaryText
Color.tertiaryText
Color.successColor
Color.warningColor
Color.errorColor
Color.infoColor
```

## Adding Accessibility Labels

```swift
Button("Sync") {
    performSync()
}
.accessibilityLabel("Sync now")
.accessibilityHint("Manually triggers health data synchronization")
.accessibilityIdentifier(AccessibilityIdentifiers.MainView.syncButton)
```

## Hiding Decorative Elements

```swift
Image(systemName: "heart")
    .accessibilityHidden(true)  // Icon is decorative, text provides context
```

## Grouping Elements

```swift
VStack {
    Text("Status")
    Text("Ready")
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Status: Ready")
```

## Using Loading States

```swift
if isLoading {
    LoadingStateView(message: "Loading sync history...")
} else if items.isEmpty {
    EmptyStateView(
        icon: "clock.arrow.circlepath",
        title: "No History",
        message: "History will appear here"
    )
} else {
    // Content
}
```

## Keyboard Handling

```swift
TextField("Enter text", text: $text)
    .keyboardDoneButton()  // Adds done button to keyboard
    .dismissKeyboardOnTap()  // Dismisses on tap outside
```

## Testing Checklist

- [ ] All buttons have accessibility labels
- [ ] All images have text alternatives or are hidden
- [ ] Status indicators include text
- [ ] Forms announce their state
- [ ] Loading states are announced
- [ ] Errors are announced clearly
- [ ] Haptic feedback on interactions
- [ ] Dark mode looks correct
- [ ] Large text sizes work
- [ ] VoiceOver navigation is logical

## Common Patterns

### Button with Loading State
```swift
Button(action: action) {
    HStack {
        if isLoading {
            ProgressView()
                .accessibilityLabel("Loading")
        }
        Text(isLoading ? "Loading..." : "Action")
    }
}
.disabled(isLoading)
.accessibilityLabel(isLoading ? "Loading" : "Action")
.accessibilityHint("Description of what this does")
```

### Toggle with Haptic
```swift
Toggle("Option", isOn: $isEnabled)
    .onChange(of: isEnabled) { _ in
        HapticFeedback.selection.generate()
    }
    .accessibilityLabel("Option name")
    .accessibilityValue(isEnabled ? "enabled" : "disabled")
```

### Card with Accessibility
```swift
VStack {
    Text("Title")
    Text("Content")
}
.cardStyle()
.accessibilityElement(children: .combine)
.accessibilityLabel("Title: Content")
```

## Resources

- Full guide: `ACCESSIBILITY_GUIDE.md`
- Test script: `ACCESSIBILITY_TEST_SCRIPT.md`
- Implementation checklist: `UI_POLISH_CHECKLIST.md`
