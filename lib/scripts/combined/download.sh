#!/bin/bash

# Function to download file with retry mechanism
download_with_retry() {
    local url=$1
    local output_file=$2
    local max_retries=$DOWNLOAD_MAX_RETRIES
    local retry_count=0
    local delay=$DOWNLOAD_RETRY_DELAY

    while [ $retry_count -lt $max_retries ]; do
        echo "📥 Downloading $url (Attempt $((retry_count + 1))/$max_retries)..."
        
        if wget -O "$output_file" "$url"; then
            echo "✅ Download successful: $output_file"
            return 0
        else
            retry_count=$((retry_count + 1))
            
            if [ $retry_count -eq $max_retries ]; then
                echo "❌ Download failed after $max_retries attempts: $url"
                bash lib/scripts/combined/send_error_email.sh "Download Failed" "Failed to download file after $max_retries attempts: $url"
                return 1
            else
                echo "⚠️ Download failed, retrying in $delay seconds..."
                sleep $delay
            fi
        fi
    done
}

# Function to download and setup app icon
download_app_icon() {
    if [ -n "$LOGO_URL" ]; then
        echo "📥 Downloading app icon..."
        if download_with_retry "$LOGO_URL" "$APP_ICON_PATH"; then
            flutter pub add flutter_launcher_icons
            flutter pub run flutter_launcher_icons
            return 0
        else
            return 1
        fi
    fi
    return 0
}

# Function to download and setup splash screen
download_splash_assets() {
    if [ "$IS_SPLASH" = "true" ]; then
        echo "📥 Downloading splash assets..."
        local success=true
        
        if [ -n "$SPLASH" ]; then
            if ! download_with_retry "$SPLASH" "$SPLASH_IMAGE_PATH"; then
                success=false
            fi
        fi
        
        if [ -n "$SPLASH_BG" ]; then
            if ! download_with_retry "$SPLASH_BG" "$SPLASH_BG_PATH"; then
                success=false
            fi
        fi
        
        if [ "$success" = true ]; then
            echo "✅ Splash assets downloaded successfully"
            return 0
        else
            return 1
        fi
    fi
    return 0
}

# Function to download Firebase config
download_firebase_config() {
    local platform=$1
    local url=$2
    local output_file=$3
    
    echo "📥 Downloading Firebase config for $platform..."
    if download_with_retry "$url" "$output_file"; then
        return 0
    else
        return 1
    fi
}

# Function to download certificates and provisioning
download_certificates() {
    echo "📥 Downloading certificates and provisioning..."
    local success=true
    
    if ! download_with_retry "$CERT_CER_URL" "$CERT_PATH"; then
        success=false
    fi
    
    if ! download_with_retry "$CERT_KEY_URL" "$KEY_PATH"; then
        success=false
    fi
    
    if ! download_with_retry "$PROFILE_URL" "$PROFILE_PATH"; then
        success=false
    fi
    
    if [ "$success" = true ]; then
        return 0
    else
        return 1
    fi
} 