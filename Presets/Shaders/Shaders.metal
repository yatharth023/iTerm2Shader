#include <metal_stdlib>
#include "../../Rendering/ShaderTypes.h"
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

// Shared vertex shader for full-screen quad
vertex VertexOut vertex_main(uint vertexID [[vertex_id]]) {
    float2 positions[6] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2(-1.0,  1.0),
        float2( 1.0, -1.0),
        float2( 1.0,  1.0)
    };

    float2 pos = positions[vertexID];

    VertexOut out;
    out.position = float4(pos, 0.0, 1.0);
    out.uv = pos * 0.5 + 0.5;

    return out;
}

// Shared utility functions
static float hash(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

static float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Spaceflight Preset Implementation
struct Star {
    float3 position;
    float brightness;
    float size;
};

static Star generateStar(float2 seed, float time, float speed, float depth) {
    Star star;

    float h1 = hash(seed);
    float h2 = hash(seed + float2(127.1, 311.7));
    float h3 = hash(seed + float2(269.5, 183.3));

    // Distribution across a standard 3D coordinate space
    star.position.x = (h1 * 2.0 - 1.0) * 2.0;
    star.position.y = (h2 * 2.0 - 1.0) * 2.0;

    // Continuous depth cycle tracking
    float baseZ = h3 * depth;
    star.position.z = fmod(baseZ - time * speed * 0.2, depth);
    if (star.position.z < 0.0) {
        star.position.z += depth;
    }

    star.brightness = 0.4 + h1 * 0.6;
    star.size = 1.5 + h2 * 3.5;

    return star;
}

static float renderStar(float2 uv, Star star, float2 resolution, float typingReaction, float depth) {
    float aspect = resolution.x / resolution.y;
    float2 aspectUV = (uv - 0.5) * float2(aspect, 1.0);

    // Division-safe perspective projection calculation
    float zOffset = star.position.z + 0.01;
    float velocityPulse = 1.0 + typingReaction * 0.4;
    float2 projectedPos = (star.position.xy / zOffset) * 0.5 * velocityPulse;

    float dist = length(aspectUV - projectedPos);

    // Scaled up baseline pixel radius multiplier
    float radius = ((star.size * 5.0) / resolution.y) * (1.0 / zOffset);

    // Depth-based dynamic brightness - stars brighten as they approach
    float proximityFade = 1.0 - (star.position.z / depth);
    float dynamicBrightness = star.brightness * mix(1.0, 1.8, proximityFade * proximityFade);

    // Widened smoothstep core distribution for soft anti-aliased edges
    float core = smoothstep(radius, radius * 0.2, dist) * dynamicBrightness;

    // Amplified exponential glow footprint for premium cinematic feel
    float glow = exp(-dist * 8.0 / (radius + 0.001)) * dynamicBrightness * 0.25;

    return core + glow;
}

fragment float4 spaceflight_shader(
    VertexOut in [[stage_in]],
    constant ShaderUniforms& uniforms [[buffer(0)]]
) {
    float2 uv = in.uv;
    float aspect = uniforms.resolution.x / uniforms.resolution.y;

    float3 color = float3(0.0);

    int starCount = 330;

    for (int i = 0; i < starCount; i++) {
        float2 seed = float2(float(i) * 0.1, float(i) * 0.2);
        Star star = generateStar(seed, uniforms.time, uniforms.speed, uniforms.depth);

        float starValue = renderStar(uv, star, uniforms.resolution, uniforms.typingReaction, uniforms.depth);

        float depthFade = 1.0 - (star.position.z / uniforms.depth);
        depthFade = pow(depthFade, 1.5);

        float3 starColor = float3(0.9, 0.95, 1.0);
        if (star.brightness > 0.7) {
            starColor = float3(0.95, 0.9, 1.0);
        }

        color += starColor * starValue * depthFade * uniforms.intensity;
    }

    // Vignette for edge darkening (terminal readability)
    float vignette = 1.0 - length((uv - 0.5) * float2(aspect, 1.0)) * 0.4;
    vignette = smoothstep(0.3, 1.0, vignette);
    color *= vignette;

    // Center calm zone - 70% intensity in center (terminal readability)
    float centerCalm = 1.0 - exp(-length((uv - 0.5) * 2.0));
    color *= mix(0.7, 1.0, centerCalm);

    // Low contrast and intensity cap (terminal readability)
    color = color * (1.0 - uniforms.contrast) + pow(color, float3(1.5)) * uniforms.contrast;
    color *= 0.6;

    return float4(color, 1.0);
}
