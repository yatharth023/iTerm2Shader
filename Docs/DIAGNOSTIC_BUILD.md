# Diagnostic Build - Window Visibility Debug

## Changes Applied

### 1. AppDelegate.swift - Full Debug Logging
- Added print statements at every step
- Moved `NSApp.activate(ignoringOtherApps: true)` to immediate after `setActivationPolicy`
- Fixed window origin to `(100, 100)` instead of center (prevents off-screen window)
- Added debug output for window visibility state

### 2. RenderViewController.swift - Bright Red Background
**CRITICAL DEBUGGING CHANGE:**
```swift
rootView.layer?.backgroundColor = NSColor.red.cgColor
```
This is a **temporary bright red background** on the root view to confirm window visibility.

**Expected Outcomes:**
- **If you see a GIANT RED WINDOW**: The window IS visible, Metal rendering is the issue
- **If you see NOTHING**: Window creation/visibility is the issue

### 3. Info.plist - Clean Configuration
**Verified Keys:**
```xml
<key>CFBundlePackageType</key>
<string>APPL</string>                     ✓ Application type

<key>LSUIElement</key>
<false/>                                  ✓ NOT a background agent

<key>NSPrincipalClass</key>
<string>NSApplication</string>            ✓ Standard app class

<key>NSHighResolutionCapable</key>
<true/>                                   ✓ Retina support

<key>NSSupportsAutomaticGraphicsSwitching</key>
<true/>                                   ✓ GPU switching
```

**Removed:**
- `NSMainStoryboardFile` - Not needed (programmatic UI)
- Any UIKit references - This is AppKit/macOS only

## Build and Test

1. **Clean build folder**: Product → Clean Build Folder (Cmd+Shift+K)
2. **Build**: Cmd+B
3. **Run**: Cmd+R

## Console Output to Check

Open Xcode's Console (View → Debug Area → Show Debug Area) and look for:

```
=== APPLICATION LAUNCHING ===
Activation policy set to regular
App activated
=== SETTING UP WINDOW ===
Window created with frame: ...
Window configured. Center: ...
RenderViewController created
ContentViewController assigned
ContentView frame: ...
Window ordered front
Window isVisible: true
Window isKeyWindow: true
=== WINDOW SETUP COMPLETE ===
=== RenderViewController loadView ===
Root view created with frame: ...
Root view wantsLayer: true
=== RenderViewController viewDidLoad ===
Setting up Metal view...
Metal device: Apple M1/M2/Intel
Metal view frame: ...
Metal view configured
Setting up renderer...
Preset: Spaceflight
Renderer created and assigned
Keyboard monitoring enabled
=== RenderViewController setup complete ===
=== RenderViewController viewDidAppear ===
View window: Premium Terminal Shader Engine
View frame: ...
Metal view frame: ...
```

## Diagnostic Results

### Scenario A: You See a Red Window
**Diagnosis:** Window visibility works! Metal rendering is the problem.

**Next Steps:**
1. Check that `MetalRenderer.draw(in:)` is being called
2. Add print statement in `MetalRenderer.draw(in:)` first line
3. Verify shader compilation succeeded
4. Check for Metal validation errors

### Scenario B: You See Nothing (No Window)
**Diagnosis:** Window creation or system-level blocking issue.

**Console Checks:**
- Does `Window isVisible: true` print?
- Does `Window isKeyWindow: true` print?
- Does `RenderViewController loadView` print?

**If prints appear but no window:**
- Window might be off-screen (check Display settings)
- Run: `defaults delete com.premiumterminalshader.app` to reset window position
- Check Mission Control for hidden spaces

**If NO prints appear:**
- App isn't launching at all
- Check build errors in Xcode
- Check entitlements/code signing

### Scenario C: You See a Red Window but No Stars
**Diagnosis:** Metal view isn't rendering or shader failed.

**Next Steps:**
1. Remove red background: `NSColor.black.cgColor`
2. Add print in `MetalRenderer.draw(in:)` to verify draw loop
3. Check Metal validation layer: Edit Scheme → Run → Diagnostics → Metal API Validation

## Info.plist Verification Checklist

Run this in Terminal from project directory:
```bash
plutil -p Info.plist | grep -E "(LSUIElement|NSPrincipal|CFBundlePackage)"
```

Expected output:
```
"LSUIElement" => 0
"NSPrincipalClass" => "NSApplication"
"CFBundlePackageType" => "APPL"
```

If `LSUIElement` shows `1` or `true`, the app will be headless!

## Quick Fix Commands

**Reset window position:**
```bash
defaults delete com.premiumterminalshader.app NSWindow\ Frame
```

**Force activation policy (if needed):**
Add to top of `applicationDidFinishLaunching`:
```swift
NSApp.setActivationPolicy(.regular)
NSApp.activate(ignoringOtherApps: true)
sleep(1)  // Give system time to process
```

## Current State

All files updated with:
- ✓ Aggressive debug logging
- ✓ Bright red background for visibility test
- ✓ Fixed window origin (not centered, to avoid off-screen)
- ✓ Clean Info.plist with verified keys
- ✓ Early activation policy setting

**BUILD NOW and report:**
1. Do you see a red window? (Yes/No)
2. What console output appears?
3. Does the app icon appear in Dock?
