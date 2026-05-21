import Foundation

class SettingsManager {

    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    private let keyActivePreset = "activePresetName"
    private let keyIntensity = "preset_intensity"
    private let keySpeed = "preset_speed"
    private let keyDepth = "preset_depth"
    private let keyContrast = "preset_contrast"
    private let keyColorTemperature = "preset_colorTemperature"
    private let keyGlow = "preset_glow"
    private let keyTypingReactivityStrength = "preset_typingReactivityStrength"

    private init() {}

    var activePresetName: String {
        get {
            return defaults.string(forKey: keyActivePreset) ?? "Spaceflight"
        }
        set {
            defaults.set(newValue, forKey: keyActivePreset)
        }
    }

    func saveParameters(_ parameters: PresetParameters) {
        defaults.set(parameters.intensity, forKey: keyIntensity)
        defaults.set(parameters.speed, forKey: keySpeed)
        defaults.set(parameters.depth, forKey: keyDepth)
        defaults.set(parameters.contrast, forKey: keyContrast)
        defaults.set(parameters.colorTemperature, forKey: keyColorTemperature)
        defaults.set(parameters.glow, forKey: keyGlow)
        defaults.set(parameters.typingReactivityStrength, forKey: keyTypingReactivityStrength)
    }

    func loadParameters(defaultParameters: PresetParameters) -> PresetParameters {
        if defaults.object(forKey: keyIntensity) == nil {
            return defaultParameters
        }

        return PresetParameters(
            intensity: defaults.float(forKey: keyIntensity),
            speed: defaults.float(forKey: keySpeed),
            depth: defaults.float(forKey: keyDepth),
            contrast: defaults.float(forKey: keyContrast),
            colorTemperature: defaults.float(forKey: keyColorTemperature),
            glow: defaults.float(forKey: keyGlow),
            typingReactivityStrength: defaults.float(forKey: keyTypingReactivityStrength)
        )
    }

    func resetToDefaults(defaultParameters: PresetParameters) {
        saveParameters(defaultParameters)
    }
}
