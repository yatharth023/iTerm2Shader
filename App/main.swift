import Foundation

// Pure CLI daemon - No AppKit GUI, no .app bundle
// Runs as a standard UNIX background process with signal handling

print("=== iTerm2 Shader Engine Starting ===")
print("PID: \(ProcessInfo.processInfo.processIdentifier)")
print("Parent PID: \(getppid())")
print("")

// Create and start the daemon controller
guard let daemon = DaemonController() else {
    print("FATAL: Failed to initialize DaemonController")
    exit(1)
}

daemon.start()

print("Daemon running successfully")
print("")
print("Signal controls:")
print("  kill -USR1 \(ProcessInfo.processInfo.processIdentifier)  # Next preset")
print("  kill -USR2 \(ProcessInfo.processInfo.processIdentifier)  # Previous preset")
print("  kill -TERM \(ProcessInfo.processInfo.processIdentifier)  # Graceful shutdown")
print("")

// Orphan lifecycle monitor: if parent terminal exits, getppid() becomes 1 (launchd)
// - 15s boot grace period to survive shell fork handoff
// - 5s check interval with 3 consecutive confirmations (15s sustained orphan) before exit
// - Resets immediately on any valid parent reading (survives signal burst transients)
let bootTime = Date()
var deadParentTicks = 0

let parentCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
    guard Date().timeIntervalSince(bootTime) > 15.0 else { return }

    if getppid() == 1 {
        deadParentTicks += 1
        if deadParentTicks >= 3 {
            print("Parent process confirmed dead (\(deadParentTicks) consecutive checks) — shutting down")
            daemon.stop()
            exit(0)
        }
    } else {
        deadParentTicks = 0
    }
}
RunLoop.main.add(parentCheckTimer, forMode: .common)

// Keep the main thread alive with a RunLoop
RunLoop.main.run()
