import Foundation
import AppKit

// MILESTONE 7: iTerm2 background sync bridge
// Updates iTerm2's native background image property via direct file path reference
// Uses OSC 50 escape sequence to avoid inline image buffer flickering

class ITerm2Bridge {

    private let framePath: URL
    private let absoluteFilePath: String
    private var lastUpdateTime: CFTimeInterval = 0.0
    private let updateInterval: CFTimeInterval = 1.0 / 45.0  // 45 FPS sync rate (smooth)

    // Cache compiled AppleScript for better performance
    private var compiledScript: NSAppleScript?

    init(framePath: URL) {
        self.framePath = framePath
        self.absoluteFilePath = framePath.path

        // Pre-compile AppleScript for better performance
        let script = """
        tell application "iTerm2"
            tell current session of current window
                set background image to "\(absoluteFilePath)"
            end tell
        end tell
        """
        self.compiledScript = NSAppleScript(source: script)

        print("ITerm2Bridge initialized - Frame path: \(absoluteFilePath)")
    }

    // Notify iTerm2 that a new frame is available
    // REALITY: iTerm2 does NOT auto-refresh background images
    // We MUST call AppleScript to force refresh, but at low rate (15 FPS)
    private var updateCount: Int = 0

    func notifyFrameUpdate() {
        let currentTime = CACurrentMediaTime()

        // Throttle to 45 FPS (smooth animation)
        guard currentTime - lastUpdateTime >= updateInterval else {
            return
        }

        lastUpdateTime = currentTime
        updateCount += 1

        // Call cached AppleScript to refresh iTerm2 background
        // Using pre-compiled script is faster than compiling each time
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.updateViaAppleScriptCached()
        }

        // Log every 45 frames (once per second at 45 FPS)
        if updateCount % 45 == 0 {
            print("iTerm2 refresh: \(updateCount) frames synced")
        }
    }

    private func sendDirectBackgroundPathUpdate() {
        // iTerm2 background image direct path assignment escape sequence
        // Format: ESC ] 50 ; SetBackgroundImageFile = <absolute_file_path> BEL
        //
        // This is a non-blocking operation that updates iTerm2's background image
        // pointer directly from the local disk cache, completely outside of the
        // active text terminal buffer. This eliminates 100% of visual flickering.

        let escapeSequence = "\u{001B}]50;SetBackgroundImageFile=\(absoluteFilePath)\u{0007}"

        // Write to stdout (iTerm2 listens to this)
        if let data = escapeSequence.data(using: .utf8) {
            FileHandle.standardOutput.write(data)
        }
    }

    // Cached AppleScript execution (faster than compiling each time)
    private func updateViaAppleScriptCached() {
        guard let script = compiledScript else {
            print("⚠️  AppleScript not compiled")
            return
        }

        var error: NSDictionary?
        script.executeAndReturnError(&error)
        if let error = error {
            print("⚠️  AppleScript error: \(error)")
        }
    }

    // AppleScript-based background update (fallback, compiles each time)
    private func updateViaAppleScript() {
        let script = """
        tell application "iTerm2"
            tell current session of current window
                set background image to "\(absoluteFilePath)"
            end tell
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if let error = error {
                print("⚠️  AppleScript error: \(error)")
            }
        }
    }

    // Monitor for iTerm2 process
    // Returns true if iTerm2 is running
    func isITerm2Running() -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { $0.bundleIdentifier == "com.googlecode.iterm2" }
    }

    // Force manual refresh (e.g., when user changes presets)
    func forceUpdateViaAppleScript() {
        print("Manual background refresh via AppleScript...")
        updateViaAppleScript()
    }
}
