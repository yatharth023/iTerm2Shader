import Foundation

// Pure CLI daemon - No AppKit, no GUI, no windows
// Runs as a standard UNIX background process with signal handling

print("=== iTerm2 Shader CLI Daemon Starting ===")
print("PID: \(ProcessInfo.processInfo.processIdentifier)")
print("")

// Create and start the daemon controller
guard let daemon = DaemonController() else {
    print("FATAL: Failed to initialize DaemonController")
    exit(1)
}

daemon.start()

print("✅ Daemon running successfully")
print("")
print("Signal controls:")
print("  kill -USR1 \(ProcessInfo.processInfo.processIdentifier)  # Next preset")
print("  kill -USR2 \(ProcessInfo.processInfo.processIdentifier)  # Previous preset")
print("  kill -TERM \(ProcessInfo.processInfo.processIdentifier)  # Graceful shutdown")
print("")

// Keep the main thread alive with a RunLoop
RunLoop.main.run()
