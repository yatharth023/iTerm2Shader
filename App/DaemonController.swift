import Foundation
import Metal

// Pure headless daemon controller - No AppKit dependencies
// Coordinates Metal rendering, frame export, iTerm2 sync, and UNIX signal handling

class DaemonController {

    private var headlessRenderer: HeadlessMetalRenderer?
    private var frameExporter: FrameExporter?
    private var iTerm2Bridge: ITerm2Bridge?

    private var renderTimer: Timer?
    private let targetFPS: Double = 30.0
    private var frameCount: Int = 0

    private let allPresets: [ShaderPreset] = [
        SpaceflightPreset(),
        NightSkyFlightPreset(),
        MorningSkyFlightPreset(),
        OceanWaveFlightPreset(),
        EveningSkyFlightPreset()
    ]

    private var currentPresetIndex: Int = 0
    private var currentPreset: ShaderPreset {
        return allPresets[currentPresetIndex]
    }

    // Dispatch source for signal handling
    private var signalSourceUSR1: DispatchSourceSignal?
    private var signalSourceUSR2: DispatchSourceSignal?
    private var signalSourceTERM: DispatchSourceSignal?
    private let signalQueue = DispatchQueue(label: "com.iterm2shader.signals")
    private var isProcessingSignal = false

    init?() {
        print("Initializing daemon controller...")

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

        // Setup UNIX signal handlers
        setupSignalHandlers()

        print("✅ Daemon controller initialized")
        print("Current preset: \(currentPreset.name)")
        print("")

        listAvailablePresets()
    }

    deinit {
        stop()
        cleanupSignalHandlers()
    }

    // MARK: - Preset Management

    private func loadSavedPreset() {
        let savedPresetName = SettingsManager.shared.activePresetName

        if let index = allPresets.firstIndex(where: { $0.name == savedPresetName }) {
            currentPresetIndex = index
            print("Loaded saved preset: \(savedPresetName)")
        } else {
            currentPresetIndex = 0
            print("No saved preset found, using default: \(allPresets[0].name)")
        }
    }

    private func listAvailablePresets() {
        print("Available presets:")
        for (index, preset) in allPresets.enumerated() {
            let marker = index == currentPresetIndex ? "→" : " "
            print("  \(marker) \(index + 1). \(preset.name)")
        }
        print("")
    }

    // MARK: - Render Loop

    func start() {
        print("Starting render loop at \(targetFPS) FPS...")

        let interval = 1.0 / targetFPS

        renderTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.renderFrame()
        }

        renderTimer?.tolerance = 0.001  // 1ms tolerance

        // Add to main run loop
        if let timer = renderTimer {
            RunLoop.main.add(timer, forMode: .common)
        }

        print("✅ Render loop started")
    }

    func stop() {
        print("Stopping render loop...")

        renderTimer?.invalidate()
        renderTimer = nil

        print("✅ Render loop stopped")
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
            if frameCount % 100 == 0 {
                print("⚠️  Frame export failed at frame \(frameCount)")
            }
            return
        }

        // Notify iTerm2 of new frame
        bridge.notifyFrameUpdate()

        frameCount += 1

        // Log every 30 frames (once per second at 30 FPS)
        if frameCount % 30 == 0 {
            print("[\(frameCount) frames] Preset: \(currentPreset.name)")
        }
    }

    // MARK: - UNIX Signal Handling

    private func setupSignalHandlers() {
        signal(SIGUSR1, SIG_IGN)
        signal(SIGUSR2, SIG_IGN)
        signal(SIGTERM, SIG_IGN)

        // USR1/USR2 dispatch to a dedicated serial queue to avoid blocking main RunLoop
        signalSourceUSR1 = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: signalQueue)
        signalSourceUSR1?.setEventHandler { [weak self] in
            self?.safePresetSwitch { self?.nextPreset() }
        }
        signalSourceUSR1?.resume()

        signalSourceUSR2 = DispatchSource.makeSignalSource(signal: SIGUSR2, queue: signalQueue)
        signalSourceUSR2?.setEventHandler { [weak self] in
            self?.safePresetSwitch { self?.previousPreset() }
        }
        signalSourceUSR2?.resume()

        signalSourceTERM = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        signalSourceTERM?.setEventHandler { [weak self] in
            self?.gracefulShutdown()
        }
        signalSourceTERM?.resume()

        print("UNIX signal handlers configured")
    }

    private func safePresetSwitch(_ action: @escaping () -> Void) {
        guard !isProcessingSignal else { return }
        isProcessingSignal = true
        DispatchQueue.main.async { [weak self] in
            action()
            self?.isProcessingSignal = false
        }
    }

    private func cleanupSignalHandlers() {
        signalSourceUSR1?.cancel()
        signalSourceUSR2?.cancel()
        signalSourceTERM?.cancel()

        signalSourceUSR1 = nil
        signalSourceUSR2 = nil
        signalSourceTERM = nil
    }

    // MARK: - Preset Switching

    private func nextPreset() {
        let oldPreset = currentPreset.name

        currentPresetIndex = (currentPresetIndex + 1) % allPresets.count
        let newPreset = currentPreset

        switchToCurrentPreset(from: oldPreset, to: newPreset.name)
    }

    private func previousPreset() {
        let oldPreset = currentPreset.name

        currentPresetIndex = (currentPresetIndex - 1 + allPresets.count) % allPresets.count
        let newPreset = currentPreset

        switchToCurrentPreset(from: oldPreset, to: newPreset.name)
    }

    private func switchToCurrentPreset(from: String, to: String) {
        print("")
        print("🔄 Preset Switch Signal Received")
        print("   From: \(from)")
        print("   To:   \(to)")

        // Switch renderer to new preset
        headlessRenderer?.switchPreset(currentPreset)

        // Save to settings
        SettingsManager.shared.activePresetName = currentPreset.name

        // Force iTerm2 refresh
        iTerm2Bridge?.forceUpdateViaAppleScript()

        print("✅ Switched to preset: \(to)")
        print("")

        listAvailablePresets()
    }

    private func gracefulShutdown() {
        print("")
        print("🛑 SIGTERM received - Graceful shutdown initiated")

        stop()

        print("✅ Shutdown complete")

        exit(0)
    }
}
