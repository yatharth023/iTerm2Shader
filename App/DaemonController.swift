import Cocoa
import Metal

// MILESTONE 7: Daemon orchestration layer
// Coordinates headless rendering, frame export, iTerm2 sync, and keyboard monitoring

class DaemonController {

    private var headlessRenderer: HeadlessMetalRenderer?
    private var frameExporter: FrameExporter?
    private var iTerm2Bridge: ITerm2Bridge?

    private var renderTimer: Timer?
    private let targetFPS: Double = 30.0  // Reduced from 60 for better performance
    private var frameCount: Int = 0

    private let allPresets: [ShaderPreset] = [
        SpaceflightPreset(),
        NightSkyFlightPreset(),
        MorningSkyFlightPreset(),
        OceanWaveFlightPreset(),
        EveningSkyFlightPreset()
    ]

    private var currentPreset: ShaderPreset!

    // Settings panel (spawned on demand) - DISABLED
    // private var settingsPanelWindow: NSWindow?
    // private var settingsPanelViewController: SettingsPanelViewController?

    // Status bar menu - REMOVED (too laggy, not working properly)

    init?() {
        print("DaemonController initializing...")

        // Load saved preset
        loadSavedPreset()

        // Initialize Metal device
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("ERROR: Metal is not supported on this device")
            return nil
        }

        print("Metal device: \(device.name)")

        // Initialize headless renderer
        guard let renderer = HeadlessMetalRenderer(preset: currentPreset) else {
            print("ERROR: Failed to create HeadlessMetalRenderer")
            return nil
        }
        self.headlessRenderer = renderer

        // Initialize frame exporter
        guard let exporter = FrameExporter(device: device) else {
            print("ERROR: Failed to create FrameExporter")
            return nil
        }
        self.frameExporter = exporter

        // Initialize iTerm2 bridge
        let framePath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent("iTerm2ShaderCLI")
            .appendingPathComponent("frame.png")

        self.iTerm2Bridge = ITerm2Bridge(framePath: framePath)

        // Check if iTerm2 is running
        if iTerm2Bridge?.isITerm2Running() == false {
            print("⚠️  WARNING: iTerm2 is not running - background sync will not work")
        }

        // Setup signal handler for preset changes
        setupSignalHandler()

        // Setup keyboard monitoring (for typing reaction only)
        setupKeyboardMonitoring()

        print("=== DaemonController initialized ===")
        print("Current preset: \(currentPreset.name)")
        print("")
        print("To change presets, use commands:")
        print("  kill -USR1 <pid>  # Next preset")
        print("  kill -USR2 <pid>  # Previous preset")
        print("")
        print("Daemon PID: \(ProcessInfo.processInfo.processIdentifier)")
        print("")
        listAvailablePresets()
    }

    deinit {
        stop()
    }

    private func loadSavedPreset() {
        let savedPresetName = SettingsManager.shared.activePresetName

        if let preset = allPresets.first(where: { $0.name == savedPresetName }) {
            currentPreset = preset
            print("Loaded saved preset: \(savedPresetName)")
        } else {
            currentPreset = SpaceflightPreset()
            print("No saved preset found, using default: Spaceflight")
        }
    }

    func start() {
        print("Starting daemon render loop at \(targetFPS) FPS...")

        let interval = 1.0 / targetFPS

        renderTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.renderFrame()
        }

        renderTimer?.tolerance = 0.001  // 1ms tolerance for precise timing

        print("Render loop started")
    }

    func stop() {
        print("Stopping daemon render loop...")

        renderTimer?.invalidate()
        renderTimer = nil

        print("Daemon stopped")
    }

    private func renderFrame() {
        guard let renderer = headlessRenderer,
              let exporter = frameExporter,
              let bridge = iTerm2Bridge else {
            return
        }

        // Render frame to Metal texture
        guard let texture = renderer.renderFrame() else {
            return  // Frame skipped (throttling)
        }

        // Export texture to PNG file
        guard exporter.exportFrame(texture: texture) else {
            print("ERROR: Failed to export frame \(frameCount)")
            return
        }

        // Notify iTerm2 of new frame
        bridge.notifyFrameUpdate()

        frameCount += 1

        // Log every 30 frames (once per second at 30 FPS)
        if frameCount % 30 == 0 {
            print("Rendered \(frameCount) frames - Preset: \(currentPreset.name)")
        }
    }

    // MARK: - Signal Handler (for preset switching via CLI)

    private func setupSignalHandler() {
        // USR1 = Next preset
        signal(SIGUSR1) { _ in
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("NextPreset"), object: nil)
            }
        }

        // USR2 = Previous preset
        signal(SIGUSR2) { _ in
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("PreviousPreset"), object: nil)
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NextPreset"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.cyclePreset(forward: true)
        }

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PreviousPreset"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.cyclePreset(forward: false)
        }

        print("✅ Signal handler setup complete")
    }

    private func listAvailablePresets() {
        print("Available presets:")
        for (index, preset) in allPresets.enumerated() {
            let marker = preset.name == currentPreset.name ? "→" : " "
            print("  \(marker) \(index + 1). \(preset.name)")
        }
        print("")
    }

    // MARK: - Keyboard Monitoring

    private func setupKeyboardMonitoring() {
        // Keyboard monitoring is now ONLY for typing reaction
        // Menu bar provides reliable controls for preset/settings

        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] _ in
            self?.headlessRenderer?.triggerTypingReaction()
        }

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.headlessRenderer?.triggerTypingReaction()
            return event
        }

        print("Keyboard monitoring enabled (typing reaction only)")
        print("Use menu bar icon for preset switching and settings")
    }

    private func cyclePreset(forward: Bool = true) {
        guard let currentIndex = allPresets.firstIndex(where: { $0.name == currentPreset.name }) else {
            return
        }

        let nextIndex: Int
        if forward {
            nextIndex = (currentIndex + 1) % allPresets.count
        } else {
            nextIndex = (currentIndex - 1 + allPresets.count) % allPresets.count
        }

        let nextPreset = allPresets[nextIndex]

        print("")
        print("=== Switching Preset ===")
        print("From: \(currentPreset.name)")
        print("To:   \(nextPreset.name)")
        print("")

        currentPreset = nextPreset
        headlessRenderer?.switchPreset(nextPreset)
        SettingsManager.shared.activePresetName = nextPreset.name

        // Force iTerm2 to refresh background
        iTerm2Bridge?.forceUpdateViaAppleScript()

        listAvailablePresets()
    }

    // MARK: - Settings Panel - REMOVED (not working properly)
}
