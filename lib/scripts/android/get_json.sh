#!/usr/bin/env bash

set -euo pipefail
trap 'echo "❌ JSON download failed on line $LINENO"; exit 1' ERR

echo "🔧 Starting Firebase JSON download step..."

if [ "${PUSH_NOTIFY:-false}" = "true" ]; then
  echo "✔ PUSH_NOTIFY=true, proceeding with JSON download."

  # Ensure directories exist
  mkdir -p android/app assets

  # Download function with retry and SSL check
  download_with_retry() {
    local url=$1
    local output=$2
    local max_retries=3
    local retry_delay=5
    local attempt=1
    local wget_opts=""

    echo "URL to download: $url"
    echo "Output path: $output"

    while [ $attempt -le $max_retries ]; do
      echo "➡️ Attempt $attempt to download $url"

      # Check SSL connection first
      if wget --spider --quiet "$url"; then
        wget_opts=""
      else
        echo "⚠️ SSL verification failed. Using --no-check-certificate"
        wget_opts="--no-check-certificate"
      fi

      # Download file
      if wget $wget_opts -O "$output" "$url"; then
        echo "✅ Successfully downloaded $output"
        return 0
      else
        echo "❌ Download failed on attempt $attempt"
      fi

      attempt=$((attempt + 1))
      if [ $attempt -le $max_retries ]; then
        echo "⏳ Waiting $retry_delay seconds before retry..."
        sleep $retry_delay
      fi
    done

    echo "🚨 Failed to download $url after $max_retries attempts."
    return 1
  }

  # Call download function with environment variable URL and target file
  download_with_retry "$firebase_config_android" "android/app/google-services.json"

  # Verify the file and copy to assets/
  if [ -f android/app/google-services.json ]; then
    echo "✅ google-services.json found"
    cp android/app/google-services.json assets/google-services.json
    echo "📂 Copied google-services.json to assets/"
  else
    echo "❌ google-services.json missing after download"
    exit 1
  fi

else
  echo "🚫 Firebase config skipped because PUSH_NOTIFY != true"
fi

echo "🎉 Firebase JSON download step completed."
