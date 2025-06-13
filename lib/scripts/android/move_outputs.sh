#!/bin/bash

# Move Outputs Script
# This script moves APK and AAB files to an output folder in the project root

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/output"

echo -e "${BLUE}📦 Moving build outputs to output folder...${NC}"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Define source paths
APK_SRC="$PROJECT_ROOT/android/app/build/outputs/apk/release/app-release.apk"
AAB_SRC="$PROJECT_ROOT/android/app/build/outputs/bundle/release/app-release.aab"

# Move APK if it exists
if [ -f "$APK_SRC" ]; then
    cp "$APK_SRC" "$OUTPUT_DIR/"
    echo -e "${GREEN}✅ APK moved to $OUTPUT_DIR/app-release.apk${NC}"
else
    echo -e "${YELLOW}⚠️  APK not found at $APK_SRC${NC}"
fi

# Move AAB if it exists
if [ -f "$AAB_SRC" ]; then
    cp "$AAB_SRC" "$OUTPUT_DIR/"
    echo -e "${GREEN}✅ AAB moved to $OUTPUT_DIR/app-release.aab${NC}"
else
    echo -e "${YELLOW}⚠️  AAB not found at $AAB_SRC${NC}"
fi

# List files in output directory
echo -e "${BLUE}📋 Files in output directory:${NC}"
if [ -d "$OUTPUT_DIR" ] && [ "$(ls -A "$OUTPUT_DIR")" ]; then
    ls -la "$OUTPUT_DIR"
else
    echo -e "${YELLOW}No files found in output directory${NC}"
fi

echo -e "${GREEN}✅ Output files moved successfully!${NC}" 