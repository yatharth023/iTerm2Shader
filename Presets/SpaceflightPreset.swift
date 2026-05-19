import Foundation

struct SpaceflightPreset: ShaderPreset {
    let name = "Spaceflight"

    let defaultParameters = PresetParameters(
        intensity: 0.5,
        speed: 1.2,
        depth: 2.0,
        contrast: 0.25,
        colorTemperature: 7000.0,
        glow: 0.15,
        typingReactivityStrength: 0.4
    )

    let performanceTuning = PerformanceTuning(
        targetFrameRate: 60,
        useSimplifiedShading: false
    )

    let shaderFunctionName = "spaceflight_shader"

    func onTypingReaction(currentReactionValue: inout Float) {
        // Smaller, stackable increment for smooth rhythm-based accumulation
        currentReactionValue = min(currentReactionValue + 0.15, 1.0)
    }
}
