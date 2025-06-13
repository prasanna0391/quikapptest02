#!/usr/bin/env bash
set -euo pipefail

# Automatically removes all MainActivity.kt/java files NOT matching the correct package path
# Requires: PKG_NAME environment variable

echo "🚀 Cleaning up conflicting MainActivity files..."

# --- Validate required env var ---
PKG_NAME="${PKG_NAME:?Environment variable PKG_NAME is required}"
PACKAGE_PATH="$(echo "$PKG_NAME" | tr '.' '/')"
EXPECTED_KT_PATH="android/app/src/main/kotlin/$PACKAGE_PATH/MainActivity.kt"
EXPECTED_JAVA_PATH="android/app/src/main/java/$PACKAGE_PATH/MainActivity.java"
MANIFEST_FILE="android/app/src/main/AndroidManifest.xml"

# --- Find and delete all invalid MainActivity files ---
find android/app/src/main \( -name "MainActivity.kt" -o -name "MainActivity.java" \) | while read -r file; do
  if [[ "$file" != "$EXPECTED_KT_PATH" && "$file" != "$EXPECTED_JAVA_PATH" ]]; then
    echo "🔍 Removing outdated MainActivity: $file"
    rm -f "$file"
  fi
done

echo "✅ Cleanup complete. Valid MainActivity path should be:"
echo "   - $EXPECTED_KT_PATH (or .java if using Java)"

# Optionally confirm result
if [[ -f "$EXPECTED_KT_PATH" || -f "$EXPECTED_JAVA_PATH" ]]; then
  echo "✨ MainActivity in correct location."
else
  echo "❌ MainActivity not found in expected package path! Please regenerate it."
  exit 1
fi

# --- Auto Regenerate using V2 embedding ---
echo "🔧 Re-generating MainActivity using Flutter V2 embedding..."
mkdir -p "$(dirname "$EXPECTED_KT_PATH")"
cat <<EOF > "$EXPECTED_KT_PATH"
package $PKG_NAME

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
EOF

echo "✅ MainActivity regenerated at $EXPECTED_KT_PATH"

# --- Patch AndroidManifest.xml to use V2 MainActivity ---
echo "📂 Updating AndroidManifest.xml..."
if [[ -f "$MANIFEST_FILE" ]]; then
  sed -i '' 's@android:name="io.flutter.app.FlutterActivity"@android:name=".MainActivity"@' "$MANIFEST_FILE" || true
  sed -i '' 's@android:name=".*MainActivity"@android:name=".MainActivity"@' "$MANIFEST_FILE"
  echo "✅ AndroidManifest.xml updated to reference .MainActivity"
else
  echo "❌ ERROR: AndroidManifest.xml not found at $MANIFEST_FILE"
  exit 1
fi
