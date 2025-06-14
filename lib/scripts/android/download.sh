#!/bin/bash

# Function to download file with retries
download_file() {
    local url="$1"
    local output_path="$2"
    local max_retries=${DOWNLOAD_MAX_RETRIES:-3}
    local retry_delay=${DOWNLOAD_RETRY_DELAY:-5}
    local attempt=1

    while [ $attempt -le $max_retries ]; do
        echo "📥 Downloading $url (Attempt $attempt/$max_retries)..."
        if curl -L "$url" -o "$output_path"; then
            echo "✅ Download successful: $output_path"
            return 0
        fi
        echo "⚠️ Download failed, retrying in $retry_delay seconds..."
        sleep $retry_delay
        attempt=$((attempt + 1))
    done

    echo "❌ Download failed after $max_retries attempts: $url"
    return 1
}

# Function to download splash assets
download_splash_assets() {
    echo "📥 Downloading splash assets..."
    
    # Create assets directory if it doesn't exist
    mkdir -p "$ASSETS_DIR"
    
    # Download splash image
    if [ ! -f "$SPLASH_IMAGE_PATH" ]; then
        if ! download_file "https://raw.githubusercontent.com/your-repo/splash.png" "$SPLASH_IMAGE_PATH"; then
            echo "⚠️ Failed to download splash image"
            return 1
        fi
    fi
    
    # Download splash background
    if [ ! -f "$SPLASH_BG_PATH" ]; then
        if ! download_file "https://raw.githubusercontent.com/your-repo/splash_bg.png" "$SPLASH_BG_PATH"; then
            echo "⚠️ Failed to download splash background"
            return 1
        fi
    fi
    
    echo "✅ Splash assets downloaded successfully"
    return 0
}

# Function to download app icon
download_app_icon() {
    echo "📥 Downloading app icon..."
    
    if [ ! -f "$APP_ICON_PATH" ]; then
        if ! download_file "https://raw.githubusercontent.com/your-repo/app_icon.png" "$APP_ICON_PATH"; then
            echo "⚠️ Failed to download app icon"
            return 1
        fi
    fi
    
    echo "✅ App icon downloaded successfully"
    return 0
}

# Main execution
if [ "$1" = "splash" ]; then
    download_splash_assets
elif [ "$1" = "icon" ]; then
    download_app_icon
else
    echo "Usage: $0 [splash|icon]"
    exit 1
fi 