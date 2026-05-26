# Premium Terminal Shader Engine for iTerm2

A high-performance macOS application that renders cinematic animated shader backgrounds directly in iTerm2. Built with Swift and Metal for smooth 60 FPS animation with five beautiful presets.

![Version](https://img.shields.io/badge/version-0.8.0-blue)
![Platform](https://img.shields.io/badge/platform-macOS%2013.0%2B-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)

> **v0.8.0 Released!** Major update with critical color fixes and 3× performance improvement. Morning skies are now actually blue! 🎨⚡

## ✨ Features

- **5 Cinematic Shader Presets**:
  - 🚀 **Spaceflight** - 3D starfield with warp-speed motion (35 optimized stars)
  - 🌙 **Night-Sky-Flight** - Dark cosmic sky with glowing stars and white clouds drifting right-to-left
  - 🌅 **Morning-Sky-Flight** - Realistic bright blue morning sky (NOW ACTUALLY BLUE!)
  - 🌊 **Ocean-Wave-Flight** - Deep ocean blues with rolling waves (NOW ACTUALLY BLUE!)
  - 🌆 **Evening-Sky-Flight** - Sunless sunset gradient with clouds drifting right-to-left (purple → amber)

- **Blazing Fast Performance**: 
  - 60 FPS internal rendering (2× faster than v0.7)
  - 45 FPS iTerm2 updates (3× faster than v0.7)
  - Optimized shaders (25-40% performance improvement)
  
- **Accurate Colors**: Fixed critical BGRA color bug - all shaders display true colors
- **Terminal-Safe**: Low contrast design maintains text readability
- **Typing Reactive**: Subtle motion responds to your typing
- **Customizable**: 7 adjustable parameters via settings panel
- **Keyboard Shortcuts**: Quick preset switching (Cmd+1) and settings (Cmd+,)

## 📦 Installation

### Via Homebrew (Recommended)

```bash
brew tap yatharth023/tap
brew install --cask iterm2-shader-cli
iterm2-shader &
```

### Manual Installation

1. Download the latest release from [Releases](https://github.com/yatharth023/iTerm2ShaderCLI/releases)
2. Extract and move to Applications:
   ```bash
   tar -xzf PremiumTerminalShader-2026.05.26-v2.tar.gz
   mv PremiumTerminalShader.app /Applications/
   ```
3. Run:
   ```bash
   /Applications/PremiumTerminalShader.app/Contents/MacOS/PremiumTerminalShader &
   ```
   Or simply:
   ```bash
   open -a PremiumTerminalShader
   ```

## 🚀 Usage

Once started, the shader automatically appears as your iTerm2 background within 2 seconds.

### Keyboard Shortcuts
- **`Cmd+1`** - Cycle through shader presets
- **`Cmd+,`** - Open settings panel with real-time preview

### Customization

The settings panel provides 7 adjustable parameters:
- **Intensity** - Overall brightness
- **Speed** - Animation speed
- **Depth** - 3D depth/parallax
- **Contrast** - Color contrast
- **Color Temperature** - Warm/cool color tone (Kelvin)
- **Glow** - Bloom/glow effect strength
- **Typing Reactivity** - How much motion responds to typing

All settings auto-save and persist across restarts.

### Launch Options

**Run as daemon** (recommended):
```bash
iterm2-shader &
```

**Run with logs**:
```bash
iterm2-shader
tail -f /tmp/iterm2shader.log
```

**Add to shell startup** (~/.zshrc or ~/.bash_profile):
```bash
iterm2-shader > /dev/null 2>&1 &
```

## 🎨 Shader Presets

### 🚀 Spaceflight
Classic 3D starfield with depth and forward motion. Features 35 optimized stars for smooth 60 FPS performance. Creates a warp-through-space experience perfect for coding sessions.

### 🌙 Night-Sky-Flight
Deep dark cosmic backdrop designed for maximum text readability. Features glowing stars with radiant halos and realistic white clouds drifting gracefully right-to-left across the sky. Perfect for night coding sessions.

### 🌅 Morning-Sky-Flight  
Realistic bright blue morning sky with pure white fluffy clouds. **Now displays actual blue colors** (fixed BGRA bug). Perfect for a fresh, energizing start to your day.

### 🌊 Ocean-Wave-Flight
Deep ocean blues with rolling waves, cyan highlights on wave crests, and realistic water movement. Features optimized 5-layer wave system for smooth performance. **Now displays true ocean blues** (was orange/black in v0.7).

### 🌆 Evening-Sky-Flight
Beautiful sunless sunset gradient with realistic clouds drifting right-to-left. Transitions smoothly from deep purple at the zenith through twilight blue to warm amber at the horizon. Multi-zone color palette creates a cinematic dusk atmosphere.

## 🔧 Requirements

- **macOS**: 13.0+ (Ventura or later)
- **iTerm2**: 3.0.0+
- **Hardware**: Apple Silicon or Intel Mac with Metal support

## 🏗️ Architecture

```
iTerm2ShaderCLI/
├── App/                           # Application lifecycle
│   ├── AppDelegate.swift          # Main app and menu bar
│   ├── DaemonController.swift     # Background daemon management
│   └── StatusBarController.swift  # Menu bar UI
├── Rendering/                     # Metal rendering pipeline
│   ├── HeadlessMetalRenderer.swift  # 60 FPS offscreen renderer
│   ├── FrameExporter.swift          # sRGB color space export
│   ├── ITerm2Bridge.swift           # 45 FPS iTerm2 sync via AppleScript
│   └── ShaderTypes.swift            # Shader uniform structures
├── Presets/                       # Shader implementations
│   ├── Shaders/
│   │   └── Shaders.metal            # All 5 shaders (BGRA color-corrected)
│   ├── SpaceflightPreset.swift      # 35 stars
│   ├── NightSkyFlightPreset.swift   # 60 stars + clouds
│   ├── MorningSkyFlightPreset.swift # Blue sky gradient
│   ├── OceanWaveFlightPreset.swift  # 5-layer waves
│   └── EveningSkyFlightPreset.swift # Sunset gradient
└── dist/                          # Release builds
    └── PremiumTerminalShader.app
```

## 🛠️ Development

### Building from Source

```bash
# Clone the repository
git clone https://github.com/yatharth023/iTerm2ShaderCLI.git
cd iTerm2ShaderCLI

# Build with Xcode
xcodebuild -scheme PremiumTerminalShader -configuration Release \
  build CONFIGURATION_BUILD_DIR=dist

# Or use the build script
./build.sh

# Run the app
open dist/PremiumTerminalShader.app
```

### Development Guidelines

- **Terminal readability first** - All presets must maintain text visibility
- **Performance matters** - Target 60 FPS rendering, 45 FPS iTerm2 updates
- **Follow the PRD** - See `PRD.md` for product specifications
- **Clean code** - See `CLAUDE.md` for implementation rules
- **Test colors** - Verify BGRA color order in all shader outputs

### Key Technical Details

- **Rendering**: Metal compute shaders running at 60 FPS
- **Color Space**: sRGB with non-premultiplied alpha
- **Color Order**: BGRA (Blue-Green-Red-Alpha) for Metal texture format
- **iTerm2 Sync**: AppleScript API at 45 FPS via cached compiled scripts
- **Threading**: `.userInteractive` QoS priority with triple command buffering

## 📝 Version History

### v0.8.0 (May 26, 2026) - Major Performance & Color Fix Update

**🎨 Critical Color Fixes:**
- Fixed BGRA color channel bug that caused all shaders to swap red/blue
- Morning-Sky-Flight: Now realistic bright blue (was orange/brown)
- Ocean-Wave-Flight: Deep ocean blues (was orange/black)
- All presets: Accurate color reproduction
- Changed color space from Device RGB to sRGB
- Fixed premultiplied alpha causing color corruption

**⚡ Performance Improvements (3× Smoother):**
- Internal rendering: 30 FPS → **60 FPS** (2× improvement)
- iTerm2 updates: 15 FPS → **45 FPS** (3× improvement)
- Spaceflight: 50 → 35 stars (30% faster)
- Night-Sky-Flight: 80 → 60 stars (25% faster)
- Ocean-Wave-Flight: 7 → 5 layers (40% faster)
- QoS priority upgrade to `.userInteractive`
- Added triple command buffering

**✨ Visual Enhancements:**
- Morning-Sky: Bright realistic blue morning sky
- Night-Sky: Glowing stars with radiant halos + white clouds moving right-to-left
- Evening-Sky: Sunless sunset gradient (purple → amber) + clouds drifting right-to-left
- Ocean-Wave: Pure deep ocean blues with cyan highlights
- All clouds: Pure white/neutral (no color bias)

**🔧 Technical Changes:**
- All shaders: Fixed BGRA color output order
- HeadlessMetalRenderer: 60 FPS target + triple buffering
- ITerm2Bridge: 45 FPS updates + `.userInteractive` priority
- FrameExporter: sRGB color space + non-premultiplied alpha
- Preset parameters: Optimized for performance and visual quality

**Files Modified:** 22 files including all shaders, rendering pipeline, and presets

## 📄 License

MIT License - See LICENSE file for details

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

**Before contributing:**
1. Read `PRD.md` for product requirements
2. Read `CLAUDE.md` for implementation guidelines
3. Test all 5 presets for correct colors (blues should be blue!)
4. Verify smooth 60 FPS performance

## 🐛 Issues & Support

Found a bug? Please open an issue on [GitHub Issues](https://github.com/yatharth023/iTerm2ShaderCLI/issues)

**Include in your report:**
- macOS version
- iTerm2 version
- Which preset has the issue
- Screenshot if visual bug
- Logs from `/tmp/iterm2shader.log`

## 📚 Documentation

- **`README.md`** - This file
- **`PRD.md`** - Product requirements and specifications
- **`CLAUDE.md`** - Implementation guidelines for AI assistance
- **`DEPLOYMENT.md`** - Deployment and release process
- **`RELEASE_v0.8.0_READY.md`** - v0.8.0 release information
- **`HOMEBREW_TAP_UPDATE_GUIDE.md`** - Homebrew tap update guide

## 🙏 Acknowledgments

Built with:
- **Swift** - Application framework
- **Metal** - GPU-accelerated shader rendering
- **iTerm2** - Terminal emulator
- **AppleScript** - iTerm2 background synchronization

## ⭐ Star History

If you find this project useful, please consider giving it a star! ⭐

---

**Made with ❤️ for developers who love beautiful terminals**

*v0.8.0 - Now with accurate colors and buttery smooth 60 FPS animation!*