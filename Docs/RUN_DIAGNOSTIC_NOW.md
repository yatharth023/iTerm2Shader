# RUN DIAGNOSTIC NOW

## What We Added

**Diagnostic test pattern that shows RED or GREEN to isolate the exact problem.**

### MetalRenderer.swift Changes
- ✓ Frame counter with heartbeat logging every 60 frames
- ✓ First frame uniform dump
- ✓ Error logging for every guard failure
- ✓ Library function listing

### Shaders.metal Changes
- ✓ Replaced starfield code with simple uniform test:
  - **RED screen** = uniforms working (intensity > 0)
  - **GREEN screen** = uniforms zeroed (intensity == 0)
  - **BLACK screen** = draw loop not running

## Build and Run

1. **Clean**: Cmd+Shift+K
2. **Build**: Cmd+B
3. **Run**: Cmd+R
4. **Open Console**: Cmd+Shift+Y

## What You'll See

### RED SCREEN = SUCCESS ✓
- Uniforms are flowing correctly
- Draw loop is running at 60 FPS
- Ready to restore starfield shader

**Console:**
```
=== FIRST FRAME UNIFORMS ===
Intensity: 0.5
Speed: 1.2
Depth: 2.0
>>> Renderer Heartbeat: Frame 60 processing successfully.
```

### GREEN SCREEN = UNIFORM PROBLEM ⚠
- Draw loop works
- Uniforms are zero
- Alignment or binding issue

**Console:**
```
=== FIRST FRAME UNIFORMS ===
Intensity: 0.0
Speed: 0.0
>>> Renderer Heartbeat: Frame 60 processing successfully.
```

### BLACK SCREEN = PIPELINE PROBLEM ✗
- Draw loop not running OR
- Shader not compiling OR
- Pipeline creation failed

**Console:**
```
ERROR: Failed to find fragment function: spaceflight_shader
```
OR no heartbeat logs at all.

## Next Steps

### If RED:
1. Open `Presets/Shaders/Shaders.metal`
2. Delete lines 119-124 (the test pattern)
3. Uncomment lines 127-163 (the original starfield)
4. Rebuild → Should see animated starfield

### If GREEN:
1. Report console output
2. Check uniform buffer binding
3. Verify alignment

### If BLACK:
1. Report console output
2. Check for specific ERROR messages
3. Verify shader compilation in build log

## Expected Console Output

```
=== APPLICATION LAUNCHING ===
=== SETTING UP WINDOW ===
Window isVisible: true
Metal device: Apple M1
MetalRenderer initializing...
Library function names: ["vertex_main", "spaceflight_shader"]
Shader functions loaded: vertex_main, spaceflight_shader
Pipeline state created successfully
Uniform buffer created: 48 bytes
MetalRenderer initialized successfully
=== FIRST FRAME UNIFORMS ===
Resolution: SIMD2<Float>(1280.0, 720.0)
Time: 0.0
Intensity: 0.5
Speed: 1.2
Depth: 2.0
Contrast: 0.25
============================
>>> Renderer Heartbeat: Frame 60 processing successfully.
>>> Renderer Heartbeat: Frame 120 processing successfully.
```

**BUILD NOW AND REPORT THE COLOR YOU SEE**
