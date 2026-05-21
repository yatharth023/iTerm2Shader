import Foundation

struct MorningSkyFlightPreset: ShaderPreset {
    let name = "Morning-Sky-Flight"

    let defaultParameters = PresetParameters(
        intensity: 0.55,
        speed: 1.0,
        depth: 2.5,
        contrast: 0.22,
        colorTemperature: 4500.0,
        glow: 0.2,
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
