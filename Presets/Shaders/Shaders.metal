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

// ============================================================================
// SHARED UTILITY FUNCTIONS (marked static to prevent linker conflicts)
// ============================================================================

static float hash_shared(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Color temperature conversion (Kelvin to RGB tint)
static float3 applyColorTemperature(float3 color, float temperature) {
    // Normalize temperature: 6500K is neutral (1.0)
    float tempNorm = temperature / 6500.0;

    float3 tint;
    if (tempNorm < 1.0) {
        // Warm (lower temperature: orange/red tint)
        tint = float3(1.0, 0.8 + tempNorm * 0.2, 0.6 + tempNorm * 0.4);
    } else {
        // Cool (higher temperature: blue tint)
        float excess = (tempNorm - 1.0) * 0.5; // Scale down the effect
        tint = float3(1.0 - excess * 0.15, 1.0 - excess * 0.05, 1.0 + excess * 0.2);
    }

    return color * tint;
}

// Apply glow/bloom effect
static float3 applyGlow(float3 color, float glowStrength) {
    if (glowStrength < 0.01) {
        return color; // Skip if glow is disabled
    }

    // Extract luminance
    float luma = dot(color, float3(0.299, 0.587, 0.114));

    // More aggressive glow threshold and factor
    float glowThreshold = 0.2; // Lower threshold = more pixels glow
    float glowFactor = smoothstep(glowThreshold, 1.0, luma) * glowStrength;

    // Strong bloom effect with brightness boost
    float brightnessMult = 1.0 + glowFactor * 3.0; // 3x brightness boost at max glow
    float3 bloomColor = color * brightnessMult;

    // Add slight white tint for authentic bloom
    bloomColor = mix(bloomColor, float3(1.0), glowFactor * 0.3);

    return mix(color, bloomColor, glowFactor * 0.8);
}

static float noise_shared(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash_shared(i);
    float b = hash_shared(i + float2(1.0, 0.0));
    float c = hash_shared(i + float2(0.0, 1.0));
    float d = hash_shared(i + float2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

static float fbm_shared(float2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise_shared(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }

    return value;
}

// ============================================================================
// PRESET 1: SPACEFLIGHT
// ============================================================================

fragment float4 spaceflight_shader(
    VertexOut in [[stage_in]],
    constant ShaderUniforms& uniforms [[buffer(0)]]
) {
    float2 uv = in.uv;
    float aspect = uniforms.resolution.x / uniforms.resolution.y;
    float2 p = (uv - 0.5) * float2(aspect, 1.0);

    float3 color = float3(0.0);

    // Ultra optimized: 35 stars for buttery smooth 60 FPS
    int starCount = 35;

    for (int i = 0; i < starCount; i++) {
        float fi = float(i);

        // Pre-computed hash values (minimize hash calls)
        float h1 = hash_shared(float2(fi * 12.345, fi * 67.890));
        float h2 = hash_shared(float2(fi * 34.567, fi * 89.012));
        float h3 = hash_shared(float2(fi * 56.789, fi * 23.456));

        // Star base position
        float2 starBase = float2(h1 * 5.0 - 2.5, h2 * 5.0 - 2.5);

        // Animate depth
        float z = fmod(h3 + uniforms.time * uniforms.speed * 0.2, 1.0);

        // Fast perspective (avoid division where possible)
        float zInv = 1.0 / (z * 2.0 + 0.3);
        float2 starPos = starBase * zInv * 0.3;

        // Quick distance
        float dist = length(p - starPos);

        // Skip far stars immediately
        if (dist > 0.4) continue;

        // Simple star with size
        float starSize = 0.015 * zInv;
        float star = max(0.0, (starSize - dist) / starSize);

        // Brightness based on depth
        star *= (1.0 - z) * 1.3;

        color += star * float3(0.95, 0.97, 1.0);
    }

    // Space background
    color += float3(0.01, 0.02, 0.05);

    // Fast vignette
    float edge = length((uv - 0.5) * float2(aspect, 1.0));
    color *= (1.0 - edge * 0.35);

    // Center calm
    float center = length(uv - 0.5) * 1.5;
    color *= mix(0.7, 1.0, center * center);

    // Final brightness
    color *= uniforms.intensity * 0.75;

    // Apply color temperature
    color = applyColorTemperature(color, uniforms.colorTemperature);

    // Apply glow
    color = applyGlow(color, uniforms.glow);

    // BGRA format fix: swap R and B channels
    return float4(color.b, color.g, color.r, 1.0);
}

// ============================================================================
// PRESET 2: NIGHT-SKY-FLIGHT
// ============================================================================

static float cloudLayer_nightsky_wispy(float2 p, float time, float speed) {
    // Clouds moving right to left (negative X direction)
    float2 drift = float2(-time * speed * 0.15, time * speed * 0.02);

    // Realistic wispy cloud formations
    float clouds = fbm_shared(p * 1.0 + drift, 4);
    clouds += fbm_shared(p * 0.5 + drift * 0.7, 3) * 0.5;

    // Clear cloud edges for realistic night clouds
    clouds = smoothstep(0.45, 0.7, clouds);
    return clouds;
}

fragment float4 nightsky_shader(
    VertexOut in [[stage_in]],
    constant ShaderUniforms& uniforms [[buffer(0)]]
) {
    float2 uv = in.uv;
    float aspect = uniforms.resolution.x / uniforms.resolution.y;
    float2 p = (uv - 0.5) * float2(aspect, 1.0) * uniforms.depth;

    // Full-screen wispy cloud layers
    float clouds1 = cloudLayer_nightsky_wispy(p, uniforms.time, uniforms.speed);
    float clouds2 = cloudLayer_nightsky_wispy(p * 0.75 + float2(100.0, 50.0), uniforms.time * 1.15, uniforms.speed * 0.9);
    float clouds3 = cloudLayer_nightsky_wispy(p * 1.25 - float2(70.0, 35.0), uniforms.time * 0.85, uniforms.speed * 1.05);

    float cloudDensity = (clouds1 * 0.45 + clouds2 * 0.35 + clouds3 * 0.2);

    // Very deep, dark night sky for readability
    float3 skyDeep = float3(0.02, 0.03, 0.08);        // Deep midnight black-blue
    float3 skyMid = float3(0.04, 0.06, 0.12);         // Dark space blue
    float3 skyHorizon = float3(0.06, 0.09, 0.16);     // Slightly lighter dark blue

    float verticalGradient = uv.y;
    float3 skyBase = mix(skyDeep, skyMid, smoothstep(0.0, 0.5, verticalGradient));
    skyBase = mix(skyBase, skyHorizon, smoothstep(0.5, 1.0, verticalGradient));

    // Realistic white clouds moving right to left
    float3 cloudDark = float3(0.40, 0.42, 0.45);      // Soft gray shadows
    float3 cloudLight = float3(0.85, 0.87, 0.90);     // Bright white clouds

    float3 cloudColor = mix(cloudDark, cloudLight, cloudDensity * 0.6 + 0.3);

    // Blend clouds with sky - visible white clouds
    float3 color = mix(skyBase, cloudColor, cloudDensity * 0.5);

    // GLOWING STARS with radiant twinkling - evenly distributed
    float stars = 0.0;
    float starGlow = 0.0;
    for (int i = 0; i < 40; i++) {
        float2 starSeed = float2(float(i) * 14.329, float(i) * 31.721);

        // Generate evenly distributed random positions across entire screen
        float starX = (hash_shared(starSeed) * 2.0 - 1.0) * aspect * uniforms.depth;
        float starY = (hash_shared(starSeed + float2(127.1, 311.7)) * 2.0 - 1.0) * uniforms.depth;
        float2 starPos = float2(starX, starY);

        float starDist = length(p - starPos);

        // Star sizes
        float starSize = 0.018 + hash_shared(starSeed + float2(1.0, 0.0)) * 0.028;

        // Enhanced twinkling with more intensity variation
        float twinklePhase = float(i) * 2.8;
        float twinkle = sin(uniforms.time * uniforms.speed * 3.5 + twinklePhase) * 0.5 + 0.5;
        twinkle = twinkle * twinkle * twinkle; // Very strong twinkle

        // Bright stars with more variation
        float starBrightness = 0.75 + hash_shared(starSeed + float2(3.0, 0.0)) * 0.35;

        // Stars slightly dimmed by clouds
        float cloudFade = 1.0 - cloudDensity * 0.4;

        // Core star
        float star = smoothstep(starSize, 0.0, starDist) * twinkle * starBrightness * cloudFade;
        stars += star;

        // Radiant glow around brighter stars
        float glowSize = starSize * 3.5;
        float glow = smoothstep(glowSize, 0.0, starDist) * twinkle * starBrightness * cloudFade * 0.4;
        starGlow += glow;
    }

    // Bright white stars with radiant glow
    color += stars * float3(1.0, 1.0, 1.0) * 1.5;
    color += starGlow * float3(0.9, 0.95, 1.0) * 0.8; // Soft blue-white glow

    // Add more background stars with subtle glow - evenly distributed
    float bgStars = 0.0;
    float bgGlow = 0.0;
    for (int j = 0; j < 20; j++) {
        float2 bgSeed = float2(float(j) * 7.123 + 100.0, float(j) * 19.456 + 200.0);

        // Generate evenly distributed random positions for background stars
        float bgX = (hash_shared(bgSeed) * 2.0 - 1.0) * aspect * uniforms.depth;
        float bgY = (hash_shared(bgSeed + float2(269.5, 183.3)) * 2.0 - 1.0) * uniforms.depth;
        float2 bgPos = float2(bgX, bgY);

        float bgDist = length(p - bgPos);
        float bgSize = 0.012 + hash_shared(bgSeed + float2(1.0, 0.0)) * 0.015;
        float bgTwinkle = sin(uniforms.time * uniforms.speed * 2.8 + float(j) * 1.9) * 0.4 + 0.6;
        bgTwinkle = bgTwinkle * bgTwinkle; // Enhanced twinkle

        float bgStar = smoothstep(bgSize, 0.0, bgDist) * bgTwinkle * (1.0 - cloudDensity * 0.3);
        bgStars += bgStar;

        // Subtle glow for background stars
        float bgGlowSize = bgSize * 2.5;
        bgGlow += smoothstep(bgGlowSize, 0.0, bgDist) * bgTwinkle * (1.0 - cloudDensity * 0.3) * 0.3;
    }
    color += bgStars * float3(0.95, 0.97, 1.0) * 0.7;
    color += bgGlow * float3(0.85, 0.9, 1.0) * 0.5; // Soft background glow

    // Typing reactivity - star burst
    float reactiveShimmer = stars * uniforms.typingReaction * 0.2;
    color += reactiveShimmer * float3(0.3, 0.35, 0.4);

    // Edge vignette
    float vignette = 1.0 - length((uv - 0.5) * float2(aspect, 1.0)) * 0.35;
    vignette = smoothstep(0.4, 1.0, vignette);
    color *= vignette;

    // Center text calm zone
    float centerCalm = 1.0 - exp(-length((uv - 0.5) * 2.0));
    color *= mix(0.45, 1.0, centerCalm);

    // Final intensity and contrast - keep very dark
    color *= uniforms.intensity * 0.6;  // Reduce overall brightness
    color = color * (1.0 - uniforms.contrast) + pow(color, float3(1.5)) * uniforms.contrast;

    // Apply glow
    color = applyGlow(color, uniforms.glow);

    // BGRA format fix: swap R and B channels
    return float4(color.b, color.g, color.r, 1.0);
}

// ============================================================================
// PRESET 3: MORNING-SKY-FLIGHT
// ============================================================================

static float cloudLayer_morningsky_realistic(float2 p, float time, float speed) {
    float2 drift = float2(time * speed * 0.08, time * speed * 0.03);

    // Create realistic fluffy cloud shapes with sharp edges
    float clouds = fbm_shared(p * 1.4 + drift, 4);

    // Add detail and definition
    clouds += fbm_shared(p * 2.8 + drift * 1.5, 3) * 0.3;

    // Sharp cloud edges for realistic cumulus look
    clouds = smoothstep(0.45, 0.65, clouds);

    return clouds;
}

fragment float4 morningsky_shader(
    VertexOut in [[stage_in]],
    constant ShaderUniforms& uniforms [[buffer(0)]]
) {
    float2 uv = in.uv;
    float aspect = uniforms.resolution.x / uniforms.resolution.y;
    float2 p = (uv - 0.5) * float2(aspect, 1.0) * uniforms.depth;

    // Realistic cloud layers with clear definition
    float clouds1 = cloudLayer_morningsky_realistic(p, uniforms.time, uniforms.speed);
    float clouds2 = cloudLayer_morningsky_realistic(p * 0.7 + float2(100.0, 50.0), uniforms.time * 1.2, uniforms.speed * 0.85);
    float clouds3 = cloudLayer_morningsky_realistic(p * 1.3 - float2(60.0, 75.0), uniforms.time * 0.8, uniforms.speed * 1.1);

    // Lower density so clouds are distinct, not dusty
    float cloudDensity = (clouds1 * 0.4 + clouds2 * 0.35 + clouds3 * 0.25);

    // Realistic bright morning blue sky
    float verticalGradient = uv.y;

    // Bright, cheerful morning blue gradient
    float3 skyTop = float3(0.35, 0.55, 0.95);        // Rich morning blue
    float3 skyMid = float3(0.50, 0.70, 1.0);         // Bright sky blue
    float3 skyHorizon = float3(0.65, 0.82, 1.0);     // Light pale blue at horizon

    float3 skyBase = mix(skyTop, skyMid, smoothstep(0.0, 0.5, verticalGradient));
    skyBase = mix(skyBase, skyHorizon, smoothstep(0.5, 1.0, verticalGradient));

    // Pure white clouds
    float3 cloudBright = float3(1.0, 1.0, 1.0);
    float3 cloudMid = float3(0.85, 0.85, 0.85);
    float3 cloudShadow = float3(0.65, 0.65, 0.65);

    float3 cloudColor = mix(cloudShadow, cloudMid, smoothstep(0.2, 0.5, cloudDensity));
    cloudColor = mix(cloudColor, cloudBright, smoothstep(0.5, 0.8, cloudDensity));

    // Blend clouds
    float3 color = mix(skyBase, cloudColor, cloudDensity * 0.4);

    // NO typing reactivity for now

    // Very light vignette to keep brightness
    float vignette = 1.0 - length((uv - 0.5) * float2(aspect, 1.0)) * 0.15;
    vignette = smoothstep(0.7, 1.0, vignette);
    color *= vignette;

    // Gentle center calm for text readability
    float centerCalm = 1.0 - exp(-length((uv - 0.5) * 2.0));
    color *= mix(0.70, 1.0, centerCalm);

    // Boost brightness for cheerful morning look
    color *= uniforms.intensity * 1.2;

    // Clamp to prevent overflow
    color = clamp(color, 0.0, 1.0);

    // Apply glow for authentic morning brightness
    color = applyGlow(color, uniforms.glow);

    // CRITICAL FIX: Swap R and B channels for BGRA texture format
    return float4(color.b, color.g, color.r, 1.0);
}

// ============================================================================
// PRESET 4: OCEAN-WAVE-FLIGHT
// ============================================================================

// Multi-directional Gerstner-style wave cascade with golden ratio frequencies
static float oceanWave_gerstner(float2 p, float time, float speed) {
    const float PHI = 1.618033988749; // Golden rataight io
    float height = 0.0;

    // Wave 1: Primary direction
    float freq1 = 1.0;
    float2 dir1 = float2(1.0, 0.3);
    height += sin(dot(p, dir1) * freq1 + time * speed * 0.35) * 0.35;

    // Wave 2: Golden ratio frequency, rotated direction
    float freq2 = PHI;
    float2 dir2 = float2(0.7, 0.9);
    height += sin(dot(p, dir2) * freq2 - time * speed * 0.28) * 0.25;

    // Wave 3: Second golden ratio step
    float freq3 = PHI * PHI;
    float2 dir3 = float2(-0.5, 1.0);
    height += sin(dot(p, dir3) * freq3 + time * speed * 0.42) * 0.20;

    // Wave 4: Combined detail wave (optimized)
    float freq4 = PHI * PHI * PHI;
    float2 dir4 = float2(0.9, -0.4);
    height += sin(dot(p, dir4) * freq4 - time * speed * 0.38) * 0.15;

    // Noise layer for organic variation (reduced to 1)
    height += noise_shared(p * 1.2 + time * speed * 0.10) * 0.18;

    return height;
}

fragment float4 oceanwave_shader(
    VertexOut in [[stage_in]],
    constant ShaderUniforms& uniforms [[buffer(0)]]
) {
    float2 uv = in.uv;
    float aspect = uniforms.resolution.x / uniforms.resolution.y;
    float2 p = (uv - 0.5) * float2(aspect, 1.0);

    // Full-screen perspective with subtle depth scaling
    // Distance from center creates natural depth perception
    float distFromCenter = length(p);
    float depthScale = 1.0 + distFromCenter * 0.5; // Subtle scaling based on distance

    // Apply depth scaling to wave coordinates
    float2 waveCoord = p * depthScale * uniforms.depth * 0.8;
    float waveHeight = oceanWave_gerstner(waveCoord, uniforms.time, uniforms.speed);

    // Normalize wave height to [0, 1] range
    waveHeight = waveHeight * 0.5 + 0.5;

    // Calculate wave normal for specular lighting (simplified derivative)
    float epsilon = 0.01;
    float dxHeight = oceanWave_gerstner(waveCoord + float2(epsilon, 0.0), uniforms.time, uniforms.speed);
    float dyHeight = oceanWave_gerstner(waveCoord + float2(0.0, epsilon), uniforms.time, uniforms.speed);
    float dx = (dxHeight - (waveHeight * 2.0 - 1.0)) / epsilon;
    float dy = (dyHeight - (waveHeight * 2.0 - 1.0)) / epsilon;
    float3 normal = normalize(float3(-dx * 8.0, -dy * 8.0, 1.0));

    // Specular highlight (diamond-like water sparkle)
    float3 viewDir = normalize(float3(0.0, 0.0, 1.0));
    float3 lightDir = normalize(float3(0.3, -0.4, 0.8)); // Elevated light source
    float3 reflectDir = reflect(-lightDir, normal);
    float specular = pow(max(dot(reflectDir, viewDir), 0.0), 32.0);

    // Crest highlights - broader range, sharper peaks
    float crestHighlight = smoothstep(0.5, 0.9, waveHeight) * 0.6;

    // Deep ocean blue color gradient - no orange tints
    float3 oceanDeep = float3(0.02, 0.08, 0.18);      // Dark oceanic blue
    float3 oceanMid = float3(0.08, 0.18, 0.35);       // Deep sea blue
    float3 oceanShallow = float3(0.15, 0.30, 0.52);   // Bright cyan-blue

    // Multi-step gradient for richer color
    float3 baseColor = mix(oceanDeep, oceanMid, smoothstep(0.3, 0.6, waveHeight));
    baseColor = mix(baseColor, oceanShallow, smoothstep(0.6, 0.85, waveHeight));

    float3 color = baseColor;
    color += crestHighlight * float3(0.3, 0.5, 0.7);  // Cyan crest highlights
    color += specular * float3(0.85, 0.95, 1.0) * 0.8; // Bright white sparkle

    // Subtle depth darkening at edges (replaces harsh horizon fade)
    float edgeDarken = 1.0 - smoothstep(0.0, 1.5, distFromCenter) * 0.3;
    color *= edgeDarken;

    // Typing reactivity - blue ripple
    float reactiveRipple = sin(waveHeight * 15.0 + uniforms.time * 4.0) * uniforms.typingReaction * 0.1;
    color += reactiveRipple * float3(0.1, 0.25, 0.4);  // Blue ripple

    // Edge vignette
    float vignette = 1.0 - length((uv - 0.5) * float2(aspect, 1.0)) * 0.42;
    vignette = smoothstep(0.3, 1.0, vignette);
    color *= vignette;

    // Center text calm zone
    float centerCalm = 1.0 - exp(-length((uv - 0.5) * 2.0));
    color *= mix(0.45, 1.0, centerCalm);

    // Final intensity and contrast
    color *= uniforms.intensity;
    color = color * (1.0 - uniforms.contrast) + pow(color, float3(1.4)) * uniforms.contrast;
    color *= 0.65;  // Keep darker for readability

    // Apply glow (no color temperature - keep pure blue)
    color = applyGlow(color, uniforms.glow);

    // BGRA format fix: swap R and B channels
    return float4(color.b, color.g, color.r, 1.0);
}

// ============================================================================
// PRESET 5: EVENING-SKY-FLIGHT
// ============================================================================

static float cloudLayer_eveningsky(float2 p, float time, float speed) {
    // Right to left motion: SUBTRACT time from x coordinate
    float2 drift = float2(-time * speed * 0.12, time * speed * 0.02);

    // Soft, scattered cloud formations
    float clouds = fbm_shared(p * 1.2 + drift, 4);
    clouds += fbm_shared(p * 0.7 + drift * 0.8, 3) * 0.5;
    clouds += fbm_shared(p * 2.0 + drift * 1.3, 2) * 0.25;

    // Realistic cloud edges
    clouds = smoothstep(0.42, 0.72, clouds);
    return clouds;
}

fragment float4 eveningsky_shader(
    VertexOut in [[stage_in]],
    constant ShaderUniforms& uniforms [[buffer(0)]]
) {
    float2 uv = in.uv;
    float aspect = uniforms.resolution.x / uniforms.resolution.y;
    float2 p = (uv - 0.5) * float2(aspect, 1.0) * uniforms.depth;

    // Realistic evening cloud layers
    float clouds1 = cloudLayer_eveningsky(p, uniforms.time, uniforms.speed);
    float clouds2 = cloudLayer_eveningsky(p * 0.72 + float2(90.0, 45.0), uniforms.time * 1.1, uniforms.speed * 0.9);
    float clouds3 = cloudLayer_eveningsky(p * 1.28 - float2(65.0, 70.0), uniforms.time * 0.85, uniforms.speed * 1.08);

    float cloudDensity = (clouds1 * 0.45 + clouds2 * 0.35 + clouds3 * 0.2);

    // Sunless sky gradient: NO sun disk, only ambient glow
    float verticalGradient = uv.y;

    // Hyper-realistic sunset gradient zones
    float3 skyZenith = float3(0.12, 0.18, 0.38);      // Deep dusty navy/indigo at top
    float3 skyUpper = float3(0.28, 0.25, 0.45);       // Rich violet
    float3 skyMid = float3(0.65, 0.45, 0.50);         // Soft twilight pink
    float3 skyLower = float3(0.88, 0.55, 0.40);       // Creamy peach
    float3 skyHorizon = float3(0.98, 0.72, 0.45);     // Vibrant golden-amber glow

    // Smooth multi-zone gradient from top to bottom
    float3 skyBase = mix(skyZenith, skyUpper, smoothstep(0.0, 0.3, verticalGradient));
    skyBase = mix(skyBase, skyMid, smoothstep(0.3, 0.55, verticalGradient));
    skyBase = mix(skyBase, skyLower, smoothstep(0.55, 0.8, verticalGradient));
    skyBase = mix(skyBase, skyHorizon, smoothstep(0.8, 1.0, verticalGradient));

    // Cloud illumination: golden edges, deep plum shadows
    // Clouds near horizon get more golden-orange light
    float horizonProximity = smoothstep(0.4, 1.0, verticalGradient);

    // Shadow side: deep plum/violet
    float3 cloudShadow = mix(
        float3(0.25, 0.22, 0.35),  // Deep plum shadows (top)
        float3(0.35, 0.30, 0.38),  // Lighter violet (near horizon)
        horizonProximity
    );

    // Mid-tone: soft gray-pink
    float3 cloudMid = mix(
        float3(0.55, 0.50, 0.55),  // Neutral gray (top)
        float3(0.70, 0.60, 0.55),  // Warm gray (near horizon)
        horizonProximity
    );

    // Highlight side: brilliant golden-orange where catching sunset light
    float3 cloudHighlight = mix(
        float3(0.85, 0.70, 0.65),  // Soft peachy highlights (top)
        float3(1.0, 0.80, 0.50),   // Brilliant golden-orange (horizon)
        horizonProximity
    );

    // Multi-level cloud shading for 3D depth
    float3 cloudColor = mix(cloudShadow, cloudMid, smoothstep(0.2, 0.5, cloudDensity));
    cloudColor = mix(cloudColor, cloudHighlight, smoothstep(0.5, 0.85, cloudDensity));

    // Additional golden edge boost for clouds near horizon
    cloudColor += horizonProximity * cloudDensity * float3(0.20, 0.12, 0.05);

    // Blend clouds with sky
    float3 color = mix(skyBase, cloudColor, cloudDensity * 0.65);

    // Typing reactivity - warm sunset pulse
    float reactiveGlow = cloudDensity * uniforms.typingReaction * 0.12;
    color += reactiveGlow * float3(0.25, 0.18, 0.12);

    // Edge vignette
    float vignette = 1.0 - length((uv - 0.5) * float2(aspect, 1.0)) * 0.35;
    vignette = smoothstep(0.4, 1.0, vignette);
    color *= vignette;

    // Center text calm zone
    float centerCalm = 1.0 - exp(-length((uv - 0.5) * 2.0));
    color *= mix(0.50, 1.0, centerCalm);

    // Final intensity and contrast
    color *= uniforms.intensity;
    color = color * (1.0 - uniforms.contrast) + pow(color, float3(1.3)) * uniforms.contrast;

    // Apply glow
    color = applyGlow(color, uniforms.glow);

    // BGRA format fix: swap R and B channels
    return float4(color.b, color.g, color.r, 1.0);
}
