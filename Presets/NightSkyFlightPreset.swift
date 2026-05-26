import Foundation

struct NightSkyFlightPreset: ShaderPreset {
    let name = "Night-Sky-Flight"

    let defaultParameters = PresetParameters(
        intensity: 0.7,         // Increased from 0.45 for iTerm2 background
        speed: 0.8,
        depth: 3.0,
        contrast: 0.4,          // Increased from 0.2 for better visibility
        colorTemperature: 8500.0,
        glow: 0.35,             // Increased from 0.25 for more luminance
        typingReactivityStrength: 0.3
    )

    let performanceTuning = PerformanceTuning(
        targetFrameRate: 60,
        useSimplifiedShading: false
    )

    let shaderFunctionName = "nightsky_shader"

    func onTypingReaction(currentReactionValue: inout Float) {
        currentReactionValue = min(currentReactionValue + 0.12, 1.0)
    }
}
