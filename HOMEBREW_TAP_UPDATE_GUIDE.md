# Homebrew Tap Update Guide for v0.8.0

Complete instructions for updating your Homebrew tap repository with the v0.8.0 release.

## 📋 Prerequisites

**Before starting, ensure you have:**
- ✅ Created GitHub release v0.8.0
- ✅ Uploaded `PremiumTerminalShader-2026.05.26-v2.tar.gz` to the release
- ✅ Have the release URL from GitHub

## 📦 Release Information

```
Version:  0.8.0
File:     PremiumTerminalShader-2026.05.26-v2.tar.gz
Size:     304 KB
SHA256:   0ebc3374e0dcfb14557fe37105c0c46e24bf641e9c31858fc8cb2f8a3bb72ca7
```

## 🔗 GitHub Release URL Format

Your release URL should be:
```
https://github.com/YOUR_USERNAME/iTerm2ShaderCLI/releases/download/v0.8.0/PremiumTerminalShader-2026.05.26-v2.tar.gz
```

Replace `YOUR_USERNAME` with your actual GitHub username.

---

## 📝 Step-by-Step Instructions

### Step 1: Navigate to Your Homebrew Tap Repository

```bash
cd /path/to/your/homebrew-tap
# Example: cd ~/homebrew-tap
```

### Step 2: Update the Formula File

The formula file is typically located at:
```
Formula/premium-terminal-shader.rb
```

### Step 3: Edit the Formula

Open the formula file and update these fields:

#### A. Update Version Number

```ruby
# Change from:
version "0.7.1"  # or whatever your current version is

# Change to:
version "0.8.0"
```

#### B. Update Download URL

```ruby
# Change to:
url "https://github.com/YOUR_USERNAME/iTerm2ShaderCLI/releases/download/v0.8.0/PremiumTerminalShader-2026.05.26-v2.tar.gz"
```

**Important:** Replace `YOUR_USERNAME` with your actual GitHub username!

#### C. Update SHA256 Checksum

```ruby
# Change to:
sha256 "0ebc3374e0dcfb14557fe37105c0c46e24bf641e9c31858fc8cb2f8a3bb72ca7"
```

#### D. Update the Caveats (Release Notes)

Replace the entire `caveats` section with:

```ruby
def caveats
  <<~EOS
    Version 0.8.0 - Major Performance & Color Fix Update
    
    🎨 CRITICAL FIXES:
    - Fixed BGRA color bug (blue skies now actually blue!)
    - All shader colors now display accurately
    - Morning-Sky-Flight: Realistic bright blue (was orange)
    - Ocean-Wave-Flight: Deep ocean blues (was black/orange)
    
    ⚡ PERFORMANCE (3× smoother!):
    - iTerm2 updates: 15 → 45 FPS (3× improvement)
    - Internal rendering: 30 → 60 FPS (2× improvement)
    - All shaders optimized (25-40% faster)
    
    ✨ VISUAL IMPROVEMENTS:
    - Night-Sky: Glowing stars + white clouds moving right-to-left
    - Morning-Sky: Bright realistic blue morning sky
    - Evening-Sky: Sunless sunset gradient (purple → amber)
    - Ocean-Wave: Pure deep ocean blues
    
    🚀 TO START:
      PremiumTerminalShader &
    
    The animated shader appears in iTerm2 within 2 seconds.
    
    ⌨️  KEYBOARD SHORTCUTS:
      Cmd+1  - Cycle through presets
      Cmd+,  - Open settings panel
    
    📝 LOGS:
      /tmp/iterm2shader.log
    
    🐛 TROUBLESHOOTING:
      - Ensure iTerm2 3.0.0+ is installed
      - Check logs: tail -f /tmp/iterm2shader.log
      - Verify background appears in iTerm2 Preferences
  EOS
end
```

---

## 📄 Complete Formula Example

Here's what your complete formula file should look like:

