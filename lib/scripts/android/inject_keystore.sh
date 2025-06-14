#!/usr/bin/env bash

set -euo pipefail
echo "🔐 Starting keystore injection..."

# --- START: Debugging Block from previous step ---
echo "-------------------------------------------------"
echo "🔍 Verifying received signing credentials from API..."
echo "   - KEY_STORE URL: '${KEY_STORE}'"
echo "   - CM_KEY_ALIAS: '${CM_KEY_ALIAS}'"
echo "   - CM_KEYSTORE_PASSWORD length: ${#CM_KEYSTORE_PASSWORD}"
echo "   - CM_KEY_PASSWORD length: ${#CM_KEY_PASSWORD}"

if [ -z "${KEY_STORE}" ] || [ -z "${CM_KEYSTORE_PASSWORD}" ] || [ -z "${CM_KEY_ALIAS}" ] || [ -z "${CM_KEY_PASSWORD}" ]; then
  echo "❌ CRITICAL ERROR: One or more signing variables are empty. Please check the JSON payload in your API call."
  exit 1
fi
echo "✅ All signing variables appear to be present."
echo "-------------------------------------------------"
# --- END: Debugging Block ---

: "${KEY_STORE:?Missing KEY_STORE}"
: "${CM_KEYSTORE_PASSWORD:?Missing CM_KEYSTORE_PASSWORD}"
: "${CM_KEY_ALIAS:?Missing CM_KEY_ALIAS}"
: "${CM_KEY_PASSWORD:?Missing CM_KEY_PASSWORD}"

mkdir -p android

# --- START: New Robust Download Logic ---
echo "📥 Downloading keystore to android/keystore.jks..."
OUTPUT_PATH="android/keystore.jks"

# Try downloading with curl first
if curl -fsSL -o "$OUTPUT_PATH" "$KEY_STORE"; then
    echo "✅ Keystore downloaded successfully using curl."
else
    echo "⚠️ curl failed. Trying wget as a fallback..."
    # If curl fails, try wget
    if wget -O "$OUTPUT_PATH" "$KEY_STORE"; then
        echo "✅ Keystore downloaded successfully using wget."
    else
        # If wget fails, check its exit code for an SSL error (code 5)
        exit_code=$?
        if [ $exit_code -eq 5 ]; then
            echo "⚠️ wget failed with an SSL error. Retrying with --no-check-certificate..."
            if wget --no-check-certificate -O "$OUTPUT_PATH" "$KEY_STORE"; then
                echo "✅ Keystore downloaded successfully using wget (no SSL check)."
            else
                echo "❌ FATAL: All download methods failed, including wget without SSL check."
                exit 1
            fi
        else
            echo "❌ FATAL: Download failed with a non-SSL error (wget exit code: $exit_code)."
            exit 1
        fi
    fi
fi

# Final check to ensure the file exists
if [ ! -f "$OUTPUT_PATH" ]; then
    echo "❌ FATAL: Keystore file does not exist after download attempts."
    exit 1
fi
# --- END: New Robust Download Logic ---

[[ -f "$OUTPUT_PATH" ]] && echo "✅ keystore.jks is present"

echo "📝 Writing android/key.properties..."
cat <<EOF > android/key.properties
storeFile=keystore.jks
storePassword=$CM_KEYSTORE_PASSWORD
keyAlias=$CM_KEY_ALIAS
keyPassword=$CM_KEY_PASSWORD
EOF
[[ -f android/key.properties ]] && echo "✅ key.properties written"

# --- START: NEW BLOCK TO DISPLAY FILE CONTENT ---
echo "-------------------------------------------------"
echo "🔍 Displaying contents of android/key.properties:"
cat android/key.properties
echo "-------------------------------------------------"
# --- END: NEW BLOCK ---