import Foundation

struct PresetParameters {
    var intensity: Float
    var speed: Float
    var depth: Float
    var contrast: Float
    var colorTemperature: Float
    var glow: Float
    var typingReactivityStrength: Float

    static var `default`: PresetParameters {
        return PresetParameters(
            intensity: 0.6,
            speed: 1.0,
            depth: 1.0,
            contrast: 0.3,
            colorTemperature: 6500.0,
            glow: 0.2,
            typingReactivityStrength: 0.3
        )
    }
}

struct PerformanceTuning {
    var targetFrameRate: Int
    var useSimplifiedShading: Bool

    static var `default`: PerformanceTuning {
        return PerformanceTuning(
            targetFrameRate: 60,
            useSimplifiedShading: false
        )
    }
}

protocol ShaderPreset {
    var name: String { get }
    var defaultParameters: PresetParameters { get }
    var performanceTuning: PerformanceTuning { get }
    var shaderFunctionName: String { get }

    func onTypingReaction(currentReactionValue: inout Float)
}
