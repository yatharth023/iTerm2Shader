import Cocoa

// MILESTONE 7: Headless daemon architecture
// Runs as .accessory (no dock icon, no persistent window)
// Streams Metal frames to iTerm2 background at 60 FPS

class AppDelegate: NSObject, NSApplicationDelegate {

    private var daemonController: DaemonController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("=== iTerm2ShaderCLI DAEMON STARTING ===")

        // Run as background daemon with menu bar icon
        // .accessory = no dock icon, menu bar only
        NSApp.setActivationPolicy(.accessory)

        print("Activation policy set to accessory (menu bar daemon)")

        // Initialize daemon controller
        daemonController = DaemonController()

        guard let controller = daemonController else {
            print("FATAL: Failed to initialize DaemonController")
            NSApp.terminate(nil)
            return
        }

        // Start the render loop and iTerm2 sync
        controller.start()

        print("=== DAEMON STARTED SUCCESSFULLY ===")
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("Daemon terminating - cleaning up resources")
        daemonController?.stop()
    }
}
