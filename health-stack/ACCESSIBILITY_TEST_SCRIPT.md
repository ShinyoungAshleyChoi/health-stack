# Accessibility Testing Script

This script provides step-by-step instructions for manually testing all accessibility features in the Health Sync app.

## Prerequisites

- iOS device or simulator running iOS 16.0+
- Health Sync app installed
- Familiarity with VoiceOver gestures

## Test Session Setup

1. **Reset App State** (if needed)
   - Delete app from device
   - Reinstall from Xcode
   - This ensures onboarding flow is tested

2. **Enable Accessibility Features**
   - Settings > Accessibility > VoiceOver > ON
   - Settings > Accessibility > Display & Text Size > Larger Text (test various sizes)
   - Settings > Display & Brightness > Dark (test dark mode)

## Test 1: Onboarding Flow with VoiceOver

### Welcome Screen

**Steps:**
1. Launch app with VoiceOver enabled
2. Swipe right through all elements

**Expected Results:**
- [ ] VoiceOver announces "Welcome to Health Sync"
- [ ] App icon description is announced
- [ ] Welcome message is read clearly
- [ ] "Get Started" button is announced with hint
- [ ] Page indicator announces "Page 1 of 3"
- [ ] Double-tap on "Get Started" advances to next screen
- [ ] Haptic feedback occurs on button tap

### Permission Screen

**Steps:**
1. Swipe right through all elements
2. Listen to each permission description
3. Double-tap "Grant Permission" button

**Expected Results:**
- [ ] VoiceOver announces "HealthKit Access"
- [ ] Each permission item is read with icon description
- [ ] "Grant Permission" button is announced
- [ ] "Skip for Now" button is announced with hint
- [ ] Page indicator announces "Page 2 of 3"
- [ ] Loading state is announced during permission request
- [ ] Haptic feedback occurs on button tap

### Data Type Selection Screen

**Steps:**
1. Swipe right through category cards
2. Double-tap to toggle categories
3. Listen to state changes

**Expected Results:**
- [ ] VoiceOver announces "Select Data Types"
- [ ] Each category announces name and data type count
- [ ] Category state (enabled/disabled) is announced
- [ ] State changes are announced when toggled
- [ ] "Finish Setup" button is announced
- [ ] Page indicator announces "Page 3 of 3"
- [ ] Haptic feedback occurs on toggles
- [ ] Success haptic on completion

## Test 2: Main View with VoiceOver

### Initial State

**Steps:**
1. Navigate to main view
2. Swipe right through all elements

**Expected Results:**
- [ ] Navigation title "Health Sync" is announced
- [ ] Sync status card announces current status
- [ ] Last sync card announces time or "Never synced"
- [ ] Data type summary announces enabled count
- [ ] "Sync Now" button is announced with hint
- [ ] Menu button announces available options

### Sync Operation

**Steps:**
1. Double-tap "Sync Now" button
2. Listen to status updates

**Expected Results:**
- [ ] Button announces "Syncing in progress"
- [ ] Loading indicator is announced
- [ ] Button is disabled during sync
- [ ] Success/error is announced on completion
- [ ] Haptic feedback on start and completion
- [ ] Status card updates are announced

### Network Warning

**Steps:**
1. Enable Airplane Mode
2. Wait for network warning banner

**Expected Results:**
- [ ] Warning banner appears
- [ ] VoiceOver announces "Warning: No internet connection"
- [ ] Banner is accessible and focusable

### Menu Navigation

**Steps:**
1. Focus on menu button
2. Double-tap to open menu
3. Swipe through menu items

**Expected Results:**
- [ ] Menu button announces "Menu"
- [ ] "Settings" option is announced
- [ ] "Sync History" option is announced
- [ ] Each option has clear hint
- [ ] Haptic feedback on selection

## Test 3: Settings View with VoiceOver

### Navigation

**Steps:**
1. Open Settings from menu
2. Swipe right through all sections

**Expected Results:**
- [ ] Navigation title "Settings" is announced
- [ ] "Cancel" button is announced
- [ ] "Save" button is announced
- [ ] All sections are accessible

### Sync Frequency

**Steps:**
1. Focus on sync frequency picker
2. Double-tap to open picker
3. Select different options

**Expected Results:**
- [ ] Picker announces "Sync frequency"
- [ ] Current selection is announced
- [ ] All options are announced when opened
- [ ] Selection change is announced
- [ ] Description text is read
- [ ] Haptic feedback on selection

