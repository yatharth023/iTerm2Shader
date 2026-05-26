import Cocoa

// MILESTONE 7: Status bar menu for preset switching and settings
// Provides reliable UI controls since keyboard shortcuts are unreliable

class StatusBarController {

    private var statusItem: NSStatusItem?
    private var menu: NSMenu?

    // Callbacks to daemon controller
    var onCyclePreset: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onQuit: (() -> Void)?
    var onPresetSelected: ((String) -> Void)?

    private let allPresetNames = [
        "Spaceflight",
        "Night-Sky-Flight",
        "Morning-Sky-Flight",
        "Ocean-Wave-Flight",
        "Evening-Sky-Flight"
    ]

    private var currentPresetName: String = "Spaceflight"

    init() {
        setupStatusBar()
    }

    private func setupStatusBar() {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else {
            print("ERROR: Failed to create status bar button")
            return
        }

        // Set icon (using SF Symbol)
        if let image = NSImage(systemSymbolName: "waveform.path", accessibilityDescription: "iTerm2 Shader") {
            image.isTemplate = true // Makes it adapt to dark/light mode
            button.image = image
        } else {
            // Fallback to text if symbol not available
            button.title = "🎨"
        }

        button.toolTip = "iTerm2 Shader Controls"

        // Create menu
        menu = NSMenu()

        // Preset selection submenu
        let presetsMenu = NSMenu()
        for presetName in allPresetNames {
            let item = NSMenuItem(title: presetName, action: #selector(presetSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = presetName
            presetsMenu.addItem(item)
        }

        let presetsMenuItem = NSMenuItem(title: "Presets", action: nil, keyEquivalent: "")
        presetsMenuItem.submenu = presetsMenu
        menu?.addItem(presetsMenuItem)

        menu?.addItem(NSMenuItem.separator())

        // Quick cycle preset
        let cycleItem = NSMenuItem(title: "Next Preset", action: #selector(cyclePresetAction), keyEquivalent: "n")
        cycleItem.target = self
        menu?.addItem(cycleItem)

        menu?.addItem(NSMenuItem.separator())

        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettingsAction), keyEquivalent: ",")
        settingsItem.target = self
        menu?.addItem(settingsItem)

        menu?.addItem(NSMenuItem.separator())

        // About/Info
        let infoItem = NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: "")
        infoItem.target = self
        menu?.addItem(infoItem)

        // Quit
        let quitItem = NSMenuItem(title: "Quit iTerm2 Shader", action: #selector(quitAction), keyEquivalent: "q")
        quitItem.target = self
        menu?.addItem(quitItem)

        statusItem?.menu = menu

        print("✅ Status bar menu created")
    }

    @objc private func presetSelected(_ sender: NSMenuItem) {
        guard let presetName = sender.representedObject as? String else { return }

        print("Status bar: Preset selected - \(presetName)")
        currentPresetName = presetName
        updatePresetCheckmarks()
        onPresetSelected?(presetName)
    }

    @objc private func cyclePresetAction() {
        print("Status bar: Cycle preset")
        onCyclePreset?()
    }

    @objc private func openSettingsAction() {
        print("Status bar: Open settings")
        onOpenSettings?()
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "iTerm2 Shader Engine"
        alert.informativeText = """
        Version: 0.7.1

        Premium terminal shader engine for iTerm2
        with animated Metal-rendered backgrounds.

        • 5 cinematic presets
        • Typing reactivity
        • Real-time settings
        • 60 FPS rendering

        Use this menu to:
        • Switch presets
        • Open settings panel
        • Control the daemon

        Logs: /tmp/iterm2shader.log
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quitAction() {
        print("Status bar: Quit requested")
        onQuit?()
    }

    // Update checkmarks in preset menu
    func updateCurrentPreset(name: String) {
        currentPresetName = name
        updatePresetCheckmarks()
    }

    private func updatePresetCheckmarks() {
        guard let menu = menu,
              let presetsMenuItem = menu.item(withTitle: "Presets"),
              let presetsSubmenu = presetsMenuItem.submenu else {
            return
        }

        // Update checkmarks
        for item in presetsSubmenu.items {
            item.state = (item.representedObject as? String == currentPresetName) ? .on : .off
        }
    }
}
