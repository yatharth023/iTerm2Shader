import Foundation

struct NightSkyFlightPreset: ShaderPreset {
    let name = "Night-Sky-Flight"

    let defaultParameters = PresetParameters(
        intensity: 0.45,
        speed: 0.8,
        depth: 3.0,
        contrast: 0.2,
        colorTemperature: 8500.0,
        glow: 0.25,
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
