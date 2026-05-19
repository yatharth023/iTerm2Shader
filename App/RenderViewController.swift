import Cocoa
import MetalKit

class RenderViewController: NSViewController {

    private var metalView: MTKView!
    private var renderer: MetalRenderer!
    private var currentPreset: ShaderPreset!

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

        setupMetalView()
        setupRenderer()
        setupKeyboardMonitoring()

        print("=== RenderViewController setup complete ===")
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

        currentPreset = SpaceflightPreset()
        print("Preset: \(currentPreset.name)")

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
            print("Key pressed: \(event.keyCode)")
            self?.renderer?.triggerTypingReaction()
            return event
        }

        print("Keyboard monitoring enabled")
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
