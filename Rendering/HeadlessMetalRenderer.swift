import Metal
import MetalKit
import CoreGraphics

// MILESTONE 7: Headless Metal renderer for daemon architecture
// Renders to offscreen textures instead of MTKView drawable

class HeadlessMetalRenderer {

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState?
    private var uniformBuffer: MTLBuffer?

    // Offscreen render target
    private var renderTexture: MTLTexture?
    private let renderWidth: Int = 1920   // Reduced from 2880 for better performance
    private let renderHeight: Int = 1200  // Reduced from 1800 for better performance

    private var preset: ShaderPreset
    private var parameters: PresetParameters

    private var startTime: CFTimeInterval
    private var typingReactionValue: Float = 0.0
    private let reactionDecayFactor: Float = 0.92

    private var isPaused: Bool = false

    // Frame timing for 60 FPS target (smooth animation)
    private var lastFrameTime: CFTimeInterval = 0.0
    private let targetFrameInterval: CFTimeInterval = 1.0 / 60.0

    init?(preset: ShaderPreset) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("ERROR: Metal is not supported on this device")
            return nil
        }

        self.device = device
        self.preset = preset

        let savedParams = SettingsManager.shared.loadParameters(defaultParameters: preset.defaultParameters)
        self.parameters = savedParams

        self.startTime = CACurrentMediaTime()

        guard let queue = device.makeCommandQueue(maxCommandBufferCount: 3) else {
            print("ERROR: Failed to create command queue")
            return nil
        }
        self.commandQueue = queue

        print("HeadlessMetalRenderer initializing...")
        guard createPipelineState() else { return nil }
        createUniformBuffer()
        createOffscreenRenderTarget()

        print("HeadlessMetalRenderer initialized - Preset: \(preset.name), Resolution: \(renderWidth)x\(renderHeight)")
    }

    private func createPipelineState() -> Bool {
        guard let library = device.makeDefaultLibrary() else {
            print("ERROR: Failed to create Metal library")
            return false
        }

        guard let vertexFunction = library.makeFunction(name: "vertex_main"),
              let fragmentFunction = library.makeFunction(name: preset.shaderFunctionName) else {
            print("ERROR: Failed to find shader functions")
            return false
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

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

    private func createOffscreenRenderTarget() {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: renderWidth,
            height: renderHeight,
            mipmapped: false
        )
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        textureDescriptor.storageMode = .shared  // Must be .shared to read on CPU

        renderTexture = device.makeTexture(descriptor: textureDescriptor)
        print("Offscreen render texture created: \(renderWidth)x\(renderHeight)")
    }

    func switchPreset(_ newPreset: ShaderPreset) {
        print("Switching preset to: \(newPreset.name)")

        self.preset = newPreset

        let savedParams = SettingsManager.shared.loadParameters(defaultParameters: newPreset.defaultParameters)
        self.parameters = savedParams

        SettingsManager.shared.activePresetName = newPreset.name
        SettingsManager.shared.saveParameters(savedParams)

        guard createPipelineState() else {
            print("ERROR: Failed to recreate pipeline state for new preset")
            return
        }

        print("Preset switched successfully to: \(newPreset.name)")
    }

    func updateParameters(_ newParameters: PresetParameters) {
        self.parameters = newParameters
        SettingsManager.shared.saveParameters(newParameters)
    }

    func triggerTypingReaction() {
        preset.onTypingReaction(currentReactionValue: &typingReactionValue)
    }

    private func updateUniforms() {
        let currentTime = Float(CACurrentMediaTime() - startTime)

        typingReactionValue *= reactionDecayFactor

        if typingReactionValue < 0.001 {
            typingReactionValue = 0.0
        }

        var uniforms = ShaderUniforms(
            resolution: simd_float2(Float(renderWidth), Float(renderHeight)),
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

    func pause() {
        isPaused = true
        print("HeadlessRenderer paused")
    }

    func resume() {
        isPaused = false
        startTime = CACurrentMediaTime()
        print("HeadlessRenderer resumed")
    }

    // Render a single frame and return the Metal texture
    // Called by frame export pipeline at 60 FPS
    func renderFrame() -> MTLTexture? {
        guard !isPaused,
              let renderTexture = renderTexture,
              let pipelineState = pipelineState,
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            return nil
        }

        // Throttle to 60 FPS
        let currentTime = CACurrentMediaTime()
        let timeSinceLastFrame = currentTime - lastFrameTime

        if timeSinceLastFrame < targetFrameInterval {
            return nil  // Skip frame to maintain 60 FPS
        }

        lastFrameTime = currentTime

        updateUniforms()

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = renderTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        renderPassDescriptor.colorAttachments[0].storeAction = .store

        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return nil
        }

        renderEncoder.setRenderPipelineState(pipelineState)

        if let uniformBuffer = uniformBuffer {
            renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)
        }

        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.endEncoding()

        commandBuffer.commit()

        // MUST wait for render to complete before texture can be read
        // This is required to prevent tearing/corruption
        commandBuffer.waitUntilCompleted()

        return renderTexture
    }
}
