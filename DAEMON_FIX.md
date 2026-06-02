# Daemon Stability Fix

## Issue

The shader daemon was automatically shutting down after 3-4 preset switches with the error:
```
▸ No shader daemon running — start it with: iterm2-shader start
```

## Root Cause

The daemon had an overly aggressive parent process death detection mechanism that was incompatible with how UNIX background daemons work:

1. **Parent Death Detection Logic** (`App/main.swift` lines 27-48):
   - The daemon monitored its parent process ID (PPID) every 5 seconds
   - When `getppid() == 1` (adopted by launchd/init), it incremented a death counter
   - After 3 consecutive checks (15 seconds), it would shut itself down
   
2. **Normal Daemon Behavior**:
   - When a process is launched with `&` in bash, it runs in the background
   - Background processes are often immediately adopted by PID 1 (launchd on macOS)
   - **This is normal and expected UNIX daemon behavior**

3. **The Problem**:
   - The daemon was treating normal daemon orphaning as a sign that the parent terminal had died
   - This caused legitimate background daemons to shut down incorrectly
   - The 15-second grace period wasn't helping because the daemon was orphaned from the start

## The Fix

### 1. Removed Aggressive Parent Checking (`App/main.swift`)

**Before:**
```swift
// Orphan lifecycle monitor: if parent terminal exits, getppid() becomes 1 (launchd)
let bootTime = Date()
var deadParentTicks = 0

let parentCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
    guard Date().timeIntervalSince(bootTime) > 15.0 else { return }
    if getppid() == 1 {
        deadParentTicks += 1
        if deadParentTicks >= 3 {
            print("Parent process confirmed dead — shutting down")
            daemon.stop()
            exit(0)
        }
    } else {
        deadParentTicks = 0
    }
}
```

**After:**
```swift
// Note: Background daemons launched with & are typically adopted by PID 1 (launchd/init)
// This is normal and expected behavior for UNIX daemons.
// The daemon should run until explicitly stopped via SIGTERM (iterm2-shader stop)
```

### 2. Removed Unnecessary `clear_iterm_bg` Calls (`Packaging/iterm2-shader`)

**Before:**
```bash
next)
  if pgrep -x "$PROCESS_NAME" > /dev/null 2>&1; then
    pkill -USR1 "$PROCESS_NAME"
    sleep 0.15
    clear_iterm_bg          # <- Unnecessary
    echo "▸ Switched to next preset"
  fi
  ;;
```

**After:**
```bash
next)
  if pgrep -x "$PROCESS_NAME" > /dev/null 2>&1; then
    pkill -USR1 "$PROCESS_NAME"
    echo "▸ Switched to next preset"
  fi
  ;;
```

**Why:** The daemon already calls `iTerm2Bridge.forceUpdateViaAppleScript()` during preset switches, so the extra `clear_iterm_bg` call was redundant and added unnecessary overhead.

## Testing

Verified the fix works correctly:

1. **Started daemon**: `iterm2-shader start`
2. **Tested 15 consecutive preset switches**: All succeeded without daemon shutdown
3. **Verified daemon persistence**: Process remained running with correct PID
4. **Clean shutdown**: `iterm2-shader stop` worked as expected

## Files Modified

1. **`App/main.swift`** - Removed parent death detection timer
2. **`Packaging/iterm2-shader`** - Removed unnecessary `clear_iterm_bg` calls from `next`/`prev` commands
3. **`build.sh`** - Updated to include wrapper script in distribution tarball

## Distribution Update

The fixed version is now packaged in:
- `dist/PremiumTerminalShader-2026.05.28.tar.gz`
- SHA256: `7dd1fa35a3d042fc4c71e2c0bc4321a61e4e7809b141fdc743d50a5fdf5ffd06`

The tarball now includes:
- `iterm2-shader-engine` (daemon binary)
- `default.metallib` (compiled shaders)
- `iterm2-shader` (CLI wrapper script)

## Key Takeaway

**UNIX background daemons being adopted by PID 1 is normal behavior, not a failure condition.** The daemon should only exit when explicitly signaled via SIGTERM, not when it detects orphaning.
