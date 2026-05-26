# PRD — Premium Terminal Shader Engine

## 1. Product name

Working name: Premium Terminal Shader Engine.

## 2. One-line summary

A macOS headless daemon that streams Metal-rendered shader frames directly to iTerm2's native background image property, providing premium animated backgrounds with five cinematic presets, strict readability protection, subtle typing reactivity, and Homebrew-based installation.

## 3. Product objective

Build a polished terminal-background visual engine that runs as a headless background daemon and streams GPU-rendered frames directly into iTerm2's native background system, delivering premium and immersive visuals while staying deliberately subtle so terminal text remains readable at all times.

## 4. Success criteria

The project is successful when all of the following are true:
- The app installs through Homebrew.
- The app launches successfully on supported macOS systems.
- The app renders all five presets.
- The backgrounds remain terminal-safe and readable.
- The visuals feel premium, cinematic, and fluid.
- Typing produces a subtle, physical reaction in the scene.
- The codebase is clean, modular, and maintainable.

## 5. Core user experience

The user installs the daemon via Homebrew, launches it as a background service, selects a preset, and gets a live animated shader background rendered natively within their iTerm2 terminal window. The daemon runs headlessly, streams Metal-rendered frames at 60 FPS to a local image file, and syncs with iTerm2's background property. The animation should always feel active and spatial, but never dominate the foreground text.

Keyboard shortcuts (Cmd+Shift+1 to cycle presets, Cmd+Shift+O for settings) trigger actions in the daemon, which may spawn temporary overlay panels for settings UI when needed. Note: Modified from original Cmd+1 and Cmd+, due to conflicts with iTerm2's built-in shortcuts.

## 6. Supported presets

### 6.1 Spaceflight
A true 3D starfield with strong depth cues, forward motion, anti-aliased particles, and a realistic warp-through-space feel.

### 6.2 Night-Sky-Flight
A volumetric night cloudscape with soft ray-marched gradients, low contrast, and a calm cinematic atmosphere.

### 6.3 Morning-Sky-Flight
A bright dawn cloudscape with soft amber light, clean atmospheric scattering, and preserved terminal readability.

### 6.4 Ocean-Wave-Flight
A 3D ocean plane with smooth wave displacement, depth perspective, and subtle crest shimmer.

### 6.5 Aurora-Drift
A 3D aurora simulation with sweeping luminous curtains, organic folds, and soft green-purple movement.

## 7. Visual rules

The following rules apply to every preset:
- Keep contrast low enough for terminal readability.
- Use premium, desaturated color grading.
- Prefer depth and atmosphere over flashy brightness.
- Keep motion smooth and continuous.
- Avoid noisy composition behind text-heavy areas.
- Make the visuals feel cohesive across presets.

## 8. Interaction rules

### 8.1 Time-based motion
The shader scene must continuously evolve over time.

### 8.2 Typing response
Typing must cause subtle reactive motion, such as:
- small shockwaves,
- slight velocity pulses,
- soft distortions,
- gentle brightness changes.

### 8.3 Interaction boundaries
Typing reactivity must never become distracting or reduce readability.

## 9. Technical stack

- Language: Swift
- Graphics: Metal (headless rendering)
- Frame output: Metal texture → CGImage → PNG file stream
- Terminal integration: iTerm2 native background image property
- Distribution: Homebrew tap
- Platform: macOS
- Architecture: Background daemon with optional settings overlay

## 10. Architecture requirements

The codebase must be modular and explicitly separated into:
- daemon lifecycle layer,
- headless rendering layer,
- frame export layer,
- iTerm2 sync layer,
- preset layer,
- packaging layer.

### 10.1 Daemon lifecycle layer
Handles background service lifecycle, settings persistence, preset selection, keyboard monitoring, and optional settings UI overlay spawning. Runs as `.accessory` activation policy (no dock icon, no persistent window).

### 10.2 Headless rendering layer
Handles Metal rendering without an on-screen MTKView. Uses offscreen render targets, frame timing, uniforms, and shader execution. Runs at 60 FPS targeting a headless Metal texture.

### 10.3 Frame export layer
Converts Metal texture output to CGImage/NSImage, writes frames to `~/.config/iTerm2ShaderCLI/frame.png` at 60 FPS, and manages file I/O performance.

