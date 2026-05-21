import Cocoa
import MetalKit

class RenderViewController: NSViewController {

    private var metalView: MTKView!
    private var renderer: MetalRenderer!
    private var currentPreset: ShaderPreset!

    private let allPresets: [ShaderPreset] = [
        SpaceflightPreset(),
        NightSkyFlightPreset(),
        MorningSkyFlightPreset(),
        OceanWaveFlightPreset(),
        EveningSkyFlightPreset()
    ]

    // MILESTONE 5: Settings Panel
    private var settingsPanelViewController: SettingsPanelViewController?
    private var settingsPanelContainer: NSView?
    private var isSettingsPanelVisible = false
    private var isAnimating = false  // Prevent rapid toggle issues

    override func loadView() {
        print("=== RenderViewController loadView ===")

        let frame = NSRect(x: 0, y: 0, width: 1280, height: 720)
        let rootView = NSView(frame: frame)
        rootView.wantsLayer = true
        rootView.layer?.backgroundColor = NSColor.black.cgColor

        print("Root view created with frame: \(frame)")
        print("Root view wantsLayer: \(rootView.wantsLayer)")

        self.view = rootView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("=== RenderViewController viewDidLoad ===")

        loadSavedPreset()
        setupMetalView()
        setupRenderer()
        setupKeyboardMonitoring()
        setupWindowStateObservers()

        print("=== RenderViewController setup complete ===")
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

    private func setupMetalView() {
        print("Setting up Metal view...")

        guard let device = MTLCreateSystemDefaultDevice() else {
            print("ERROR: Metal is not supported on this device")
            fatalError("Metal is not supported on this device")
        }

        print("Metal device: \(device.name)")

        metalView = MTKView(frame: view.bounds, device: device)
        metalView.autoresizingMask = [.width, .height]
        view.addSubview(metalView)

        print("Metal view frame: \(metalView.frame)")
        print("Metal view bounds: \(metalView.bounds)")

        metalView.colorPixelFormat = .bgra8Unorm
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        metalView.framebufferOnly = false
        metalView.enableSetNeedsDisplay = false
        metalView.isPaused = false

        print("Metal view configured")
    }

    private func setupRenderer() {
        print("Setting up renderer...")
        print("Current preset: \(currentPreset.name)")

        guard let renderer = MetalRenderer(
            view: metalView,
            preset: currentPreset
        ) else {
            print("ERROR: Failed to create Metal renderer")
            fatalError("Failed to create Metal renderer")
        }

        self.renderer = renderer
        metalView.delegate = renderer

        print("Renderer created and assigned")
    }

    private func setupKeyboardMonitoring() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyPress(event: event)
            return event
        }

