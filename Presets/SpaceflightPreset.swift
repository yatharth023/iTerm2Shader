import Foundation

struct SpaceflightPreset: ShaderPreset {
    let name = "Spaceflight"

    let defaultParameters = PresetParameters(
        intensity: 0.75,        // Increased from 0.5 for iTerm2 background
        speed: 1.2,
        depth: 2.0,
        contrast: 0.45,         // Increased from 0.25 for better visibility
        colorTemperature: 7000.0,
        glow: 0.25,             // Increased from 0.15 for more luminance
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
