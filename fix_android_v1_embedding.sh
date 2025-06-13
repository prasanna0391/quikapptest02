#!/bin/bash

# Standalone Android V1 Embedding Fix Script
# Run this script from the project root to fix any v1 embedding issues

echo "🔧 Android V1 Embedding Fix Script"
echo "=================================="
echo "This script will automatically detect and fix any Android v1 embedding issues."
echo ""

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found. Please run this script from the Flutter project root."
    exit 1
fi

# Run the fix script
if [ -f "lib/scripts/android/fix_v1_embedding.sh" ]; then
    echo "🚀 Running v1 embedding fix..."
    lib/scripts/android/fix_v1_embedding.sh
else
    echo "❌ Error: fix_v1_embedding.sh not found. Please ensure the script exists."
    exit 1
fi

echo ""
echo "✅ V1 embedding fix completed!"
echo "💡 You can now run your build script: lib/scripts/android/main.sh" 