import Foundation

struct EveningSkyFlightPreset: ShaderPreset {
    let name = "Evening-Sky-Flight"

    let defaultParameters = PresetParameters(
        intensity: 0.77,        // Increased from 0.52 for iTerm2 background
        speed: 0.7,
        depth: 2.8,
        contrast: 0.46,         // Increased from 0.26 for better visibility
        colorTemperature: 3500.0,
        glow: 0.38,             // Increased from 0.28 for more luminance
        typingReactivityStrength: 0.3
    )

    let performanceTuning = PerformanceTuning(
        targetFrameRate: 60,
        useSimplifiedShading: false
    )

    let shaderFunctionName = "eveningsky_shader"

    func onTypingReaction(currentReactionValue: inout Float) {
        currentReactionValue = min(currentReactionValue + 0.12, 1.0)
    }
}
