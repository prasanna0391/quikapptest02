#!/usr/bin/env bash

set -euo pipefail
trap 'echo "❌ Error on line $LINENO"; exit 1' ERR

if [ "${IS_SPLASH:-false}" = "true" ]; then
  SPLASH_DIR="assets/images"

  if [ -f "$SPLASH_DIR/splash.png" ]; then
    rm "$SPLASH_DIR/splash.png"
    echo "✅ Deleted: $SPLASH_DIR/splash.png"
  else
    echo "⚠️ splash.png not found"
  fi

  echo "🚀 Started: Downloading splash assets"
  mkdir -p "$SPLASH_DIR"

  echo "⬇️ Downloading splash logo from: ${SPLASH:-<no URL provided>}"
  wget -O "$SPLASH_DIR/splash.png" "$SPLASH" || {
    echo "⚠️ Certificate issue or download failed. Retrying with --no-check-certificate..."
    wget --no-check-certificate -O "$SPLASH_DIR/splash.png" "$SPLASH"
  }

  if [ ! -f "$SPLASH_DIR/splash.png" ]; then
    echo "❌ Error: Failed to download splash logo"
    exit 1
  fi

  if [ -n "${SPLASH_BG:-}" ]; then
    echo "⬇️ Downloading splash background from: $SPLASH_BG"
    wget -O "$SPLASH_DIR/splash_bg.png" "$SPLASH_BG" || {
      echo "⚠️ Certificate issue or download failed. Retrying with --no-check-certificate..."
      wget --no-check-certificate -O "$SPLASH_DIR/splash_bg.png" "$SPLASH_BG"
    }

    if [ ! -f "$SPLASH_DIR/splash_bg.png" ]; then
      echo "❌ Error: Failed to download splash background"
      exit 1
    fi
  else
    echo "ℹ️ No SPLASH_BG provided, skipping background download"
  fi

  flutter pub get
  echo "✅ Completed: Splash assets downloaded"

else
  echo "⏭️ Skipping splash asset download (IS_SPLASH != true)"
fi
