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

// Note: Background daemons launched with & are typically adopted by PID 1 (launchd/init)
// This is normal and expected behavior for UNIX daemons.
// The daemon should run until explicitly stopped via SIGTERM (iterm2-shader stop)

// Keep the main thread alive with a RunLoop
RunLoop.main.run()
