#!/usr/bin/env bash
set -euo pipefail

if [ -z "${ANDROID_HOME:-}" ]; then
  echo "❌ ANDROID_HOME is not set!"
  exit 1
fi
if [ -z "${FLUTTER_ROOT:-}" ]; then
  echo "❌ FLUTTER_ROOT is not set!"
  exit 1
fi

mkdir -p android
cat > android/local.properties <<EOF
sdk.dir=$ANDROID_HOME
flutter.sdk=$FLUTTER_ROOT
EOF

echo "✅ android/local.properties generated." 