# Diagnostic Test Pattern - Hardware Pipeline Check

## Purpose

This diagnostic isolates whether the issue is:
1. **Draw loop not running** (no frames being processed)
2. **Uniforms not flowing** (GPU receiving zeros)
3. **Shader math broken** (uniforms work but output is wrong)

## Changes Applied

### 1. MetalRenderer.swift - Frame Counter + Verbose Logging

**Added static frame counter:**
```swift
private static var frameCount = 0
```

**Heartbeat logging every 60 frames:**
```swift
if MetalRenderer.frameCount % 60 == 0 {
    print(">>> Renderer Heartbeat: Frame \(MetalRenderer.frameCount) processing successfully.")
}
```

**First frame uniform dump:**
```swift
if MetalRenderer.frameCount == 0 {
    print("=== FIRST FRAME UNIFORMS ===")
    print("Resolution: \(uniforms.resolution)")
    print("Time: \(uniforms.time)")
    print("Intensity: \(uniforms.intensity)")
    print("Speed: \(uniforms.speed)")
    print("Depth: \(uniforms.depth)")
    print("Contrast: \(uniforms.contrast)")
    print("============================")
}
```

**Error logging for each guard failure:**
- No drawable available
- No render pass descriptor
- No pipeline state
- Failed to create command buffer
- Failed to create render encoder
- No uniform buffer

**Library function listing:**
```swift
print("Library function names: \(library.functionNames)")
```

### 2. Shaders.metal - Uniform Flow Test Pattern

**Replaced spaceflight_shader output with diagnostic:**
```metal
fragment float4 spaceflight_shader(
    VertexOut in [[stage_in]],
    constant ShaderUniforms& uniforms [[buffer(0)]]
) {
    // DIAGNOSTIC TEST: Check if uniforms are flowing
    if (uniforms.intensity > 0.0) {
        return float4(1.0, 0.0, 0.0, 1.0); // RED = uniforms working
    }
    return float4(0.0, 1.0, 0.0, 1.0);     // GREEN = uniforms zeroed
}
```

The original starfield code is preserved in comments below the test pattern.

## Expected Outcomes

### Scenario A: RED SCREEN ✓ (Success)
**What you see:** Solid red window

**Diagnosis:** Uniforms are flowing correctly!
- Draw loop is running ✓
- Pipeline is configured ✓
- Uniforms are non-zero ✓
- Shader is executing ✓

**Console output:**
```
>>> Renderer Heartbeat: Frame 60 processing successfully.
=== FIRST FRAME UNIFORMS ===
Resolution: SIMD2<Float>(1280.0, 720.0)
Intensity: 0.5
Speed: 1.2
Depth: 2.0
```

**Next step:** Remove diagnostic code and restore original starfield shader.

### Scenario B: GREEN SCREEN ⚠ (Uniform Problem)
**What you see:** Solid green window

**Diagnosis:** Uniforms are zeroed!
- Draw loop is running ✓
- Pipeline is configured ✓
- Uniforms are ZERO ✗
- Shader is executing ✓

**Problem:** Alignment or buffer binding issue
- Check console for "Uniform buffer pointer: 0x..."
- Verify `setFragmentBuffer` is being called
- Check if buffer contents are actually being written

**Console should show:**
```
>>> Renderer Heartbeat: Frame 60 processing successfully.
=== FIRST FRAME UNIFORMS ===
Resolution: SIMD2<Float>(0.0, 0.0)
Intensity: 0.0
```

**Fix:** Buffer is not being updated or bound correctly.

### Scenario C: BLACK SCREEN ✗ (Draw Loop Problem)
**What you see:** Pitch black window

**Diagnosis:** Draw loop not executing or shader not compiling!

**Check console for:**
- "ERROR: No drawable available"
- "ERROR: Failed to create command buffer"
- "ERROR: Failed to find fragment function: spaceflight_shader"

**No heartbeat logs = draw loop never runs**

**Possible causes:**
1. MTKView delegate not set
2. MTKView.isPaused = true
3. Shader compilation failed
4. Pipeline creation failed

### Scenario D: PARTIAL RED (Flashing/Intermittent)
**What you see:** Flickering between red and black

**Diagnosis:** Drawable or buffer intermittently unavailable

**Console shows:**
```
ERROR: No drawable available (frame 45)
>>> Renderer Heartbeat: Frame 60 processing successfully.
ERROR: No drawable available (frame 73)
```

**Fix:** Check Metal device state, drawable acquisition timing.

## Console Output to Monitor

### Initialization Phase
```
MetalRenderer initializing...
Metal library created
Library function names: ["vertex_main", "spaceflight_shader", ...]
Shader functions loaded: vertex_main, spaceflight_shader
Pipeline state created successfully
Uniform buffer created: 48 bytes
Uniform buffer pointer: 0x...
MetalRenderer initialized successfully
Target frame rate: 60 FPS
```

### Runtime Phase (Every Second)
```
>>> Renderer Heartbeat: Frame 60 processing successfully.
>>> Renderer Heartbeat: Frame 120 processing successfully.
>>> Renderer Heartbeat: Frame 180 processing successfully.
```

### Keyboard Interaction
```
Key pressed: 49
Typing reaction triggered: 0.5
```

## Build and Test Steps

1. **Clean Build Folder**: Cmd+Shift+K
2. **Build**: Cmd+B (check for Metal shader compilation errors)
3. **Run**: Cmd+R
4. **Open Console**: View → Debug Area → Show Debug Area (Cmd+Shift+Y)
5. **Watch for:**
   - Initialization logs
   - Heartbeat every second
   - First frame uniform dump
   - Any ERROR messages

## After Diagnostic

### If RED (Success):
1. Open `Presets/Shaders/Shaders.metal`
2. Delete the diagnostic test block (lines 119-124)
3. Uncomment the original starfield code (lines 127-163)
4. Rebuild and run
5. Should see starfield with working animation

### If GREEN (Uniform Flow Broken):
1. Check buffer binding in MetalRenderer.swift
2. Verify alignment with:
   ```swift
   print("Uniform alignment: \(MemoryLayout<ShaderUniforms>.alignment)")
   ```
3. Try explicit alignment attribute in ShaderTypes.h:
   ```c
   struct __attribute__((aligned(16))) ShaderUniforms { ... };
   ```

### If BLACK (Pipeline Broken):
1. Check console for specific error
2. Verify shader compilation in build log
3. Check MTKView delegate assignment
4. Verify Metal device is available

## Verification Checklist

Before building, verify in Xcode:
- [ ] `Presets/Shaders/Shaders.metal` has target membership ✓
- [ ] Build Phases → Compile Sources includes `Shaders.metal` ✓
- [ ] No build errors (red indicators) in Xcode
- [ ] Console area is visible (Cmd+Shift+Y)

## Expected Timeline

- **Frame 0**: First frame logs, uniform dump
- **Frame 60**: First heartbeat (1 second)
- **Frame 120**: Second heartbeat (2 seconds)
- Color appears **immediately** on frame 0

If no color after 3 seconds and no heartbeat, the draw loop is stalled.
