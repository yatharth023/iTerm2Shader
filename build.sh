#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Building iterm2-shader-engine${NC}"
echo -e "${GREEN}  (Standalone UNIX Binary)${NC}"
echo -e "${GREEN}========================================${NC}"

PROJECT_NAME="iterm2-shader-engine"
CONFIGURATION="release"
BUILD_DIR="build"
DIST_DIR="dist"
VERSION="2026.05.27"

# Clean previous builds
echo -e "\n${YELLOW}[1/5] Cleaning previous builds...${NC}"
rm -rf "${BUILD_DIR}"
rm -rf "${DIST_DIR}"
mkdir -p "${BUILD_DIR}"
mkdir -p "${DIST_DIR}"

# Collect all Swift source files
echo -e "\n${YELLOW}[2/5] Compiling Metal shaders...${NC}"

# Compile .metal -> .metallib
xcrun metal -c Presets/Shaders/Shaders.metal -o "${BUILD_DIR}/Shaders.air"
xcrun metallib "${BUILD_DIR}/Shaders.air" -o "${BUILD_DIR}/default.metallib"

echo -e "${GREEN}✅ Metal library compiled${NC}"

# Compile Swift sources into a standalone binary
echo -e "\n${YELLOW}[3/5] Compiling Swift sources...${NC}"

SWIFT_FILES=(
    App/main.swift
    App/DaemonController.swift
    App/Settings/SettingsManager.swift
    Rendering/HeadlessMetalRenderer.swift
    Rendering/MetalRenderer.swift
    Rendering/FrameExporter.swift
    Rendering/ITerm2Bridge.swift
    Rendering/ShaderTypes.swift
    Presets/ShaderPreset.swift
    Presets/SpaceflightPreset.swift
    Presets/NightSkyFlightPreset.swift
    Presets/MorningSkyFlightPreset.swift
    Presets/OceanWaveFlightPreset.swift
    Presets/EveningSkyFlightPreset.swift
)

swiftc \
    -O \
    -whole-module-optimization \
    -import-objc-header Rendering/ShaderTypes.h \
    -sdk "$(xcrun --show-sdk-path)" \
    -target arm64-apple-macos13.0 \
    -framework Metal \
    -framework MetalKit \
    -framework CoreGraphics \
    -framework Foundation \
    -framework AppKit \
    -framework ImageIO \
    -framework UniformTypeIdentifiers \
    -o "${BUILD_DIR}/${PROJECT_NAME}" \
    "${SWIFT_FILES[@]}" \
    2>&1 | tee "${BUILD_DIR}/build.log"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed! Check ${BUILD_DIR}/build.log${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Binary compiled successfully${NC}"

# Verify the binary
echo -e "\n${YELLOW}[4/5] Verifying binary...${NC}"

if [ ! -f "${BUILD_DIR}/${PROJECT_NAME}" ]; then
    echo -e "${RED}❌ Binary not found at ${BUILD_DIR}/${PROJECT_NAME}${NC}"
    exit 1
fi

file "${BUILD_DIR}/${PROJECT_NAME}"
echo -e "${GREEN}✅ Binary verified${NC}"

# Package for distribution
echo -e "\n${YELLOW}[5/5] Packaging distribution...${NC}"

# Copy binary and metallib to dist
cp "${BUILD_DIR}/${PROJECT_NAME}" "${DIST_DIR}/"
cp "${BUILD_DIR}/default.metallib" "${DIST_DIR}/"

# Make binary executable
chmod +x "${DIST_DIR}/${PROJECT_NAME}"

# Create tarball
cd "${DIST_DIR}"
TARBALL_NAME="PremiumTerminalShader-${VERSION}.tar.gz"
tar -czf "${TARBALL_NAME}" "${PROJECT_NAME}" "default.metallib"
cd ..

echo -e "${GREEN}✅ Created tarball: ${DIST_DIR}/${TARBALL_NAME}${NC}"

# Generate SHA256
SHA256=$(shasum -a 256 "${DIST_DIR}/${TARBALL_NAME}" | awk '{print $1}')

echo -e "${GREEN}✅ SHA256: ${SHA256}${NC}"

# Print summary
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Build Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\nDistribution files:"
echo -e "  Binary:    ${DIST_DIR}/${PROJECT_NAME}"
echo -e "  Metallib:  ${DIST_DIR}/default.metallib"
echo -e "  Tarball:   ${DIST_DIR}/${TARBALL_NAME}"
echo -e "\nHomebrew Cask Info:"
echo -e "  Version: ${VERSION}"
echo -e "  SHA256:  ${SHA256}"

# Save build info
cat > "${DIST_DIR}/BUILD_INFO.txt" << EOF
Build Information
==================
Project: ${PROJECT_NAME}
Version: ${VERSION}
Configuration: ${CONFIGURATION}
Build Date: $(date)
SHA256: ${SHA256}
Architecture: arm64 (Apple Silicon)
Target: macOS 13.0+

Contents:
  - ${PROJECT_NAME} (standalone binary)
  - default.metallib (compiled Metal shaders)

Installation:
  brew tap yatharthkhattri/tap
  brew install --cask iterm2-shader-cli
EOF

echo -e "\n${GREEN}✅ Build info saved to: ${DIST_DIR}/BUILD_INFO.txt${NC}"
