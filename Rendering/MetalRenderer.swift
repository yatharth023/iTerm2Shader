import Metal
import MetalKit

class MetalRenderer: NSObject, MTKViewDelegate {

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState?
    private var uniformBuffer: MTLBuffer?

    private var preset: ShaderPreset
    private var parameters: PresetParameters

    private var startTime: CFTimeInterval
    private var typingReactionValue: Float = 0.0
    private let reactionDecayFactor: Float = 0.92

    // MILESTONE 4: Diagnostic overlay state
    var diagnosticsEnabled: Bool = false
    private var lastFrameTime: CFTimeInterval = 0.0
    private var frameDeltaMs: Double = 0.0
    private var estimatedFPS: Double = 60.0
    private let fpsSmoothing: Double = 0.9 // Exponential smoothing factor

    // MILESTONE 5: Edge-case resilience state
    private var isPaused: Bool = false
    private var isOccluded: Bool = false

    init?(view: MTKView, preset: ShaderPreset) {
        guard let device = view.device else { return nil }

        self.device = device
        self.preset = preset

        let savedParams = SettingsManager.shared.loadParameters(defaultParameters: preset.defaultParameters)
        self.parameters = savedParams

        self.startTime = CACurrentMediaTime()

        guard let queue = device.makeCommandQueue() else { return nil }
        self.commandQueue = queue

        super.init()

        print("MetalRenderer initializing...")
        guard createPipelineState(view: view) else { return nil }
        createUniformBuffer()

        view.preferredFramesPerSecond = preset.performanceTuning.targetFrameRate
        print("MetalRenderer initialized - Preset: \(preset.name), Target: \(preset.performanceTuning.targetFrameRate) FPS")
    }

