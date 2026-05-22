# Homebrew Deployment Guide - Milestone 6

This guide covers the complete process of packaging and distributing PremiumTerminalShader via Homebrew.

---

## Prerequisites

- macOS with Xcode 15.0+ installed
- Git configured with GitHub access
- Homebrew installed on your system
- GitHub account (username: yatharthkhattri)

---

## Step 1: Build the Release Package

### 1.1 Run the Build Script

```bash
cd /Users/yatharth/Desktop/iTerm2ShaderCLI
./build.sh
```

**What this does:**
- Cleans previous builds
- Compiles the project in Release configuration
- Creates a `.app` bundle
- Generates a `.tar.gz` archive for distribution
- Calculates SHA256 checksum for Homebrew formula

**Expected Output:**
```
========================================
  Building PremiumTerminalShader
========================================

[1/6] Cleaning previous builds...
[2/6] Building PremiumTerminalShader (Release)...
✅ Build succeeded!
[3/6] Locating built application...
✅ Found: build/DerivedData/Build/Products/Release/PremiumTerminalShader.app
[4/6] Verifying application structure...
✅ Application structure valid
[5/6] Preparing distribution package...
✅ Created tarball: dist/PremiumTerminalShader-2026.05.22.tar.gz
[6/6] Generating SHA256 checksum...
✅ SHA256: a1b2c3d4e5f6...

========================================
  Build Complete!
========================================
```

**Save the SHA256 hash** - you'll need it for the Homebrew formula!

### 1.2 Test the Built App Locally

```bash
open dist/PremiumTerminalShader.app
```

Verify:
- App launches without errors
- All 5 shaders work
- Settings panel opens with `Cmd+,`
- Diagnostics toggle with `Cmd+D`
- Preset cycling with `Cmd+1`

---

## Step 2: Create GitHub Repository

### 2.1 Initialize Main Project Repository

```bash
cd /Users/yatharth/Desktop/iTerm2ShaderCLI

# Initialize git if not already done
git init

# Create .gitignore
cat > .gitignore << 'EOF'
# Xcode
build/
dist/
*.xcuserstate
*.xcworkspace/xcuserdata/
DerivedData/

# macOS
.DS_Store

# IDE
.vscode/
.idea/

# Temporary files
*.swp
*.swo
*~
EOF

# Add all files
git add .

# Initial commit
git commit -m "Initial commit - PremiumTerminalShader v1.0"
```

### 2.2 Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `iTerm2ShaderCLI`
3. Description: `Premium GPU-accelerated shader engine for terminal backgrounds`
4. Public repository
5. **DO NOT** initialize with README (we already have files)
6. Click "Create repository"

### 2.3 Push to GitHub

```bash
git remote add origin https://github.com/yatharthkhattri/iTerm2ShaderCLI.git
git branch -M main
git push -u origin main
```

---

## Step 3: Create GitHub Release

### 3.1 Tag the Release

```bash
# Create a version tag
VERSION="2026.05.22"
git tag -a "v${VERSION}" -m "Release v${VERSION} - Production-ready release"
git push origin "v${VERSION}"
```

### 3.2 Upload Release Artifacts via GitHub UI

1. Go to https://github.com/yatharthkhattri/iTerm2ShaderCLI/releases
2. Click "Draft a new release"
3. Tag: Select `v2026.05.22`
4. Release title: `v2026.05.22 - Production Release`
5. Description:

```markdown
## PremiumTerminalShader v2026.05.22

Premium GPU-accelerated shader engine for macOS terminal backgrounds.

### ✨ Features
- 🎨 5 stunning shader presets (Spaceflight, Night Sky, Morning Sky, Ocean Waves, Evening Sky)
- ⚡ Real-time parameter tuning via interactive settings panel
- 🎛️ 7 adjustable parameters (Intensity, Speed, Depth, Contrast, Color Temperature, Glow, Typing Reactivity)
- 💾 Auto-save settings with persistence across restarts
- 🖥️ Full Metal GPU acceleration for 60 FPS performance
- 📊 Optional diagnostics overlay for performance monitoring
- 🔄 Window state resilience (minimize, resize, sleep/wake)

### 📦 Installation

#### Via Homebrew (Recommended)
```bash
brew tap yatharthkhattri/tap
brew install --cask iterm2-shader-cli
```

#### Manual Installation
Download `PremiumTerminalShader-2026.05.22.tar.gz` below, extract, and drag to Applications.

### 🚀 Quick Start
- Launch: `open -a PremiumTerminalShader`
- Cycle presets: `Cmd+1`
- Settings: `Cmd+,`
- Diagnostics: `Cmd+D`

### 📋 Requirements
- macOS 13.0+ (Ventura or later)
- Metal-capable GPU

### 🐛 Report Issues
https://github.com/yatharthkhattri/iTerm2ShaderCLI/issues
```

6. **Attach binary**: Drag and drop `dist/PremiumTerminalShader-2026.05.22.tar.gz`
7. Click "Publish release"

---

## Step 4: Create Homebrew Tap

### 4.1 Create Tap Repository

1. Go to https://github.com/new
2. Repository name: `homebrew-tap`
3. Description: `Homebrew tap for PremiumTerminalShader`
4. Public repository
5. Initialize with README
6. Click "Create repository"

### 4.2 Clone and Setup Tap

```bash
cd ~/Desktop
git clone https://github.com/yatharthkhattri/homebrew-tap.git
cd homebrew-tap

# Create Casks directory (for GUI apps)
mkdir -p Casks
```