```ruby
class PremiumTerminalShader < Formula
  desc "Premium terminal shader engine for iTerm2 with animated backgrounds"
  homepage "https://github.com/YOUR_USERNAME/iTerm2ShaderCLI"
  url "https://github.com/YOUR_USERNAME/iTerm2ShaderCLI/releases/download/v0.8.0/PremiumTerminalShader-2026.05.26-v2.tar.gz"
  sha256 "0ebc3374e0dcfb14557fe37105c0c46e24bf641e9c31858fc8cb2f8a3bb72ca7"
  version "0.8.0"
  license "MIT"

  depends_on :macos => :ventura  # macOS 13.0+
  depends_on :arch => [:arm64, :x86_64]

  def install
    prefix.install "PremiumTerminalShader.app"
    
    # Create convenience binary in bin/
    (bin/"PremiumTerminalShader").write <<~EOS
      #!/bin/bash
      exec "#{prefix}/PremiumTerminalShader.app/Contents/MacOS/PremiumTerminalShader" "$@"
    EOS
    
    # Make binary executable
    chmod 0755, bin/"PremiumTerminalShader"
    
    # Install documentation
    doc.install "BUILD_INFO.txt" if File.exist? "BUILD_INFO.txt"
  end

  def caveats
    <<~EOS
      Version 0.8.0 - Major Performance & Color Fix Update
      
      🎨 CRITICAL FIXES:
      - Fixed BGRA color bug (blue skies now actually blue!)
      - All shader colors now display accurately
      - Morning-Sky-Flight: Realistic bright blue (was orange)
      - Ocean-Wave-Flight: Deep ocean blues (was black/orange)
      
      ⚡ PERFORMANCE (3× smoother!):
      - iTerm2 updates: 15 → 45 FPS (3× improvement)
      - Internal rendering: 30 → 60 FPS (2× improvement)
      - All shaders optimized (25-40% faster)
      
      ✨ VISUAL IMPROVEMENTS:
      - Night-Sky: Glowing stars + white clouds moving right-to-left
      - Morning-Sky: Bright realistic blue morning sky
      - Evening-Sky: Sunless sunset gradient (purple → amber)
      - Ocean-Wave: Pure deep ocean blues
      
      🚀 TO START:
        PremiumTerminalShader &
      
      The animated shader appears in iTerm2 within 2 seconds.
      
      ⌨️  KEYBOARD SHORTCUTS:
        Cmd+1  - Cycle through presets
        Cmd+,  - Open settings panel
      
      📝 LOGS:
        /tmp/iterm2shader.log
      
      🐛 TROUBLESHOOTING:
        - Ensure iTerm2 3.0.0+ is installed
        - Check logs: tail -f /tmp/iterm2shader.log
        - Verify background appears in iTerm2 Preferences
    EOS
  end

  test do
    assert_predicate prefix/"PremiumTerminalShader.app/Contents/MacOS/PremiumTerminalShader", :exist?
    assert_predicate prefix/"PremiumTerminalShader.app/Contents/MacOS/PremiumTerminalShader", :executable?
  end
end
```

**Remember:** Replace `YOUR_USERNAME` with your actual GitHub username in the `homepage` and `url` lines!

---

## 🔄 Step 4: Commit and Push Changes

```bash
# Add the modified formula
git add Formula/premium-terminal-shader.rb

# Commit with descriptive message
git commit -m "Update to v0.8.0 - Major performance & color fix update

- Fixed critical BGRA color bug (all colors accurate)
- 3× smoother animation (15→45 FPS iTerm2 updates)
- 2× faster rendering (30→60 FPS internal)
- Enhanced all shader visuals
- Optimized shader performance (25-40% improvement)

Release: https://github.com/YOUR_USERNAME/iTerm2ShaderCLI/releases/tag/v0.8.0
SHA256: 0ebc3374e0dcfb14557fe37105c0c46e24bf641e9c31858fc8cb2f8a3bb72ca7"

# Push to GitHub
git push origin main
```

---

## ✅ Step 5: Test the Installation

After pushing, test that users can install it:

```bash
# Uninstall old version (if installed)
brew uninstall premium-terminal-shader

# Update Homebrew
brew update

# Tap your repository (if not already tapped)
brew tap YOUR_USERNAME/tap

# Install the new version
brew install premium-terminal-shader

# Verify version
PremiumTerminalShader --version  # Should show 0.8.0

# Test run
PremiumTerminalShader &

# Verify it works
# - Check iTerm2 background appears
# - Morning sky should be BLUE
# - Ocean should be BLUE
# - Animation should be smooth (45 FPS)
```

---

## 🐛 Troubleshooting

### Issue: "Checksum Mismatch"

```bash
# Recalculate the checksum
shasum -a 256 /path/to/PremiumTerminalShader-2026.05.26-v2.tar.gz

# Update the sha256 line in your formula with the new checksum
```

### Issue: "URL Not Found"

- Verify the GitHub release v0.8.0 exists
- Verify the tarball is uploaded to the release
- Check the URL format matches exactly:
  ```
  https://github.com/YOUR_USERNAME/iTerm2ShaderCLI/releases/download/v0.8.0/PremiumTerminalShader-2026.05.26-v2.tar.gz
  ```

### Issue: "Formula Audit Fails"

```bash
# Run audit to see warnings/errors
brew audit --new-formula premium-terminal-shader

# Run style check
brew style premium-terminal-shader

# Fix any issues reported
```

### Issue: "Installation Fails"

```bash
# Try verbose installation to see detailed errors
brew install --verbose premium-terminal-shader

# Check the logs
cat ~/Library/Logs/Homebrew/premium-terminal-shader/install.log
```

---

## 📊 Verification Checklist

After completing all steps, verify:

- [ ] Formula version is `0.8.0`
- [ ] SHA256 matches: `0ebc3374e0dcfb14557fe37105c0c46e24bf641e9c31858fc8cb2f8a3bb72ca7`
- [ ] GitHub URL is correct and accessible
- [ ] Formula installs without errors
- [ ] App binary is executable
- [ ] App starts successfully: `PremiumTerminalShader &`
- [ ] iTerm2 background appears within 2 seconds
- [ ] Morning-Sky is BLUE (not orange)
- [ ] Ocean-Wave is BLUE (not orange/black)
- [ ] Animation is smooth (no lag)
- [ ] Keyboard shortcuts work (Cmd+1, Cmd+,)

---

## 📝 Formula File Location

Typical Homebrew tap structure:
```
homebrew-tap/
├── Formula/
│   └── premium-terminal-shader.rb  ← Edit this file
└── README.md
```

If you have a different structure, adjust accordingly.

---

## 🎯 Quick Reference

**What to change in the formula:**

| Field | Old Value | New Value |
|-------|-----------|-----------|
| `version` | `"0.7.1"` (or current) | `"0.8.0"` |
| `url` | Old release URL | `v0.8.0/PremiumTerminalShader-2026.05.26-v2.tar.gz` |
| `sha256` | Old checksum | `"0ebc337..."` (full checksum above) |
| `caveats` | Old release notes | New release notes (see above) |

---

## 🚀 After Update

Once the formula is updated and pushed:

1. **Announce the release** (optional):
   - Twitter, Reddit, etc.
   - "v0.8.0 released with major color fix and 3× performance improvement!"

2. **Monitor for issues**:
   - Watch GitHub issues
   - Check Homebrew formula repository for PRs

3. **Update main README** (if needed):
   - Ensure installation instructions are current

---

## 📞 Support

If users encounter issues:

1. **Check logs**: `tail -f /tmp/iterm2shader.log`
2. **Verify iTerm2 version**: Must be 3.0.0+
3. **Check macOS version**: Must be 13.0+ (Ventura)
4. **GitHub Issues**: Point users to your issues page

---

## ✨ Summary

**You need to:**
1. Edit `Formula/premium-terminal-shader.rb` in your homebrew-tap repo
2. Update version to `0.8.0`
3. Update URL to point to v0.8.0 release
4. Update SHA256 checksum
5. Update caveats with new release notes
6. Commit and push changes
7. Test installation

**That's it!** Users can now `brew install premium-terminal-shader` to get v0.8.0! 🎉