    private func createPipelineState(view: MTKView) -> Bool {
        guard let libraryURL = Bundle.main.url(forResource: "default", withExtension: "metallib"),
              let library = try? device.makeLibrary(URL: libraryURL) else {
            print("ERROR: Failed to create Metal library from bundle path")
            return false
        }

        guard let vertexFunction = library.makeFunction(name: "vertex_main"),
              let fragmentFunction = library.makeFunction(name: preset.shaderFunctionName) else {
            print("ERROR: Failed to find shader functions")
            print("Available functions: \(library.functionNames)")
            return false
        }

        print("Shader functions loaded: vertex_main, \(preset.shaderFunctionName)")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            print("Pipeline state created successfully")
            return true
        } catch {
            print("ERROR: Failed to create pipeline state: \(error)")
            return false
        }
    }

    private func createUniformBuffer() {
        let uniformSize = MemoryLayout<ShaderUniforms>.stride
        uniformBuffer = device.makeBuffer(length: uniformSize, options: [.storageModeShared])
        print("Uniform buffer created: \(uniformSize) bytes")
    }

    func switchPreset(_ newPreset: ShaderPreset, view: MTKView) {
        print("Switching preset to: \(newPreset.name)")

        self.preset = newPreset

        let savedParams = SettingsManager.shared.loadParameters(defaultParameters: newPreset.defaultParameters)
        self.parameters = savedParams

        SettingsManager.shared.activePresetName = newPreset.name
        SettingsManager.shared.saveParameters(savedParams)

        guard createPipelineState(view: view) else {
            print("ERROR: Failed to recreate pipeline state for new preset")
            return
        }

        view.preferredFramesPerSecond = preset.performanceTuning.targetFrameRate
        print("Preset switched successfully to: \(newPreset.name)")
    }

    func updateParameters(_ newParameters: PresetParameters) {
        self.parameters = newParameters
        SettingsManager.shared.saveParameters(newParameters)
    }

    func triggerTypingReaction() {
        preset.onTypingReaction(currentReactionValue: &typingReactionValue)
    }

    private func updateUniforms(drawableSize: CGSize) {
        let currentTime = Float(CACurrentMediaTime() - startTime)

        typingReactionValue *= reactionDecayFactor

        if typingReactionValue < 0.001 {
            typingReactionValue = 0.0
        }

        var uniforms = ShaderUniforms(
            resolution: simd_float2(Float(drawableSize.width), Float(drawableSize.height)),
            time: currentTime,
            intensity: parameters.intensity,
            speed: parameters.speed,
            depth: parameters.depth,
            contrast: parameters.contrast,
            colorTemperature: parameters.colorTemperature,
            glow: parameters.glow,
            typingReaction: typingReactionValue * parameters.typingReactivityStrength,
            padding1: 0.0,
            padding2: 0.0
        )

        memcpy(uniformBuffer?.contents(), &uniforms, MemoryLayout<ShaderUniforms>.stride)
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("Drawable size changed: \(size)")
        // MILESTONE 5: Aspect ratio and resolution are automatically updated in updateUniforms
        // No additional state tracking needed - Metal handles this gracefully
    }

    // MILESTONE 5: Pause/resume control for occlusion and minimization
    func pause() {
        isPaused = true
        print("Renderer paused (window minimized or occluded)")
    }

    func resume() {
        isPaused = false
        startTime = CACurrentMediaTime() - Double(parameters.speed) // Smooth time continuity
        print("Renderer resumed")
    }

    func handleOcclusionState(isOccluded: Bool) {
        self.isOccluded = isOccluded
        if isOccluded {
            print("Window occluded - throttling render loop")
        } else {
            print("Window visible - full render loop")
        }
    }

    // MILESTONE 4: Toggle diagnostics overlay
    func toggleDiagnostics() {
        diagnosticsEnabled.toggle()
        print("Diagnostics overlay: \(diagnosticsEnabled ? "ENABLED" : "DISABLED")")
    }

    // MILESTONE 4: Render diagnostic text overlay
    private func renderDiagnosticOverlay(in view: MTKView, commandBuffer: MTLCommandBuffer) {
        guard diagnosticsEnabled else { return }

        // Create attributed string with diagnostic info
        let uniformSize = MemoryLayout<ShaderUniforms>.stride
        let diagnosticText = """
        PRESET: \(preset.name)
        DELTA: \(String(format: "%.2f", frameDeltaMs)) ms
        FPS: \(String(format: "%.1f", estimatedFPS))
        UNIFORMS: \(uniformSize) bytes
        """

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 15, weight: .medium),
            .foregroundColor: NSColor(white: 0.85, alpha: 0.95)
        ]

        let attributedString = NSAttributedString(string: diagnosticText, attributes: attributes)

        // Render text to texture (lightweight Core Graphics approach)
        let textSize = attributedString.size()
        let padding: CGFloat = 8.0
        let boxWidth = textSize.width + padding * 2
        let boxHeight = textSize.height + padding * 2

        guard let context = CGContext(
            data: nil,
            width: Int(boxWidth),
            height: Int(boxHeight),
            bitsPerComponent: 8,
            bytesPerRow: Int(boxWidth) * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return }

        // Clear background with semi-transparent black
        context.setFillColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5)
        context.fill(CGRect(x: 0, y: 0, width: boxWidth, height: boxHeight))

        // Render text
        let textRect = CGRect(x: padding, y: padding, width: textSize.width, height: textSize.height)
        let ctFrame = CTFramesetterCreateFrame(
            CTFramesetterCreateWithAttributedString(attributedString),
            CFRangeMake(0, attributedString.length),
            CGPath(rect: textRect, transform: nil),
            nil
        )

        CTFrameDraw(ctFrame, context)

        // Create texture descriptor
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: Int(boxWidth),
            height: Int(boxHeight),
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead]

        guard let texture = device.makeTexture(descriptor: textureDescriptor),
              let imageData = context.data else { return }

        let region = MTLRegionMake2D(0, 0, Int(boxWidth), Int(boxHeight))
        texture.replace(region: region, mipmapLevel: 0, withBytes: imageData, bytesPerRow: Int(boxWidth) * 4)

        // Blit texture to drawable (top-left corner placement)
        guard let drawable = view.currentDrawable,
              let blitEncoder = commandBuffer.makeBlitCommandEncoder() else { return }

        blitEncoder.copy(
            from: texture,
            sourceSlice: 0,
            sourceLevel: 0,
            sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
            sourceSize: MTLSize(width: Int(boxWidth), height: Int(boxHeight), depth: 1),
            to: drawable.texture,
            destinationSlice: 0,
            destinationLevel: 0,
            destinationOrigin: MTLOrigin(x: 10, y: 10, z: 0)
        )

        blitEncoder.endEncoding()
    }

    func draw(in view: MTKView) {
        // MILESTONE 5: Skip rendering if paused (minimized/occluded)
        if isPaused || isOccluded {
            return
        }

        // MILESTONE 4: Frame timing measurement
        let frameStartTime = CACurrentMediaTime()

        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let pipelineState = pipelineState,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        updateUniforms(drawableSize: view.drawableSize)

        renderEncoder.setRenderPipelineState(pipelineState)

        if let uniformBuffer = uniformBuffer {
            renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)
        }

        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.endEncoding()

        // MILESTONE 4: Render diagnostic overlay if enabled
        renderDiagnosticOverlay(in: view, commandBuffer: commandBuffer)

        commandBuffer.present(drawable)
        commandBuffer.commit()

        // MILESTONE 4: Calculate frame delta and FPS
        let frameEndTime = CACurrentMediaTime()
        frameDeltaMs = (frameEndTime - frameStartTime) * 1000.0

        if lastFrameTime > 0 {
            let instantFPS = 1.0 / (frameEndTime - lastFrameTime)
            // Exponential smoothing for stable FPS display
            estimatedFPS = fpsSmoothing * estimatedFPS + (1.0 - fpsSmoothing) * instantFPS
        }

        lastFrameTime = frameEndTime
    }
}
