#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Building PremiumTerminalShader${NC}"
echo -e "${GREEN}========================================${NC}"

# Configuration
PROJECT_NAME="PremiumTerminalShader"
SCHEME_NAME="PremiumTerminalShader"
CONFIGURATION="Release"
BUILD_DIR="build"
ARCHIVE_PATH="${BUILD_DIR}/${PROJECT_NAME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/Export"
DIST_DIR="dist"
VERSION=$(date +"%Y.%m.%d")

# Clean previous builds
echo -e "\n${YELLOW}[1/6] Cleaning previous builds...${NC}"
rm -rf "${BUILD_DIR}"
rm -rf "${DIST_DIR}"
mkdir -p "${BUILD_DIR}"
mkdir -p "${DIST_DIR}"

# Build the project (using default DerivedData location for reliability)
echo -e "\n${YELLOW}[2/6] Building ${SCHEME_NAME} (${CONFIGURATION})...${NC}"
xcodebuild \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME_NAME}" \
    -configuration "${CONFIGURATION}" \
    clean build \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    ONLY_ACTIVE_ARCH=NO \
    > "${BUILD_DIR}/build.log" 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed! Check ${BUILD_DIR}/build.log for details${NC}"
    tail -50 "${BUILD_DIR}/build.log"
    exit 1
fi

echo -e "${GREEN}✅ Build succeeded!${NC}"

# Locate the built app (using default DerivedData path)
echo -e "\n${YELLOW}[3/6] Locating built application...${NC}"

# Try multiple possible locations
DERIVED_DATA_BASE="${HOME}/Library/Developer/Xcode/DerivedData"
APP_PATH=$(find "${DERIVED_DATA_BASE}" -name "${PROJECT_NAME}.app" -path "*/Build/Products/${CONFIGURATION}/${PROJECT_NAME}.app" -type d 2>/dev/null | head -1)

if [ -z "${APP_PATH}" ] || [ ! -d "${APP_PATH}" ]; then
    echo -e "${RED}❌ Application not found${NC}"
    echo -e "${YELLOW}Searching in DerivedData...${NC}"
    find "${DERIVED_DATA_BASE}" -name "${PROJECT_NAME}.app" -type d 2>/dev/null | head -5
    exit 1
fi

echo -e "${GREEN}✅ Found: ${APP_PATH}${NC}"

# Verify the app structure
echo -e "\n${YELLOW}[4/6] Verifying application structure...${NC}"
if [ ! -f "${APP_PATH}/Contents/MacOS/${PROJECT_NAME}" ]; then
    echo -e "${RED}❌ Executable not found in app bundle${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Application structure valid${NC}"

# Copy to dist directory
echo -e "\n${YELLOW}[5/6] Preparing distribution package...${NC}"
cp -R "${APP_PATH}" "${DIST_DIR}/"

# Create tarball for Homebrew
cd "${DIST_DIR}"
TARBALL_NAME="${PROJECT_NAME}-${VERSION}.tar.gz"
tar -czf "${TARBALL_NAME}" "${PROJECT_NAME}.app"
cd ..

echo -e "${GREEN}✅ Created tarball: ${DIST_DIR}/${TARBALL_NAME}${NC}"

# Generate SHA256 for Homebrew formula
echo -e "\n${YELLOW}[6/6] Generating SHA256 checksum...${NC}"
SHA256=$(shasum -a 256 "${DIST_DIR}/${TARBALL_NAME}" | awk '{print $1}')

echo -e "${GREEN}✅ SHA256: ${SHA256}${NC}"

# Print summary
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Build Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\nDistribution files:"
echo -e "  📦 App bundle: ${DIST_DIR}/${PROJECT_NAME}.app"
echo -e "  📦 Tarball:    ${DIST_DIR}/${TARBALL_NAME}"
echo -e "\nHomebrew Formula Info:"
echo -e "  Version: ${VERSION}"
echo -e "  SHA256:  ${SHA256}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo -e "  1. Upload tarball to GitHub releases"
echo -e "  2. Update Homebrew formula with new version and SHA256"
echo -e "  3. Test installation: brew install --cask iterm2-shader-cli"

# Save build info
cat > "${DIST_DIR}/BUILD_INFO.txt" << EOF
Build Information
==================
Project: ${PROJECT_NAME}
Version: ${VERSION}
Configuration: ${CONFIGURATION}
Build Date: $(date)
SHA256: ${SHA256}

Installation:
  brew tap yatharthkhattri/tap
  brew install --cask iterm2-shader-cli
EOF

echo -e "\n${GREEN}✅ Build info saved to: ${DIST_DIR}/BUILD_INFO.txt${NC}"
