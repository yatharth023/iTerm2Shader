import Foundation
import Metal

class DaemonController {

    private var headlessRenderer: HeadlessMetalRenderer?
    private var frameExporter: FrameExporter?
    private var iTerm2Bridge: ITerm2Bridge?

    private var renderTimer: Timer?
    private let targetFPS: Double = 45.0  // Balanced FPS for smooth rendering with lower overhead
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

    // Signal handling — dedicated GCD sources on a utility queue
    private var signalSourceUSR1: DispatchSourceSignal?
    private var signalSourceUSR2: DispatchSourceSignal?
    private var signalSourceTERM: DispatchSourceSignal?
    private let signalQueue = DispatchQueue(label: "com.shader.signalQueue", qos: .utility)
    private let presetSwapQueue = DispatchQueue(label: "com.shader.presetSwap", qos: .userInitiated)
    private var isSwitchingPreset: Bool = false

    init?() {
        print("Initializing daemon controller...")

        loadSavedPreset()

        guard let device = MTLCreateSystemDefaultDevice() else {
            print("ERROR: Metal is not supported on this device")
            return nil
        }

        print("Metal device: \(device.name)")

        guard let renderer = HeadlessMetalRenderer(preset: currentPreset) else {
            print("ERROR: Failed to create HeadlessMetalRenderer")
            return nil
        }
        self.headlessRenderer = renderer

        guard let exporter = FrameExporter(device: device) else {
            print("ERROR: Failed to create FrameExporter")
            return nil
        }
        self.frameExporter = exporter

        let framePath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent("iTerm2ShaderCLI")
            .appendingPathComponent("frame.png")

        self.iTerm2Bridge = ITerm2Bridge(framePath: framePath)

        if iTerm2Bridge?.isITerm2Running() == false {
            print("WARNING: iTerm2 is not running")
        }

        setupSignalHandlers()

        print("Daemon controller initialized")
        print("Current preset: \(currentPreset.name)")
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
        } else {
            currentPresetIndex = 0
        }
    }

    private func listAvailablePresets() {
        print("Available presets:")
        for (index, preset) in allPresets.enumerated() {
            let marker = index == currentPresetIndex ? ">" : " "
            print("  \(marker) \(index + 1). \(preset.name)")
        }
    }

    // MARK: - Render Loop

    func start() {
        print("Starting render loop at \(targetFPS) FPS...")

        let interval = 1.0 / targetFPS

        renderTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.renderFrame()
        }

        renderTimer?.tolerance = 0.005

        if let timer = renderTimer {
            RunLoop.main.add(timer, forMode: .common)
        }

        print("Render loop started")
    }

    func stop() {
        renderTimer?.invalidate()
        renderTimer = nil
    }

    private func renderFrame() {
        guard let renderer = headlessRenderer,
              let exporter = frameExporter,
              let bridge = iTerm2Bridge else {
            return
        }

        guard let texture = renderer.renderFrame() else {
            return
        }

        guard exporter.exportFrame(texture: texture) else {
            return
        }

        bridge.notifyFrameUpdate()

        frameCount += 1
    }

    // MARK: - Signal Handling (Pure GCD, no raw signal() traps)

    private func setupSignalHandlers() {
        // Block default signal actions at the process level
        signal(SIGUSR1, SIG_IGN)
        signal(SIGUSR2, SIG_IGN)
        signal(SIGTERM, SIG_IGN)

        // GCD dispatch sources on a dedicated utility queue — never touches main thread
        signalSourceUSR1 = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: signalQueue)
        signalSourceUSR1?.setEventHandler { [weak self] in
            self?.handleNextPreset()
        }
        signalSourceUSR1?.resume()

        signalSourceUSR2 = DispatchSource.makeSignalSource(signal: SIGUSR2, queue: signalQueue)
        signalSourceUSR2?.setEventHandler { [weak self] in
            self?.handlePreviousPreset()
        }
        signalSourceUSR2?.resume()

        signalSourceTERM = DispatchSource.makeSignalSource(signal: SIGTERM, queue: signalQueue)
        signalSourceTERM?.setEventHandler { [weak self] in
            self?.handleTermination()
        }
        signalSourceTERM?.resume()
    }

    private func cleanupSignalHandlers() {
        signalSourceUSR1?.cancel()
        signalSourceUSR2?.cancel()
        signalSourceTERM?.cancel()
        signalSourceUSR1 = nil
        signalSourceUSR2 = nil
        signalSourceTERM = nil
    }

    // MARK: - Async Preset Switching (never blocks render loop)

    private func handleNextPreset() {
        guard !isSwitchingPreset else { return }
        isSwitchingPreset = true

        presetSwapQueue.async { [weak self] in
            guard let self = self else { return }

            self.currentPresetIndex = (self.currentPresetIndex + 1) % self.allPresets.count
            self.performPresetSwitch()
        }
    }

    private func handlePreviousPreset() {
        guard !isSwitchingPreset else { return }
        isSwitchingPreset = true

        presetSwapQueue.async { [weak self] in
            guard let self = self else { return }

            self.currentPresetIndex = (self.currentPresetIndex - 1 + self.allPresets.count) % self.allPresets.count
            self.performPresetSwitch()
        }
    }

    private func performPresetSwitch() {
        let newPreset = currentPreset

        // Pipeline recompilation happens off-main — renderer uses semaphore internally
        headlessRenderer?.switchPreset(newPreset)

        SettingsManager.shared.activePresetName = newPreset.name

        // iTerm2 refresh on background thread (AppleScript is thread-safe)
        iTerm2Bridge?.forceUpdateViaAppleScript()

        print("Switched to preset: \(newPreset.name)")
        listAvailablePresets()

        isSwitchingPreset = false
    }

    private func handleTermination() {
        DispatchQueue.main.async { [weak self] in
            self?.stop()
            exit(0)
        }
    }
}