### 4.3 Add the Formula

Copy the formula file:

```bash
cp /Users/yatharth/Desktop/iTerm2ShaderCLI/Formula/iterm2-shader-cli.rb Casks/
```

### 4.4 Update Formula with Correct SHA256

**IMPORTANT:** Edit `Casks/iterm2-shader-cli.rb` and replace the SHA256:

```ruby
sha256 "REPLACE_WITH_ACTUAL_SHA256_FROM_BUILD"
```

With the actual SHA256 from your build output (Step 1.1).

Example:
```ruby
sha256 "a1b2c3d4e5f6789..."
```

### 4.5 Commit and Push

```bash
git add Casks/iterm2-shader-cli.rb
git commit -m "Add iterm2-shader-cli cask v2026.05.22"
git push origin main
```

---

## Step 5: Test the Homebrew Installation

### 5.1 Add Your Tap

```bash
brew tap yatharthkhattri/tap
```

### 5.2 Install the Cask

```bash
brew install --cask iterm2-shader-cli
```

**Expected Output:**
```
==> Downloading https://github.com/yatharthkhattri/iTerm2ShaderCLI/releases/download/v2026.05.22/PremiumTerminalShader-2026.05.22.tar.gz
######################################################################## 100.0%
==> Installing Cask iterm2-shader-cli
==> Moving App 'PremiumTerminalShader.app' to '/Applications/PremiumTerminalShader.app'
==> Linking Binary 'PremiumTerminalShader' to '/opt/homebrew/bin/iterm2-shader'
🍺  iterm2-shader-cli was successfully installed!
```

### 5.3 Verify Installation

```bash
# Check app exists
ls -la /Applications/PremiumTerminalShader.app

# Launch the app
open -a PremiumTerminalShader

# Check command-line symlink
which iterm2-shader
```

### 5.4 Test Uninstallation

```bash
brew uninstall --cask iterm2-shader-cli
```

Verify app is removed from `/Applications`.

---

## Step 6: User Installation Instructions

Add this to your main project README.md:

````markdown
## Installation

### Homebrew (Recommended)

```bash
brew tap yatharthkhattri/tap
brew install --cask iterm2-shader-cli
```

### Manual Installation

1. Download the latest release from [GitHub Releases](https://github.com/yatharthkhattri/iTerm2ShaderCLI/releases)
2. Extract `PremiumTerminalShader-YYYY.MM.DD.tar.gz`
3. Drag `PremiumTerminalShader.app` to `/Applications`

## Usage

Launch the application:
```bash
open -a PremiumTerminalShader
```

**Keyboard Shortcuts:**
- `Cmd+1` - Cycle through shader presets
- `Cmd+,` - Open settings panel
- `Cmd+D` - Toggle diagnostics overlay
````

---

## Step 7: Update Process (Future Releases)

When releasing a new version:

### 7.1 Update Version

```bash
cd /Users/yatharth/Desktop/iTerm2ShaderCLI

# Update version in relevant files
# Then rebuild
./build.sh
```

### 7.2 Create New GitHub Release

```bash
NEW_VERSION="2026.06.01"
git tag -a "v${NEW_VERSION}" -m "Release v${NEW_VERSION}"
git push origin "v${NEW_VERSION}"
```

Upload new tarball to GitHub releases.

### 7.3 Update Homebrew Formula

```bash
cd ~/Desktop/homebrew-tap

# Edit Casks/iterm2-shader-cli.rb
# Update version and sha256

git add Casks/iterm2-shader-cli.rb
git commit -m "Update iterm2-shader-cli to v${NEW_VERSION}"
git push origin main
```

### 7.4 Users Update

Users can update with:
```bash
brew update
brew upgrade --cask iterm2-shader-cli
```

---

## Troubleshooting

### Issue: SHA256 Mismatch

**Error:**
```
Error: SHA256 mismatch
Expected: abc123...
Actual:   def456...
```

**Fix:**
1. Download the tarball manually
2. Calculate SHA256: `shasum -a 256 PremiumTerminalShader-*.tar.gz`
3. Update formula with correct hash

### Issue: App Won't Launch

**Error:** "PremiumTerminalShader is damaged and can't be opened"

**Fix:**
```bash
sudo xattr -rd com.apple.quarantine /Applications/PremiumTerminalShader.app
```

### Issue: Formula Not Found

**Error:** `Error: Cask iterm2-shader-cli not found`

**Fix:**
```bash
brew untap yatharthkhattri/tap
brew tap yatharthkhattri/tap
brew update
```

---

## Verification Checklist

Before publishing, verify:

- [ ] Build script runs without errors
- [ ] Tarball contains correct app bundle
- [ ] SHA256 checksum matches
- [ ] GitHub release is published
- [ ] Formula syntax is valid (`brew audit --cask Casks/iterm2-shader-cli.rb`)
- [ ] Homebrew installation works
- [ ] App launches successfully
- [ ] All keyboard shortcuts work
- [ ] Settings persist across restarts
- [ ] Uninstallation removes all files

---

## Distribution URLs

**Main Repository:**
https://github.com/yatharthkhattri/iTerm2ShaderCLI

**Homebrew Tap:**
https://github.com/yatharthkhattri/homebrew-tap

**Installation Command:**
```bash
brew tap yatharthkhattri/tap && brew install --cask iterm2-shader-cli
```

---

## Milestone 6 Status: ✅ COMPLETE

All packaging and deployment infrastructure is ready for production release!