### Data Type Categories

**Steps:**
1. Swipe to data type section
2. Focus on category toggle
3. Double-tap to toggle
4. Expand category disclosure group

**Expected Results:**
- [ ] Category name is announced
- [ ] State (enabled/disabled) is announced
- [ ] Data type count is announced
- [ ] Toggle state change is announced
- [ ] Individual data types are accessible
- [ ] Haptic feedback on toggle
- [ ] Hint explains category toggle behavior

### Individual Data Types

**Steps:**
1. Expand a category
2. Swipe through data types
3. Toggle individual types

**Expected Results:**
- [ ] Each data type name is announced
- [ ] State is announced for each
- [ ] Toggle changes are announced
- [ ] Haptic feedback on each toggle

### HealthKit Permissions

**Steps:**
1. Swipe to permissions section
2. Focus on authorization status
3. Focus on action buttons

**Expected Results:**
- [ ] "Authorization status" is announced with value
- [ ] "Request HealthKit Authorization" button is clear
- [ ] "Open iOS Settings" button is clear
- [ ] Hints explain what each button does
- [ ] Haptic feedback on button taps

### Save Settings

**Steps:**
1. Focus on "Save" button
2. Double-tap to save

**Expected Results:**
- [ ] Save action is announced
- [ ] Success alert is announced
- [ ] Haptic feedback on save
- [ ] View dismisses properly

## Test 4: Sync History with VoiceOver

### Empty State

**Steps:**
1. Open sync history (if no syncs yet)
2. Swipe through empty state

**Expected Results:**
- [ ] Navigation title "Sync History" is announced
- [ ] Empty state icon is hidden from VoiceOver
- [ ] "No Sync History" message is announced
- [ ] Description text is read clearly

### Record List

**Steps:**
1. After performing syncs, open history
2. Swipe through record rows

**Expected Results:**
- [ ] Each record announces status
- [ ] Timestamp is announced
- [ ] Item count is announced
- [ ] Duration is announced
- [ ] All information is in logical order

### Expandable Errors

**Steps:**
1. Focus on a failed sync record
2. Double-tap to expand
3. Listen to error details

**Expected Results:**
- [ ] Hint announces "Double tap to expand"
- [ ] Error details are announced when expanded
- [ ] "Double tap to collapse" hint when expanded
- [ ] Haptic feedback on tap

### Pull to Refresh

**Steps:**
1. Use three-finger swipe down (VoiceOver gesture)
2. Listen for refresh feedback

**Expected Results:**
- [ ] Refresh action is announced
- [ ] Loading state is announced
- [ ] Completion is announced
- [ ] Haptic feedback on refresh

## Test 5: Dark Mode

### Enable Dark Mode

**Steps:**
1. Go to Settings > Display & Brightness > Dark
2. Return to app
3. Navigate through all views

**Expected Results:**
- [ ] All views render correctly in dark mode
- [ ] Text is readable (proper contrast)
- [ ] Cards are visible with proper shadows
- [ ] Status colors are visible
- [ ] No white flashes or incorrect colors
- [ ] Gradients work in dark mode

### Toggle Between Modes

**Steps:**
1. Use Control Center to toggle appearance
2. Observe app updates

**Expected Results:**
- [ ] App updates immediately
- [ ] No layout issues
- [ ] Smooth transition
- [ ] All elements remain visible

## Test 6: Dynamic Type

### Test Various Sizes

**Steps:**
1. Settings > Accessibility > Display & Text Size > Larger Text
2. Test at minimum size
3. Test at maximum size
4. Test at accessibility sizes

**Expected Results:**
- [ ] Text scales appropriately
- [ ] Layouts don't break
- [ ] No text truncation
- [ ] Buttons remain tappable
- [ ] Scrolling works properly
- [ ] All content is accessible

### Specific Views

**Test each view at largest text size:**
- [ ] Main View: All cards readable
- [ ] Settings View: Form elements work
- [ ] Onboarding View: Text doesn't overflow
- [ ] Sync History View: Records are readable

## Test 7: Haptic Feedback

### Test All Interactions

**Steps:**
1. Disable VoiceOver for this test
2. Perform each action and feel for haptic

**Expected Results:**
- [ ] Sync button: Medium haptic
- [ ] Sync success: Success haptic
- [ ] Sync error: Error haptic
- [ ] Settings save: Success haptic
- [ ] Toggle switches: Selection haptic
- [ ] Picker changes: Selection haptic
- [ ] Category cards: Selection haptic
- [ ] Navigation: Light haptic
- [ ] Pull to refresh: Light haptic

