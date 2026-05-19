import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow?
    private var renderViewController: RenderViewController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("=== APPLICATION LAUNCHING ===")

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        print("Activation policy set to regular")
        print("App activated")

        setupWindow()
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("Application terminating")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    private func setupWindow() {
        print("=== SETTING UP WINDOW ===")

        let contentRect = NSRect(x: 100, y: 100, width: 1280, height: 720)
        let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]

        let win = NSWindow(
            contentRect: contentRect,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )

        print("Window created with frame: \(win.frame)")

        win.title = "Premium Terminal Shader Engine"
        win.backgroundColor = NSColor.black
        win.isOpaque = true
        win.isReleasedWhenClosed = false

        print("Window configured at: \(win.frame)")

        renderViewController = RenderViewController()
        print("RenderViewController created")

        win.contentViewController = renderViewController
        print("ContentViewController assigned")
        print("ContentView frame: \(win.contentView?.frame ?? .zero)")

        self.window = win

        win.makeKeyAndOrderFront(nil)
        print("Window ordered front")
        print("Window isVisible: \(win.isVisible)")
        print("Window isKeyWindow: \(win.isKeyWindow)")

        print("=== WINDOW SETUP COMPLETE ===")
    }
}
