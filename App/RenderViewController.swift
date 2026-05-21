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
            case 18: cyclePreset()
            default: renderer?.triggerTypingReaction()
            }
        } else {
            renderer?.triggerTypingReaction()
        }
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
