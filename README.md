# Premium Terminal Shader Engine for iTerm2

A high-performance macOS daemon that renders cinematic animated shader backgrounds directly in iTerm2. Built with Swift and Metal for smooth 45 FPS animation with five beautiful presets.

![Version](https://img.shields.io/badge/version-2026.05.28-blue)
![Platform](https://img.shields.io/badge/platform-macOS%2013.0%2B-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)

> **v2026.05.28 Released!** Major stability and performance update. Fixed daemon crashes, eliminated black artifacts, and optimized for smooth rendering! 🚀✨

## ✨ Features

- **5 Cinematic Shader Presets**:
  - 🚀 **Spaceflight** - 3D starfield with warp-speed motion
  - 🌙 **Night-Sky-Flight** - Dark cosmic sky with glowing stars and drifting clouds
  - 🌅 **Morning-Sky-Flight** - Realistic bright blue morning sky
  - 🌊 **Ocean-Wave-Flight** - Deep ocean blues with rolling waves
  - 🌆 **Evening-Sky-Flight** - Sunset gradient with clouds drifting across the sky

- **Blazing Fast Performance**: 
  - 45 FPS smooth rendering (optimized for efficiency)
  - 5-8% CPU usage on Apple Silicon
  - ~30 MB memory footprint
  - No lag or stuttering
  
- **Rock Solid Stability**: 
  - Daemon runs indefinitely without crashes
  - Unlimited preset switches
  - Fixed black artifact glitches
  
- **Terminal-Safe**: Low contrast design maintains text readability
- **Easy Controls**: Simple CLI commands for all operations
- **Auto-Start Support**: Add to shell startup for seamless experience

## 📦 Installation

### Via Homebrew (Recommended)

```bash
# Add the tap
brew tap yatharth023/tap

# Install iTerm2 Shader CLI
brew install iterm2-shader-cli

# Start the shader
iterm2-shader start
```

See [INSTALL.md](INSTALL.md) for detailed installation instructions and troubleshooting.

## 🚀 Usage

### Basic Commands

```bash
# Start the shader daemon
iterm2-shader start

# Stop the shader daemon
iterm2-shader stop

# Switch to next preset
iterm2-shader next

# Switch to previous preset
iterm2-shader prev

# List all available presets
iterm2-shader list
```

### Auto-Start on Terminal Launch

Add to your `~/.zshrc` or `~/.bash_profile`:

```bash
# Start shader if not already running
if ! pgrep -x "iterm2-shader-engine" > /dev/null; then
    iterm2-shader start
fi
```

## 🎨 Shader Presets

### 🚀 Spaceflight
Classic 3D starfield with depth and forward motion. Creates a warp-through-space experience perfect for coding sessions.

### 🌙 Night-Sky-Flight
Deep dark cosmic backdrop with glowing stars and realistic white clouds drifting right-to-left. Perfect for night coding sessions.

### 🌅 Morning-Sky-Flight  
Realistic bright blue morning sky with pure white fluffy clouds. Perfect for a fresh, energizing start to your day.

### 🌊 Ocean-Wave-Flight
Deep ocean blues with rolling waves and cyan highlights on wave crests. Features optimized multi-layer wave system for smooth performance.

### 🌆 Evening-Sky-Flight
Beautiful sunset gradient with realistic clouds drifting right-to-left. Transitions smoothly from deep purple to warm amber at the horizon.

## ⚙️ iTerm2 Configuration

For the best experience:

1. **Open iTerm2 Preferences** → Profiles → Window
2. **Background Image Blending:** Set to 40-60% (recommended: 50%)
3. **Blur:** Off (shader provides its own blur)
4. **Transparency:** 0% (keep window opaque)

See [INSTALL.md](INSTALL.md) for detailed configuration instructions.

## 🔧 Requirements

- **macOS**: 13.0+ (Ventura or later)
- **iTerm2**: 3.4+
- **Hardware**: Apple Silicon or Intel Mac with Metal support
- **Homebrew**: Latest version (for installation)

## 🏗️ Architecture

```
iTerm2ShaderCLI/
├── App/                           # Daemon controller
│   ├── main.swift                 # Entry point
│   ├── DaemonController.swift     # Signal handling & preset management
│   └── Settings/
│       └── SettingsManager.swift  # Persistent settings
├── Rendering/                     # Metal rendering pipeline
│   ├── HeadlessMetalRenderer.swift  # 45 FPS GPU renderer
│   ├── FrameExporter.swift          # Optimized PNG export
│   ├── ITerm2Bridge.swift           # 24 FPS iTerm2 updates
│   └── ShaderTypes.swift            # Shader uniforms
├── Presets/                       # Shader implementations
│   ├── Shaders/
│   │   └── Shaders.metal            # All 5 GPU shaders
│   ├── SpaceflightPreset.swift
│   ├── NightSkyFlightPreset.swift
│   ├── MorningSkyFlightPreset.swift
│   ├── OceanWaveFlightPreset.swift
│   └── EveningSkyFlightPreset.swift
├── Packaging/
│   └── iterm2-shader              # CLI wrapper script
└── build.sh                       # Build script
```

## 🛠️ Development

### Building from Source

```bash
# Clone the repository
git clone https://github.com/yatharth023/iTerm2Shader.git
cd iTerm2Shader

# Build
./build.sh

# Install locally
cp dist/iterm2-shader-engine /opt/homebrew/bin/
cp dist/default.metallib /opt/homebrew/bin/
cp dist/iterm2-shader /opt/homebrew/bin/
chmod +x /opt/homebrew/bin/iterm2-shader*

# Run
iterm2-shader start
```

### Development Guidelines

- **Terminal readability first** - All presets must maintain text visibility
- **Performance matters** - Target 45 FPS with minimal CPU usage
- **Stability critical** - Daemon must run indefinitely without crashes
- **Clean code** - Follow Swift best practices

### Key Technical Details

- **Rendering**: Metal GPU shaders at 45 FPS
- **Resolution**: 1280×800 (optimized for performance)
- **Color Space**: sRGB with optimized PNG compression
- **iTerm2 Sync**: AppleScript at 24 FPS (reduced overhead)
- **Threading**: Async GPU execution with proper synchronization
- **Signal Handling**: USR1/USR2 for preset switching, TERM for shutdown

## 📝 Version History

### v2026.05.28 (June 2, 2026) - Stability & Performance Update

**🐛 Critical Bug Fixes:**
- Fixed daemon crashing after 3-4 preset switches
- Fixed black artifacts/glitches appearing over shader
- Fixed Homebrew installation "metal formula not found" error
- Removed incompatible parent process death detection

**⚡ Performance Optimizations:**
- Optimized render resolution: 1920×1200 → 1280×800 (56% fewer pixels)
- Balanced frame rate: 45 FPS (smooth with lower overhead)
- Reduced iTerm2 updates: 24 FPS (less AppleScript overhead)
- Optimized PNG compression (0.8 quality, no alpha)
- CPU usage: 15-20% → 5-8% on Apple Silicon
- Memory: 40 MB → 30 MB

**🔧 Technical Improvements:**
- Proper GPU synchronization to prevent artifacts
- Removed blocking GPU waits where possible
- Optimized frame export pipeline
- Improved error handling and stability

**📦 Distribution:**
- Cleaner repository structure
- Updated documentation (INSTALL.md)
- New SHA256: `88f674dd139c5ac1f10335494514225377d85b5a3bd5a4149bfbdc6b92adfde9`

## 📊 Performance Metrics

| Metric | Value |
|--------|-------|
| Frame Rate | 45 FPS |
| CPU Usage | 5-8% (Apple Silicon) |
| Memory | ~30 MB |
| Resolution | 1280×800 |
| GPU Usage | 15-20% |
| Battery Impact | Minimal (~5-8% extra drain) |

## 📄 License

MIT License - See LICENSE file for details

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

**Before contributing:**
1. Test all 5 presets for stability
2. Verify smooth 45 FPS performance
3. Ensure no memory leaks or crashes
4. Check daemon can handle 20+ preset switches

## 🐛 Issues & Support

Found a bug? Please open an issue on [GitHub Issues](https://github.com/yatharth023/iTerm2Shader/issues)

**Include in your report:**
- macOS version
- iTerm2 version
- Which preset has the issue
- Screenshot if visual bug
- Steps to reproduce

## 📚 Documentation

- **`README.md`** - This file
- **`INSTALL.md`** - Detailed installation and setup guide
- **`build.sh`** - Build script

## 🙏 Acknowledgments

Built with:
- **Swift** - Application framework
- **Metal** - GPU-accelerated shader rendering
- **iTerm2** - Terminal emulator
- **AppleScript** - iTerm2 background synchronization
- **Homebrew** - Distribution and package management

## ⭐ Star History

If you find this project useful, please consider giving it a star! ⭐

---

**Made with ❤️ for developers who love beautiful terminals**

*v2026.05.28 - Stable, fast, and artifact-free!*
