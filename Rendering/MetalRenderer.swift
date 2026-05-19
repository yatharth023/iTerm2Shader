import Metal
import MetalKit

class MetalRenderer: NSObject, MTKViewDelegate {

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState?
    private var uniformBuffer: MTLBuffer?

    private let preset: ShaderPreset
    private var parameters: PresetParameters

    private var startTime: CFTimeInterval
    private var typingReactionValue: Float = 0.0
    private let reactionDecayFactor: Float = 0.92

    init?(view: MTKView, preset: ShaderPreset) {
        guard let device = view.device else { return nil }

        self.device = device
        self.preset = preset
        self.parameters = preset.defaultParameters
        self.startTime = CACurrentMediaTime()

        guard let queue = device.makeCommandQueue() else { return nil }
        self.commandQueue = queue

        super.init()

        print("MetalRenderer initializing...")
        guard createPipelineState(view: view) else { return nil }
        createUniformBuffer()

        view.preferredFramesPerSecond = preset.performanceTuning.targetFrameRate
        print("MetalRenderer initialized successfully - Target: \(preset.performanceTuning.targetFrameRate) FPS")
    }

    private func createPipelineState(view: MTKView) -> Bool {
        guard let library = device.makeDefaultLibrary() else {
            print("ERROR: Failed to create Metal library")
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

    func triggerTypingReaction() {
        preset.onTypingReaction(currentReactionValue: &typingReactionValue)
    }

    private func updateUniforms(drawableSize: CGSize) {
        let currentTime = Float(CACurrentMediaTime() - startTime)

        // Exponential decay for silky-smooth easing (no harsh stops)
        typingReactionValue *= reactionDecayFactor

        // Clamp to zero when very small to prevent floating point drift
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
    }

    func draw(in view: MTKView) {
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

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
