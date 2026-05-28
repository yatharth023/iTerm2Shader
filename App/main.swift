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
// Grace period: ignore checks for first 15 seconds to survive shell fork handoff
let bootTime = Date()
var orphanHitCount = 0
let requiredConsecutiveHits = 3

let parentCheckTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
    guard Date().timeIntervalSince(bootTime) > 15.0 else { return }

    if getppid() == 1 {
        orphanHitCount += 1
        if orphanHitCount >= requiredConsecutiveHits {
            print("Parent process exited (orphaned) — shutting down cleanly")
            daemon.stop()
            exit(0)
        }
    } else {
        orphanHitCount = 0
    }
}
RunLoop.main.add(parentCheckTimer, forMode: .common)

// Keep the main thread alive with a RunLoop
RunLoop.main.run()
