#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO"; exit 1' ERR

echo "🧹 Deleting old splash and logo assets..."

if [ -f assets/images/logo.png ]; then
  rm assets/images/logo.png
  echo "✅ Deleted: assets/images/logo.png"
else
  echo "⚠️ logo.png not found"
fi

echo "🚀 Started: Downloading logo from $LOGO_URL"

mkdir -p assets/images/

# Try downloading with SSL certificate check first (silent test)
wget --spider --quiet "$LOGO_URL"
if [ $? -ne 0 ]; then
  echo "⚠️ SSL verification failed. Retrying with --no-check-certificate..."
  WGET_OPTS="--no-check-certificate"
else
  WGET_OPTS=""
fi

# Attempt actual download
wget $WGET_OPTS -O assets/images/logo.png "$LOGO_URL"

# Check if the file was successfully downloaded
if [ ! -f assets/images/logo.png ]; then
  echo "❌ Error: Failed to download logo from $LOGO_URL"
  exit 1
fi

flutter pub get
echo "✅ Completed: Logo downloaded"
