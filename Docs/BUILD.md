# Build Instructions

## Prerequisites

- macOS 13.0 or later
- Xcode 14.0 or later
- Metal-capable Mac

## Building from Xcode

1. Open `PremiumTerminalShader.xcodeproj` in Xcode
2. Select the "PremiumTerminalShader" scheme
3. Build and run (Cmd+R)

## Building from Command Line

```bash
xcodebuild -project PremiumTerminalShader.xcodeproj -scheme PremiumTerminalShader -configuration Release build
```

The built application will be in:
```
build/Release/PremiumTerminalShader.app
```

## Running

Launch the app. You should see a window with the Spaceflight preset rendering a 3D starfield with forward motion and depth.

Press any key to trigger subtle typing-reactive velocity pulses.

## Milestone 1 Status

✓ Project scaffold and directory structure
✓ App lifecycle shell
✓ Metal rendering engine with MTKView
✓ Shared preset interface protocol
✓ Spaceflight preset fully implemented with:
  - 3D starfield with procedural star generation
  - Forward depth motion
  - Anti-aliased particles with glow
  - Warp streaks for nearby stars
  - Subtle typing-reactive velocity pulses
  - Terminal-safe low contrast visuals
