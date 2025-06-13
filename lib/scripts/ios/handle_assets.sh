#!/usr/bin/env bash

set -euo pipefail

echo "🎨 Handling iOS app assets..."

# Check if required environment variables are set
if [ -z "${LOGO_URL:-}" ]; then
    echo "❌ Error: LOGO_URL environment variable is not set"
    exit 1
fi

if [ -z "${IS_SPLASH:-}" ]; then
    echo "❌ Error: IS_SPLASH environment variable is not set"
    exit 1
fi

# Set local variables
logo_url="$LOGO_URL"
is_splash="$IS_SPLASH"
splash_url="${SPLASH:-}"
splash_bg_url="${SPLASH_BG:-}"

echo "🧹 Deleting old splash and logo assets..."

# Use find with -delete for robustness
find assets/images/ -name "logo.png" -delete || true
find assets/images/ -name "splash.png" -delete || true
find assets/images/ -name "splash_bg.png" -delete || true
echo "✅ Deleted old assets (if they existed)."

echo "🚀 Started: Downloading logo from $logo_url"
mkdir -p assets/images/

# Use curl as it's generally preferred in CI environments
if ! curl -f -L -o assets/images/logo.png "$logo_url"; then
    echo "❌ Error: Failed to download logo from $logo_url"
    exit 1
fi
echo "✅ Completed: Logo downloaded to assets/images/logo.png"

echo "🚀 Generating launcher icons"
# Assumes flutter_launcher_icons is in dev_dependencies and configured in pubspec.yaml
if ! flutter pub run flutter_launcher_icons; then
    echo "❌ Failed to generate launcher icons. Is flutter_launcher_icons configured correctly in pubspec.yaml?"
    exit 1
fi
echo "✅ Launcher icons generated successfully"

if [ "$is_splash" = "true" ]; then
    echo "🚀 Started: Downloading splash assets"
    mkdir -p assets/images/ # Ensure directory exists

    # Download splash logo
    if [ -n "$splash_url" ]; then
        echo "⬇️ Downloading splash logo from: $splash_url"
        if ! curl -f -L -o assets/images/splash.png "$splash_url"; then
            echo "❌ Error: Failed to download SPLASH logo from $splash_url"
            exit 1
        fi
        echo "✅ Splash logo downloaded."
    else
        echo "⚠️ No SPLASH URL provided, using logo as splash"
        cp assets/images/logo.png assets/images/splash.png
        echo "✅ Copied logo to splash.png"
    fi

    # Download splash background (optional)
    if [ -n "$splash_bg_url" ]; then
        echo "⬇️ Downloading splash background from: $splash_bg_url"
        if ! curl -f -L -o assets/images/splash_bg.png "$splash_bg_url"; then
            echo "❌ Error: Failed to download SPLASH background from $splash_bg_url"
            # This might not be a fatal error depending on splash implementation, but report it.
            echo "⚠️ Warning: Failed to download splash background."
        else
            echo "✅ Splash background downloaded."
        fi
    else
        echo "ℹ️ No SPLASH_BG provided, skipping background download"
    fi

    echo "✅ Completed: Splash assets handled"
else
    echo "⏭️ Skipping splash asset download (IS_SPLASH != true)"
fi

# Ensure pubspec.yaml changes and downloaded assets are picked up
echo "📦 Running flutter pub get to ensure all dependencies are up to date..."
flutter pub get

echo "✅ iOS app assets handled successfully" 