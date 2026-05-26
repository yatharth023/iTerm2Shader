# Premium Terminal Shader Engine for iTerm2

A high-performance macOS application that renders cinematic animated shader backgrounds directly in iTerm2. Built with Swift and Metal for smooth 60 FPS animation with five beautiful presets.

![Version](https://img.shields.io/badge/version-0.8.0-blue)
![Platform](https://img.shields.io/badge/platform-macOS%2013.0%2B-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)

## ✨ Features

- **5 Cinematic Shader Presets**:
  - 🚀 **Spaceflight** - 3D starfield with forward motion
  - 🌙 **Night-Sky-Flight** - Dark cosmic sky with glowing stars and drifting clouds
  - 🌅 **Morning-Sky-Flight** - Realistic bright blue morning sky
  - 🌊 **Ocean-Wave-Flight** - Rolling deep ocean waves
  - 🌆 **Evening-Sky-Flight** - Sunless sunset gradient (purple to amber)

- **Performance Optimized**: Smooth 60 FPS rendering with 45 FPS iTerm2 updates
- **Terminal-Safe**: Low contrast, text-first design
- **Typing Reactive**: Subtle motion reacts to your typing
- **Keyboard Shortcuts**: Quick preset switching (Cmd+1) and settings (Cmd+,)

## 📦 Installation

### Via Homebrew (Recommended)

```bash
brew tap YOUR_USERNAME/tap
brew install premium-terminal-shader
PremiumTerminalShader &
```

### Manual Installation

1. Download the latest release from [Releases](https://github.com/YOUR_USERNAME/iTerm2ShaderCLI/releases)
2. Extract and move to Applications:
   ```bash
   tar -xzf PremiumTerminalShader-*.tar.gz
   mv PremiumTerminalShader.app /Applications/
   ```
3. Run:
   ```bash
   /Applications/PremiumTerminalShader.app/Contents/MacOS/PremiumTerminalShader &
   ```

## 🚀 Usage

Once started, the shader will automatically appear as your iTerm2 background within 2 seconds.

### Keyboard Shortcuts
- `Cmd+1` - Cycle through shader presets
- `Cmd+,` - Open settings panel

### Customization
Adjust intensity, speed, contrast, and other parameters through the settings panel.

## 🎨 Shader Presets

### Spaceflight
A 3D starfield with depth and forward motion, creating a warp-through-space experience.

### Night-Sky-Flight
Deep dark cosmic backdrop with glowing stars featuring radiant halos, and realistic white clouds drifting right-to-left across the sky.

### Morning-Sky-Flight  
Realistic bright blue morning sky with pure white fluffy clouds - perfect for a fresh start to your day.

### Ocean-Wave-Flight
Deep ocean blues with rolling waves, cyan highlights on crests, and realistic water movement.

### Evening-Sky-Flight
Beautiful sunless sunset gradient transitioning from deep purple at the zenith through twilight blue to warm amber at the horizon.

## 🔧 Requirements

- macOS 13.0+ (Ventura or later)
- iTerm2 3.0.0+
- Apple Silicon or Intel Mac

## 🏗️ Architecture

```
├── App/                    # Application lifecycle and daemon control
├── Rendering/              # Metal rendering pipeline
│   ├── HeadlessMetalRenderer.swift
│   ├── FrameExporter.swift
│   ├── ITerm2Bridge.swift
│   └── ShaderTypes.swift
├── Presets/                # Shader implementations
│   ├── Shaders/
│   │   └── Shaders.metal
│   ├── SpaceflightPreset.swift
│   ├── NightSkyFlightPreset.swift
│   ├── MorningSkyFlightPreset.swift
│   ├── OceanWaveFlightPreset.swift
│   └── EveningSkyFlightPreset.swift
└── dist/                   # Release builds
```

## 🛠️ Development

### Building from Source

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/iTerm2ShaderCLI.git
cd iTerm2ShaderCLI

# Build with Xcode
xcodebuild -scheme PremiumTerminalShader -configuration Release \
  build CONFIGURATION_BUILD_DIR=dist

# Or use the build script
./build.sh
```

### Development Guidelines

- **Terminal readability first** - All presets must maintain text visibility
- **Performance matters** - Target 60 FPS rendering
- **Follow the PRD** - See `PRD.md` for product specifications
- **Clean code** - See `CLAUDE.md` for implementation rules

## 📝 Version History

### v0.8.0 (Latest) - Major Performance & Color Fix Update
- 🎨 Fixed critical BGRA color bug (all colors now accurate)
- ⚡ 3× smoother animation (45 FPS iTerm2 updates)
- 🚀 2× faster rendering (60 FPS internal)
- ✨ Enhanced all shader visuals
- 🔧 Optimized shader performance (25-40% improvement)

## 📄 License

MIT License - See LICENSE file for details

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 🐛 Issues

Found a bug? Please open an issue on [GitHub Issues](https://github.com/YOUR_USERNAME/iTerm2ShaderCLI/issues)

## 📚 Documentation

- `PRD.md` - Product requirements and specifications
- `CLAUDE.md` - Implementation guidelines for AI assistance
- `DEPLOYMENT.md` - Deployment and release process
- `RELEASE_v0.8.0_READY.md` - Current release information