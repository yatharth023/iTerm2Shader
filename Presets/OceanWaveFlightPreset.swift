import Foundation

struct OceanWaveFlightPreset: ShaderPreset {
    let name = "Ocean-Wave-Flight"

    let defaultParameters = PresetParameters(
        intensity: 0.5,
        speed: 0.6,
        depth: 4.0,
        contrast: 0.28,
        colorTemperature: 7500.0,
        glow: 0.18,
        typingReactivityStrength: 0.4
    )

    let performanceTuning = PerformanceTuning(
        targetFrameRate: 60,
        useSimplifiedShading: false
    )

    let shaderFunctionName = "oceanwave_shader"

    func onTypingReaction(currentReactionValue: inout Float) {
        currentReactionValue = min(currentReactionValue + 0.2, 1.0)
    }
}
