import simd

// Swift bridge for ShaderTypes.h
// Must match the layout in ShaderTypes.h exactly

struct ShaderUniforms {
    var resolution: simd_float2      // 8 bytes (offset 0)
    var time: Float                  // 4 bytes (offset 8)
    var intensity: Float             // 4 bytes (offset 12)

    var speed: Float                 // 4 bytes (offset 16)
    var depth: Float                 // 4 bytes (offset 20)
    var contrast: Float              // 4 bytes (offset 24)
    var colorTemperature: Float      // 4 bytes (offset 28)

    var glow: Float                  // 4 bytes (offset 32)
    var typingReaction: Float        // 4 bytes (offset 36)
    var padding1: Float              // 4 bytes (offset 40)
    var padding2: Float              // 4 bytes (offset 44)
}