## Test 8: Keyboard Navigation

### External Keyboard

**Steps:**
1. Connect external keyboard
2. Use Tab key to navigate
3. Use Return to activate
4. Use Escape to dismiss

**Expected Results:**
- [ ] Tab moves through interactive elements
- [ ] Focus indicator is visible
- [ ] Return activates buttons
- [ ] Escape dismisses sheets
- [ ] Logical tab order
- [ ] All elements reachable

### On-Screen Keyboard

**Steps:**
1. Focus on any text field (if present)
2. Observe keyboard behavior

**Expected Results:**
- [ ] Keyboard appears automatically
- [ ] Appropriate keyboard type
- [ ] Done button dismisses keyboard
- [ ] Tap outside dismisses keyboard
- [ ] View adjusts for keyboard

## Test 9: Voice Control

### Enable Voice Control

**Steps:**
1. Settings > Accessibility > Voice Control > ON
2. Say "Show numbers"
3. Say "Tap [element name]"

**Expected Results:**
- [ ] Numbers appear on all interactive elements
- [ ] Elements can be activated by name
- [ ] Elements can be activated by number
- [ ] Scrolling works with voice
- [ ] Navigation works with voice

## Test 10: Switch Control

### Enable Switch Control

**Steps:**
1. Settings > Accessibility > Switch Control > ON
2. Configure switches
3. Navigate through app

**Expected Results:**
- [ ] All interactive elements are reachable
- [ ] Focus moves logically
- [ ] Actions can be performed
- [ ] Scrolling works
- [ ] Navigation works

## Test 11: Color Blindness

### Enable Color Filters

**Steps:**
1. Settings > Accessibility > Display & Text Size > Color Filters > ON
2. Try different filter types
3. Navigate through app

**Expected Results:**
- [ ] Status indicators don't rely solely on color
- [ ] Icons supplement color coding
- [ ] Text labels clarify status
- [ ] All information is accessible
- [ ] Sync status uses icon + text
- [ ] Error states use icon + text

## Test 12: Reduce Motion

### Enable Reduce Motion

**Steps:**
1. Settings > Accessibility > Motion > Reduce Motion > ON
2. Navigate through app

**Expected Results:**
- [ ] Animations are simplified
- [ ] Transitions still work
- [ ] No jarring movements
- [ ] Functionality is preserved
- [ ] Haptic feedback still works

## Test 13: Error Scenarios

### Network Error

**Steps:**
1. Enable Airplane Mode
2. Try to sync
3. Listen to error announcement

**Expected Results:**
- [ ] Error alert is announced
- [ ] Error message is clear
- [ ] Retry option is announced
- [ ] Error haptic occurs
- [ ] Recovery suggestion is provided

### Permission Error

**Steps:**
1. Deny HealthKit permissions
2. Try to sync
3. Listen to error

**Expected Results:**
- [ ] Permission error is announced
- [ ] Guidance to Settings is provided
- [ ] Error is clear and actionable
- [ ] Error haptic occurs

## Test 14: Accessibility Inspector

### Run Automated Audit

**Steps:**
1. Open Xcode > Open Developer Tool > Accessibility Inspector
2. Select app in simulator
3. Click "Audit"
4. Review results

**Expected Results:**
- [ ] No critical issues
- [ ] All elements have labels
- [ ] Contrast ratios pass
- [ ] Touch targets meet minimum size
- [ ] No accessibility warnings

## Test Results Summary

### Pass/Fail Criteria

- **Pass**: All checkboxes checked, no critical issues
- **Fail**: Any critical accessibility issue found

### Issues Found

Document any issues here:

1. Issue: [Description]
   - Severity: [Critical/High/Medium/Low]
   - Steps to reproduce: [Steps]
   - Expected: [Expected behavior]
   - Actual: [Actual behavior]

### Recommendations

Document any recommendations for improvement:

1. [Recommendation]
2. [Recommendation]

## Sign-off

- **Tester Name**: _______________
- **Date**: _______________
- **Result**: [ ] Pass [ ] Fail
- **Notes**: _______________

## Next Steps

If issues are found:
1. Document in issue tracker
2. Prioritize by severity
3. Fix and retest
4. Update this script if needed

If all tests pass:
1. Mark task as complete
2. Update documentation
3. Prepare for release
