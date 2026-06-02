# Installation Guide

Complete installation and setup instructions for iTerm2 Shader CLI.

---

## 📋 Requirements

- **macOS:** 13.0 (Ventura) or later
- **Terminal:** iTerm2 3.4 or later
- **GPU:** Metal-compatible (all Macs from 2012+)
- **Homebrew:** Latest version

---

## 🆕 For New Users

### Step 1: Install Homebrew (if not installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Step 2: Add the Tap

```bash
brew tap yatharth023/tap
```

### Step 3: Install iTerm2 Shader CLI

```bash
brew install iterm2-shader-cli
```

### Step 4: Start the Shader

```bash
iterm2-shader start
```

🎉 **Done!** Your terminal now has a beautiful animated shader background.

---

## 🔄 For Existing Users (Upgrading)

### Update to Latest Version

```bash
# Update Homebrew
brew update

# Upgrade iTerm2 Shader CLI
brew upgrade iterm2-shader-cli
```

### If Update Doesn't Work

Sometimes Homebrew caches old versions. Force a clean install:

```bash
# Stop the daemon
iterm2-shader stop

# Uninstall old version
brew uninstall iterm2-shader-cli

# Clear Homebrew cache
rm -rf "$(brew --cache)/downloads/*iterm2-shader*"

# Reinstall
brew install iterm2-shader-cli

# Start the new version
iterm2-shader start
```

---

## 🎮 Usage

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

### Available Presets

1. **Spaceflight** - Star field with depth parallax
2. **Night-Sky-Flight** - Starry night with floating clouds
3. **Morning-Sky-Flight** - Golden sunrise atmosphere
4. **Ocean-Wave-Flight** - Realistic ocean wave simulation
5. **Evening-Sky-Flight** - Sunset with warm colors

Cycle through presets using `iterm2-shader next` to find your favorite!

---

## ⚙️ iTerm2 Configuration

For the best experience, configure iTerm2 settings:

### 1. Open iTerm2 Preferences

`iTerm2 → Preferences → Profiles → Window`

### 2. Adjust Background Settings

- **Background Image Blending:** `40-60%` (recommended: 50%)
- **Blur:** `Off` (shader provides its own blur)
- **Transparency:** `0%` (keep window opaque)

### 3. Text Visibility

`Profiles → Colors → Minimum Contrast`

- Set to: `10-20%` for better text readability over animated backgrounds

### 4. Restart iTerm2

After changing settings, restart iTerm2 for best results.

---

## 🔧 Troubleshooting

### Shader Not Appearing

1. **Check if daemon is running:**
   ```bash
   ps aux | grep iterm2-shader-engine
   ```

2. **Restart the daemon:**
   ```bash
   iterm2-shader stop
   iterm2-shader start
   ```

3. **Check iTerm2 background image path:**
   ```bash
   cat ~/.config/iTerm2ShaderCLI/frame.png
   ```
   If this file exists, the shader is working.

### Daemon Stops After Switching Presets

This was a bug in older versions. **Make sure you have version `2026.05.28` or later:**

```bash
brew info iterm2-shader-cli
```

If you see an older version, follow the "For Existing Users" upgrade steps above.

### Performance Issues / Lag

1. **Check CPU usage:**
   ```bash
   ps aux | grep iterm2-shader-engine | grep -v grep
   ```
   Should be around 8-12% on Apple Silicon.

2. **Verify Metal support:**
   ```bash
   system_profiler SPDisplaysDataType | grep Metal
   ```
   Should show "Metal: Supported"

3. **Reduce iTerm2 blending:**
   Lower the "Background Image Blending" to 40% in iTerm2 preferences.

### Command Not Found

If you get `zsh: command not found: iterm2-shader`:

```bash
# Check if Homebrew bin is in PATH
echo $PATH | grep homebrew

# If not, add it to your shell profile
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Try again
iterm2-shader start
```

---

## 🗑️ Uninstallation

### Remove iTerm2 Shader CLI

```bash
# Stop the daemon
iterm2-shader stop

# Uninstall via Homebrew
brew uninstall iterm2-shader-cli

# Remove configuration files
rm -rf ~/.config/iTerm2ShaderCLI
```

### Remove the Tap (optional)

```bash
brew untap yatharth023/tap
```

---

## 🚀 Performance

### Current Version (2026.05.28)

- **Frame Rate:** 60 FPS
- **CPU Usage:** 8-12% (Apple Silicon M1+)
- **Memory:** ~40 MB
- **GPU Usage:** 15-20%
- **Battery Impact:** Minimal (~5-8% extra drain)

### Optimization Tips

If you want to save battery:

**Lower Frame Rate** (requires manual modification):
- Edit `/opt/homebrew/bin/iterm2-shader-engine` source
- Change `targetFPS` from 60 to 30
- Rebuild with `./build.sh`

**Lower iTerm2 Update Rate:**
- Already optimized to 30 FPS (iTerm2 updates)
- No user action needed

---

## 📚 Additional Resources

- **GitHub Repository:** https://github.com/yatharth023/iTerm2Shader
- **Report Issues:** https://github.com/yatharth023/iTerm2Shader/issues
- **Homebrew Tap:** https://github.com/yatharth023/homebrew-tap

---

## 🎨 Customization

### Creating Your Own Presets

Advanced users can create custom shader presets:

1. **Fork the repository**
2. **Add a new preset file** in `Presets/` directory
3. **Implement the `ShaderPreset` protocol**
4. **Add your shader function** in `Presets/Shaders/Shaders.metal`
5. **Rebuild with `./build.sh`**

See existing presets like `SpaceflightPreset.swift` for examples.

---

## ❓ FAQ

### Q: Does this work with other terminals?

**A:** No, iTerm2 only. It uses iTerm2's background image API.

### Q: Can I adjust the shader intensity?

**A:** Not via CLI yet. Parameters are preset-specific. Future versions may add configuration commands.

### Q: Does it drain battery?

**A:** Minimal impact (~5-8% extra). The daemon is optimized for efficiency.

### Q: Can I run multiple presets at once?

**A:** No, only one shader can run at a time.

### Q: Does it work on Intel Macs?

**A:** Yes, as long as you have macOS 13.0+ and Metal support (2012+ Macs).

### Q: Why does it write to `~/.config/iTerm2ShaderCLI/`?

**A:** The shader renders to a PNG file that iTerm2 loads as a background image. This is the communication mechanism.

---

## 🏆 Credits

Built with:
- **Swift** - Core daemon and app logic
- **Metal** - GPU-accelerated shader rendering
- **Homebrew** - Distribution and installation

Developed by [Yatharth Khattri](https://github.com/yatharth023)

---

## 📝 License

See LICENSE file in the repository.

---

**Enjoy your premium terminal experience!** 🚀✨
