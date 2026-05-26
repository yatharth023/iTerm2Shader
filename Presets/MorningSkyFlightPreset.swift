import Foundation

struct MorningSkyFlightPreset: ShaderPreset {
    let name = "Morning-Sky-Flight"

    let defaultParameters = PresetParameters(
        intensity: 0.75,        // Slightly reduced to preserve blue
        speed: 1.0,
        depth: 2.5,
        contrast: 0.35,         // Reduced to preserve color saturation
        colorTemperature: 7500.0,  // Cool/blue temperature (NOT warm orange)
        glow: 0.25,             // Reduced to avoid color washing
        typingReactivityStrength: 0.35
    )

    let performanceTuning = PerformanceTuning(
        targetFrameRate: 60,
        useSimplifiedShading: false
    )

    let shaderFunctionName = "morningsky_shader"

    func onTypingReaction(currentReactionValue: inout Float) {
        currentReactionValue = min(currentReactionValue + 0.15, 1.0)
    }
}
