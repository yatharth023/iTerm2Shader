# PRD — Premium Terminal Shader Engine

## 1. Product name

Working name: Premium Terminal Shader Engine.

## 2. One-line summary

A macOS Swift + Metal application that renders premium animated shader backgrounds for terminal use, with five cinematic presets, strict readability protection, subtle typing reactivity, and Homebrew-based installation.

## 3. Product objective

Build a polished terminal-background visual engine that feels premium and immersive while staying deliberately subtle so terminal text remains readable at all times.

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

The user installs the app, launches it, selects a preset, and gets a live animated shader background behind their terminal workflow. The animation should always feel active and spatial, but never dominate the foreground text.

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
- Graphics: Metal
- Distribution: Homebrew tap
- Platform: macOS

## 10. Architecture requirements

The codebase must be modular and explicitly separated into:
- application layer,
- rendering layer,
- preset layer,
- packaging layer.

### 10.1 Application layer
Handles app lifecycle, settings, preset selection, preview, and persistence.

### 10.2 Rendering layer
Handles frame timing, uniforms, rendering pipeline, shader execution, and performance-sensitive work.

### 10.3 Preset layer
Each preset must be implemented as a separate module or file using a shared interface.

### 10.4 Packaging layer
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

The renderer must be efficient and suitable for everyday MacBook use.

Required performance principles:
- minimize CPU work per frame,
- prefer GPU-friendly procedural math,
- avoid unnecessary redraws,
- reuse buffers and resources,
- keep shader passes simple unless complexity is clearly justified,
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
- Swift macOS app
- Metal rendering
- Five presets
- Typing reaction
- Settings UI
- Live preview
- Homebrew install flow
- Clean modular codebase

### Out of scope for version 1
- marketplace
- third-party shader plugins
- custom shader editor
- cross-platform support
- mobile support
- terminal emulator replacement

## 17. Implementation milestones

### Milestone 1
Project scaffold, app shell, Metal renderer, one working preset.

### Milestone 2
Shared preset interface and settings model.

### Milestone 3
All five presets implemented.

### Milestone 4
Typing reaction and readability tuning.

### Milestone 5
Settings UI and preview.

### Milestone 6
Homebrew tap and packaging.

### Milestone 7
Stability, cleanup, and release readiness.

## 18. Acceptance tests

A build is acceptable only if all of the following pass:
- app launches without crashing,
- each preset renders correctly,
- typing reaction works,
- terminal content remains readable,
- install works via Homebrew,
- update path is documented,
- code structure remains modular.

## 19. Definition of done

The project is done when a user can install it with Homebrew, launch it, choose one of the five presets, and use the terminal with a premium animated shader background that remains subtle, stable, and readable.