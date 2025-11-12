# Accessibility Guide

This document provides comprehensive information about the accessibility features implemented in the Health Sync app and how to test them.

## Overview

The Health Sync app is designed to be fully accessible to all users, including those who rely on assistive technologies like VoiceOver, Switch Control, and Voice Control.

## Implemented Accessibility Features

### 1. VoiceOver Support

All UI elements have been enhanced with proper accessibility labels, hints, and traits:

#### Main View
- **Sync Status Card**: Announces current sync status with context
- **Last Sync Card**: Announces when the last sync occurred
- **Data Type Summary**: Announces how many data types are enabled
- **Sync Button**: Clear label and hint about what the button does
- **Menu Button**: Announces available menu options

#### Settings View
- **Sync Frequency Picker**: Announces current selection and available options
- **Category Toggles**: Each category announces its state and data type count
- **Data Type Toggles**: Individual data types announce their enabled/disabled state
- **Permission Buttons**: Clear labels explaining what each button does

#### Onboarding View
- **Page Indicators**: Announces current page number
- **Permission Cards**: Each permission type is clearly labeled
- **Category Cards**: Announces category name, data type count, and enabled state

#### Sync History View
- **Record Rows**: Announces status, timestamp, item count, and duration
- **Error Details**: Expandable error messages are properly announced
- **Empty State**: Clear message when no history is available

### 2. Accessibility Identifiers

All major UI elements have unique accessibility identifiers for UI testing:

```swift
// Example identifiers
AccessibilityIdentifiers.MainView.syncButton
AccessibilityIdentifiers.SettingsView.syncFrequencyPicker
AccessibilityIdentifiers.OnboardingView.getStartedButton
AccessibilityIdentifiers.SyncHistoryView.historyList
```

### 3. Haptic Feedback

Haptic feedback is provided for all user interactions:

- **Success**: When sync completes successfully
- **Error**: When an error occurs
- **Medium**: For primary actions (sync button, permission requests)
- **Light**: For navigation and secondary actions
- **Selection**: For toggle switches and pickers

### 4. Dark Mode Support

The app fully supports iOS dark mode with:

- Semantic colors that adapt to light/dark mode
- Proper contrast ratios in both modes
- Card shadows that work in both modes
- Text colors that maintain readability

### 5. Dynamic Type Support

All text in the app uses system fonts that scale with the user's preferred text size:

- `.headline`, `.body`, `.subheadline`, `.caption` styles
- Text automatically scales from extra small to accessibility sizes
- Layouts adapt to larger text sizes

### 6. Keyboard Navigation

For users with external keyboards:

- Tab navigation works through all interactive elements
- Return key activates buttons
- Escape key dismisses sheets and alerts

## Testing with VoiceOver

### Enable VoiceOver

1. Go to **Settings** > **Accessibility** > **VoiceOver**
2. Toggle **VoiceOver** on
3. Or use the shortcut: Triple-click the side button (if configured)

### VoiceOver Gestures

- **Swipe Right**: Move to next element
- **Swipe Left**: Move to previous element
- **Double Tap**: Activate selected element
- **Two-finger Swipe Up**: Read from top
- **Two-finger Swipe Down**: Read from current position
- **Rotor**: Two-finger rotation to change navigation mode

### Testing Checklist

#### Main View
- [ ] VoiceOver announces "Sync status: [status]"
- [ ] VoiceOver announces "Last sync: [time]"
- [ ] VoiceOver announces data type summary
- [ ] Sync button announces state (enabled/disabled)
- [ ] Menu button announces available options
- [ ] Network warning banner is announced when offline

#### Settings View
- [ ] Sync frequency picker announces current selection
- [ ] Category toggles announce state and data type count
- [ ] Individual data type toggles are accessible
- [ ] Permission status is announced
- [ ] All buttons have clear labels and hints

#### Onboarding View
- [ ] Page indicator announces current page
- [ ] All buttons are accessible and labeled
- [ ] Permission descriptions are read clearly
- [ ] Category cards announce state properly

#### Sync History View
- [ ] Each record announces status, time, and count
- [ ] Error details can be expanded/collapsed
- [ ] Empty state is announced clearly
- [ ] Pull to refresh is accessible

## Testing with Voice Control

### Enable Voice Control

1. Go to **Settings** > **Accessibility** > **Voice Control**
2. Toggle **Voice Control** on

### Voice Control Commands