### 10.4 iTerm2 sync layer
Monitors frame writes and triggers iTerm2 background image updates using native iTerm2 APIs or escape sequences to sync the terminal background with the latest rendered frame.

### 10.5 Preset layer
Each preset must be implemented as a separate module or file using a shared interface.

### 10.6 Packaging layer
Handles command-line installation and update flow through Homebrew.

## 11. Preset interface requirement

Every preset must expose the same basic interface:
- name
- default parameters
- render entry point
- typing-reactive behavior hook
- optional performance tuning values

Do not invent different interfaces for each preset.

## 12. Configuration parameters

Each preset may expose only these core adjustable parameters:
- intensity
- speed
- depth
- contrast
- color temperature
- glow
- typing-reactivity strength

Do not add unrelated settings in version 1.

## 13. Performance requirements

The daemon and rendering pipeline must be efficient and suitable for everyday MacBook use, running continuously in the background.

Required performance principles:
- minimize CPU work per frame,
- prefer GPU-friendly procedural math,
- avoid unnecessary redraws,
- reuse Metal buffers, textures, and resources,
- optimize file I/O for frame export (avoid blocking the render loop),
- keep shader passes simple unless complexity is clearly justified,
- minimize frame export overhead (consider texture-to-PNG conversion cost),
- throttle rendering when iTerm2 is occluded or minimized,
- profile before optimizing.

## 14. Readability requirements

Readability is mandatory.

The app must:
- keep the terminal legible across presets,
- avoid bright overexposed areas,
- maintain usable text contrast,
- default to conservative settings,
- allow intensity reduction if needed.

## 15. Packaging requirements

The project must be installable through a Homebrew tap.

The packaging workflow must support:
- install,
- update,
- uninstall,
- versioned releases,
- clear usage instructions.

## 16. Scope boundaries

### In scope
- Swift macOS headless daemon
- Metal offscreen rendering
- Frame export pipeline (Metal texture → CGImage → PNG)
- iTerm2 native background integration
- Five presets
- Typing reaction
- Settings UI overlay (spawned on demand)
- Homebrew install flow
- Clean modular codebase

### Out of scope for version 1
- Other terminal emulators (iTerm2 only)
- Overlay window architecture
- Marketplace
- Third-party shader plugins
- Custom shader editor
- Cross-platform support
- Mobile support
- Terminal emulator replacement

## 17. Implementation milestones

### Milestone 1 (COMPLETED)
Project scaffold, app shell, Metal renderer, one working preset.

### Milestone 2 (COMPLETED)
Shared preset interface and settings model.

### Milestone 3 (COMPLETED)
All five presets implemented.

### Milestone 4 (COMPLETED)
Typing reaction and readability tuning.

### Milestone 5 (COMPLETED)
Settings UI and preview.

### Milestone 6 (COMPLETED)
Homebrew tap and packaging.

### Milestone 7 (IN PROGRESS — ARCHITECTURAL PIVOT)
Convert to headless daemon architecture:
- Remove AppKit window/overlay layer
- Implement headless Metal rendering (offscreen render targets)
- Build frame export pipeline (Metal texture → CGImage → PNG at 60 FPS)
- Implement iTerm2 background sync mechanism
- Preserve keyboard shortcuts and settings UI (spawn overlay on demand)
- Update daemon lifecycle to run as `.accessory` background service
- Validate performance and stability

### Milestone 8
Final stability, cleanup, and release readiness.

## 18. Acceptance tests

A build is acceptable only if all of the following pass:
- daemon launches headlessly without crashing,
- daemon runs as background service (no dock icon, no persistent window),
- each preset renders correctly to offscreen Metal texture,
- frame export pipeline writes frames at stable 60 FPS to `~/.config/iTerm2ShaderCLI/frame.png`,
- iTerm2 background syncs with exported frames in real-time,
- typing reaction works and triggers visual changes in iTerm2 background,
- terminal content remains readable,
- keyboard shortcuts (Cmd+1, Cmd+,) trigger daemon actions,
- settings UI overlay spawns and dismisses correctly,
- install works via Homebrew,
- update path is documented,
- code structure remains modular.

## 19. Definition of done

The project is done when a user can install it with Homebrew, launch the daemon as a background service, choose one of the five presets, and use iTerm2 with a premium animated shader background rendered natively within the terminal window that remains subtle, stable, and readable. The daemon must run headlessly, stream frames at 60 FPS, and sync seamlessly with iTerm2's background system.