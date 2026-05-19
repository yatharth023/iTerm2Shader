#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define SIMD_FLOAT2 float2
#else
#include <simd/simd.h>
#define SIMD_FLOAT2 simd_float2
#endif

struct ShaderUniforms {
    SIMD_FLOAT2 resolution;     // 8 bytes (offset 0)
    float time;                 // 4 bytes (offset 8)
    float intensity;            // 4 bytes (offset 12) [16-byte aligned block complete]

    float speed;                // 4 bytes (offset 16)
    float depth;                // 4 bytes (offset 20)
    float contrast;             // 4 bytes (offset 24)
    float colorTemperature;     // 4 bytes (offset 28) [16-byte aligned block complete]

    float glow;                 // 4 bytes (offset 32)
    float typingReaction;       // 4 bytes (offset 36)
    float padding1;             // 4 bytes (offset 40)
    float padding2;             // 4 bytes (offset 44) [16-byte aligned block complete]
};

#endif