- **"Tap [element name]"**: Activate an element
- **"Show numbers"**: Display numbers for all interactive elements
- **"Tap number [X]"**: Activate element with number X
- **"Scroll up/down"**: Scroll the view
- **"Go back"**: Navigate back

### Testing Checklist

- [ ] All buttons can be activated by name
- [ ] Number overlay shows all interactive elements
- [ ] Scrolling works in all views
- [ ] Navigation works properly

## Testing with Switch Control

### Enable Switch Control

1. Go to **Settings** > **Accessibility** > **Switch Control**
2. Configure your switches
3. Toggle **Switch Control** on

### Testing Checklist

- [ ] All interactive elements are reachable
- [ ] Focus moves logically through the interface
- [ ] Actions can be performed with switches
- [ ] Scrolling works with switches

## Testing Dynamic Type

### Change Text Size

1. Go to **Settings** > **Accessibility** > **Display & Text Size** > **Larger Text**
2. Adjust the slider to different sizes
3. Test the app at various sizes

### Testing Checklist

- [ ] Text scales properly at all sizes
- [ ] Layouts don't break with large text
- [ ] All text remains readable
- [ ] Buttons remain tappable
- [ ] No text truncation occurs

## Testing Dark Mode

### Toggle Dark Mode

1. Go to **Settings** > **Display & Brightness**
2. Select **Light** or **Dark**
3. Or use Control Center to toggle

### Testing Checklist

- [ ] All views look correct in dark mode
- [ ] Text is readable in both modes
- [ ] Colors have proper contrast
- [ ] Shadows are visible in both modes
- [ ] Status indicators are clear

## Testing Color Blindness

### Enable Color Filters

1. Go to **Settings** > **Accessibility** > **Display & Text Size** > **Color Filters**
2. Toggle **Color Filters** on
3. Try different filter types

### Testing Checklist

- [ ] Status indicators don't rely solely on color
- [ ] Icons supplement color coding
- [ ] Text labels clarify status
- [ ] All information is accessible without color

## Accessibility Best Practices Implemented

### 1. Semantic Structure
- Proper heading hierarchy
- Logical reading order
- Grouped related elements

### 2. Clear Labels
- All buttons have descriptive labels
- Icons have text alternatives
- Status indicators include text

### 3. Sufficient Contrast
- Text meets WCAG AA standards
- Interactive elements are distinguishable
- Focus indicators are visible

### 4. Touch Targets
- All buttons are at least 44x44 points
- Adequate spacing between elements
- No overlapping touch areas

### 5. Feedback
- Visual feedback for all actions
- Haptic feedback for interactions
- Clear error messages

### 6. Keyboard Support
- All actions accessible via keyboard
- Logical tab order
- Visible focus indicators

## Common Issues and Solutions

### Issue: VoiceOver not announcing element
**Solution**: Check that the element has an accessibility label or is not marked as `accessibilityHidden(true)`

### Issue: Element not focusable with VoiceOver
**Solution**: Ensure the element is interactive or use `.accessibilityElement(children: .combine)` for custom views

### Issue: Text truncated at large sizes
**Solution**: Use `.fixedSize(horizontal: false, vertical: true)` or adjust layout constraints

### Issue: Colors not visible in dark mode
**Solution**: Use semantic colors like `Color.primaryText` instead of fixed colors

## Automated Testing

### UI Tests with Accessibility

```swift
func testMainViewAccessibility() {
    let app = XCUIApplication()
    app.launch()
    
    // Test sync button is accessible
    let syncButton = app.buttons[AccessibilityIdentifiers.MainView.syncButton]
    XCTAssertTrue(syncButton.exists)
    XCTAssertTrue(syncButton.isEnabled)
    
    // Test VoiceOver label
    XCTAssertEqual(syncButton.label, "Sync now")
}
```

### Accessibility Audit

Use Xcode's Accessibility Inspector:

1. Open **Xcode** > **Open Developer Tool** > **Accessibility Inspector**
2. Select your app in the simulator
3. Click **Audit** to run automated checks
4. Review and fix any issues found

## Resources

- [Apple Human Interface Guidelines - Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [iOS Accessibility Programming Guide](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/iPhoneAccessibility/)

## Continuous Improvement

Accessibility is an ongoing process. Regular testing with real users who rely on assistive technologies is essential for identifying and addressing issues.

### Feedback Channels

- In-app feedback option
- Accessibility-specific support email
- Regular user testing sessions
- Community feedback forums
