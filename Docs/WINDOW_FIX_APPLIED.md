# Window Visibility Fix Applied

## Changes Made

### 1. AppDelegate.swift
**Added at start of applicationDidFinishLaunching:**
```swift
NSApp.setActivationPolicy(.regular)
```
This explicitly tells macOS that this is a regular application with UI windows and a dock icon, not a background agent or service.

**Added to activateWindow():**
```swift
window.orderFrontRegardless()
```
This forces the window to the front of the screen stack, bypassing normal window ordering rules.

**Full activation sequence now:**
1. `window.setIsVisible(true)` - Mark window as visible
2. `window.makeKeyAndOrderFront(nil)` - Make it the key window and bring to front
3. `window.orderFrontRegardless()` - Force it to front regardless of other windows
4. `NSApp.activate(ignoringOtherApps: true)` - Activate the entire application

### 2. Info.plist
**Added explicit declarations:**
```xml
<key>LSUIElement</key>
<false/>
```
Explicitly declares this is NOT a background-only app.

```xml
<key>NSSupportsAutomaticGraphicsSwitching</key>
<true/>
```
Enables automatic graphics switching for better Metal performance on MacBooks with dual GPUs.

## What These Changes Do

1. **NSApp.setActivationPolicy(.regular)** - Without this, the app might launch as an agent or accessory app, which won't show dock icons or windows normally.

2. **orderFrontRegardless()** - This is the nuclear option for window ordering. It brings the window to the front no matter what, ignoring other apps' windows and system preferences.

3. **LSUIElement = false** - Explicitly prevents macOS from treating this as a UIElement (background agent). When undefined, macOS might make assumptions based on other factors.

4. **NSSupportsAutomaticGraphicsSwitching** - Allows Metal to use the appropriate GPU, which is important for the shader rendering.

## Testing the Fix

After building (Cmd+R), you should see:
1. The app icon appears in the Dock
2. A window titled "Premium Terminal Shader Engine" appears
3. The window contains a black background with the Spaceflight starfield
4. Stars are moving forward with depth
5. Pressing any key triggers subtle velocity pulses

## If Window Still Doesn't Appear

Try these debugging steps in order:

1. **Check Console logs**: Open Console.app and filter for "PremiumTerminalShader" to see if there are any startup errors.

2. **Check Window menu**: When the app is running, check if "Premium Terminal Shader Engine" appears in the Window menu. If it does but isn't visible, the window might be off-screen.

3. **Force window on-screen**: Add this to activateWindow() before orderFrontRegardless():
   ```swift
   window.setFrameOrigin(NSPoint(x: 100, y: 100))
   ```

4. **Check Metal device**: Add this debug print in RenderViewController.setupMetalView():
   ```swift
   print("Metal device created: \(device.name)")
   ```

5. **Verify window creation**: Add this debug print in AppDelegate.setupWindow():
   ```swift
   print("Window created with frame: \(window.frame)")
   ```

## Current File State

All files are in sync with the following critical settings:
- **App/AppDelegate.swift**: Contains `NSApp.setActivationPolicy(.regular)` and `orderFrontRegardless()`
- **Info.plist**: Contains `LSUIElement = false`
- **All other files**: Unchanged from previous working state

The window should now be forcefully visible on screen.