        print("Keyboard monitoring enabled")
    }

    private func handleKeyPress(event: NSEvent) {
        let keyCode = event.keyCode

        if event.modifierFlags.contains(.command) {
            switch keyCode {
            case 18: cyclePreset() // Cmd+1
            case 2: renderer?.toggleDiagnostics() // Cmd+D
            case 43: toggleSettingsPanel() // Cmd+, (MILESTONE 5)
            default: renderer?.triggerTypingReaction()
            }
        } else {
            renderer?.triggerTypingReaction()
        }
    }

    // MILESTONE 5: Settings Panel Toggle with Slide-in Animation
    private func toggleSettingsPanel() {
        // Prevent toggling during animation
        guard !isAnimating else {
            print("⚠️ Animation in progress, ignoring toggle")
            return
        }

        if isSettingsPanelVisible {
            hideSettingsPanel()
        } else {
            showSettingsPanel()
        }
    }

    private func showSettingsPanel() {
        // Prevent multiple opens
        guard !isSettingsPanelVisible && !isAnimating else {
            print("⚠️ Panel already visible or animating")
            return
        }

        // Mark as animating immediately
        isAnimating = true
        isSettingsPanelVisible = true  // Set state BEFORE animation

        let currentParams = SettingsManager.shared.loadParameters(defaultParameters: currentPreset.defaultParameters)

        let settingsVC = SettingsPanelViewController(
            currentParameters: currentParams,
            allPresets: allPresets
        )

        // Real-time parameter updates
        settingsVC.onParametersChanged = { [weak self] newParameters in
            self?.renderer?.updateParameters(newParameters)
        }

        // Preset switching
        settingsVC.onPresetChanged = { [weak self] newPreset in
            guard let self = self else { return }
            self.currentPreset = newPreset
            self.renderer?.switchPreset(newPreset, view: self.metalView)
            SettingsManager.shared.activePresetName = newPreset.name
        }

        // Close callback
        settingsVC.onClose = { [weak self] in
            self?.hideSettingsPanel()
        }

        self.settingsPanelViewController = settingsVC

        // Create container view for slide-in animation
        let panelWidth: CGFloat = 400
        let container = NSView(frame: NSRect(
            x: view.bounds.width,
            y: 0,
            width: panelWidth,
            height: view.bounds.height
        ))
        container.wantsLayer = true
        container.autoresizingMask = [.minXMargin, .height] // Stay pinned to right edge and resize vertically
        container.layer?.shadowColor = NSColor.black.cgColor
        container.layer?.shadowOpacity = 0.5
        container.layer?.shadowOffset = NSSize(width: -2, height: 0)
        container.layer?.shadowRadius = 8

        addChild(settingsVC)
        container.addSubview(settingsVC.view)
        settingsVC.view.frame = container.bounds
        settingsVC.view.autoresizingMask = [.width, .height]

        view.addSubview(container)
        self.settingsPanelContainer = container

        // Update preset selection AFTER view is loaded
        settingsVC.updateCurrentPreset(presetName: currentPreset.name)

        // Slide-in animation
        NSAnimationContext.runAnimationGroup({ [weak self] context in
            guard let self = self else { return }
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true

            container.frame = NSRect(
                x: self.view.bounds.width - panelWidth,
                y: 0,
                width: panelWidth,
                height: self.view.bounds.height
            )
        }, completionHandler: { [weak self] in
            self?.isAnimating = false
            print("✅ Settings panel opened")
        })
    }

    private func hideSettingsPanel() {
        // Prevent multiple closes
        guard isSettingsPanelVisible && !isAnimating, let container = settingsPanelContainer else {
            print("⚠️ Panel not visible or animating")
            return
        }

        // Mark as animating and update state immediately
        isAnimating = true
        isSettingsPanelVisible = false  // Set state BEFORE animation

        // Slide-out animation
        NSAnimationContext.runAnimationGroup({ [weak self] context in
            guard let self = self else { return }
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true

            container.frame = NSRect(
                x: self.view.bounds.width,
                y: 0,
                width: container.bounds.width,
                height: self.view.bounds.height
            )
        }, completionHandler: { [weak self] in
            guard let self = self else { return }

            // Clean up UI elements
            container.removeFromSuperview()
            self.settingsPanelViewController?.removeFromParent()
            self.settingsPanelViewController = nil
            self.settingsPanelContainer = nil
            self.isAnimating = false

            print("✅ Settings panel closed")
        })
    }

    // MILESTONE 5: Window state observers for edge-case resilience
    private func setupWindowStateObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMiniaturize),
            name: NSWindow.didMiniaturizeNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidDeminiaturize),
            name: NSWindow.didDeminiaturizeNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowOcclusionStateChanged),
            name: NSWindow.didChangeOcclusionStateNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        print("Window state observers registered")
    }

    @objc private func windowDidMiniaturize(_ notification: Notification) {
        renderer?.pause()
        metalView?.isPaused = true
    }

    @objc private func windowDidDeminiaturize(_ notification: Notification) {
        renderer?.resume()
        metalView?.isPaused = false
    }

    @objc private func windowOcclusionStateChanged(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        let isOccluded = !window.occlusionState.contains(.visible)
        renderer?.handleOcclusionState(isOccluded: isOccluded)

        // Throttle MTKView when occluded
        if isOccluded {
            metalView?.preferredFramesPerSecond = 10
        } else {
            metalView?.preferredFramesPerSecond = currentPreset.performanceTuning.targetFrameRate
        }
    }

    @objc private func systemWillSleep(_ notification: Notification) {
        print("System going to sleep - pausing renderer")
        renderer?.pause()
        metalView?.isPaused = true
    }

    @objc private func systemDidWake(_ notification: Notification) {
        print("System woke up - resuming renderer")

        // MILESTONE 5: Metal device recovery after sleep/wake
        // MTKView and Metal automatically handle device state recovery
        // Just resume the render loop
        renderer?.resume()
        metalView?.isPaused = false
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func cyclePreset() {
        guard let currentIndex = allPresets.firstIndex(where: { $0.name == currentPreset.name }) else {
            return
        }

        let nextIndex = (currentIndex + 1) % allPresets.count
        let nextPreset = allPresets[nextIndex]

        print("Cycling to next preset: \(nextPreset.name)")

        currentPreset = nextPreset
        renderer?.switchPreset(nextPreset, view: metalView)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        print("=== RenderViewController viewDidAppear ===")
        print("View window: \(view.window?.title ?? "nil")")
        print("View frame: \(view.frame)")
        print("Metal view frame: \(metalView.frame)")

        view.window?.makeFirstResponder(view)
    }
}
