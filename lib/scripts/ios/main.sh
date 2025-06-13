#!/usr/bin/env bash

set -euo pipefail

# iOS Build Script - Main Orchestrator
# This script coordinates the entire iOS build process

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Source environment variables
if [ -f "$SCRIPT_DIR/export.sh" ]; then
    source "$SCRIPT_DIR/export.sh"
else
    echo "❌ Error: export.sh not found at $SCRIPT_DIR/export.sh"
    exit 1
fi

# Build configuration
BUILD_TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BUILD_LOG_DIR="$PROJECT_ROOT/build_logs"
BUILD_OUTPUT_DIR="$PROJECT_ROOT/build_outputs"
CM_BUILD_DIR="$PROJECT_ROOT/build"

# Create necessary directories
mkdir -p "$BUILD_LOG_DIR" "$BUILD_OUTPUT_DIR" "$CM_BUILD_DIR"

# Log file setup
LOG_FILE="$BUILD_LOG_DIR/ios_build_${BUILD_TIMESTAMP}.log"
CHANGES_LOG="$BUILD_LOG_DIR/ios_build_${BUILD_TIMESTAMP}_changes.log"

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Function to capture build changes
capture_changes() {
    local step="$1"
    local description="$2"
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $step: $description" >> "$CHANGES_LOG"
}

# Function to handle errors
handle_error() {
    local exit_code=$?
    local line_number=$1
    local error_message="Build failed at line $line_number with exit code $exit_code"
    log_message "ERROR" "$error_message"
    
    # Source the email notification script if available
    if [ -f "$SCRIPT_DIR/send_error_email.sh" ]; then
        log_message "INFO" "Sending error notification..."
        source "$SCRIPT_DIR/send_error_email.sh"
        report_error "$error_message" "$LOG_FILE" "main.sh" || {
            log_message "WARN" "Failed to send error notification"
        }
    else
        log_message "WARN" "send_error_email.sh not found, skipping error notification"
    fi
    
    exit $exit_code
}

# Set error handling
trap 'handle_error $LINENO' ERR

# Start build process
log_message "INFO" "🚀 Starting iOS Build Process"
log_message "INFO" "📱 App: $APP_NAME ($PKG_NAME) v$VERSION_NAME"
log_message "INFO" "🏗️ Build Directory: $CM_BUILD_DIR"
log_message "INFO" "📝 Log File: $LOG_FILE"

# Step 1: Create build directory and set paths
log_message "INFO" "📁 Step 1: Setting up build environment"
capture_changes "SETUP" "Creating build directories and setting paths"

# Set keychain variables
export KEYCHAIN_NAME="ios-build.keychain"
export CM_BUILD_DIR="$CM_BUILD_DIR"
export PROFILE_PLIST_PATH="$CM_BUILD_DIR/profile.plist"

# Define paths for downloaded/generated files
export CERT_CER_PATH="$CM_BUILD_DIR/certificate.cer"
export PRIVATE_KEY_PATH="$CM_BUILD_DIR/private.key"
export GENERATED_P12_PATH="$CM_BUILD_DIR/generated_certificate.p12"
export PROFILE_PATH="$CM_BUILD_DIR/profile.mobileprovision"
export CERT_PATH="$GENERATED_P12_PATH"

# Create build directory
mkdir -p "$CM_BUILD_DIR"

log_message "INFO" "✅ Build environment setup complete"

# Step 2: Download certificate, key, and profile files
log_message "INFO" "🔐 Step 2: Downloading code signing files"
capture_changes "DOWNLOAD" "Downloading certificate, key, and provisioning profile"

if [ -f "$SCRIPT_DIR/download_certificates.sh" ]; then
    "$SCRIPT_DIR/download_certificates.sh" || {
        log_message "ERROR" "Failed to download certificates"
        exit 1
    }
else
    log_message "WARN" "download_certificates.sh not found, skipping certificate download"
fi

# Step 3: Verify provisioning profile
log_message "INFO" "🔍 Step 3: Verifying provisioning profile"
capture_changes "VERIFY" "Verifying provisioning profile validity"

if [ -f "$SCRIPT_DIR/verify_profile.sh" ]; then
    "$SCRIPT_DIR/verify_profile.sh" || {
        log_message "ERROR" "Provisioning profile verification failed"
        exit 1
    }
    
    # Extract and export profile UUID for Xcode settings
    if [ -f "$PROFILE_PATH" ]; then
        # Create a temporary plist file
        temp_plist="$CM_BUILD_DIR/temp_profile.plist"
        security cms -D -i "$PROFILE_PATH" > "$temp_plist"
        export PROFILE_UUID=$(/usr/libexec/PlistBuddy -c "Print :UUID" "$temp_plist" 2>/dev/null || echo "")
        rm -f "$temp_plist"
        
        if [ -n "$PROFILE_UUID" ]; then
            log_message "INFO" "📱 Profile UUID extracted: $PROFILE_UUID"
        else
            log_message "WARN" "Could not extract profile UUID"
        fi
    fi
else
    log_message "WARN" "verify_profile.sh not found, skipping profile verification"
fi

# Step 4: Generate and verify .p12 file
log_message "INFO" "📦 Step 4: Generating .p12 certificate"
capture_changes "CERTIFICATE" "Generating .p12 certificate from .cer and .key"

if [ -f "$SCRIPT_DIR/generate_p12.sh" ]; then
    "$SCRIPT_DIR/generate_p12.sh" || {
        log_message "ERROR" "Failed to generate .p12 certificate"
        exit 1
    }
else
    log_message "WARN" "generate_p12.sh not found, skipping .p12 generation"
fi

# Step 5: Update Project Configuration
log_message "INFO" "⚙️ Step 5: Updating project configuration"
capture_changes "CONFIG" "Updating app name, bundle ID, and version"

if [ -f "$SCRIPT_DIR/update_project_config.sh" ]; then
    "$SCRIPT_DIR/update_project_config.sh" || {
        log_message "ERROR" "Failed to update project configuration"
        exit 1
    }
else
    log_message "WARN" "update_project_config.sh not found, skipping project configuration"
fi

# Step 6: Handle Assets (Logo, Splash, Icons)
log_message "INFO" "🎨 Step 6: Handling app assets"
capture_changes "ASSETS" "Downloading and configuring app assets"

if [ -f "$SCRIPT_DIR/handle_assets.sh" ]; then
    "$SCRIPT_DIR/handle_assets.sh" || {
        log_message "ERROR" "Failed to handle assets"
        exit 1
    }
else
    log_message "WARN" "handle_assets.sh not found, skipping asset handling"
fi

# Step 7: Clean and Install CocoaPods
log_message "INFO" "📦 Step 7: Setting up CocoaPods"
capture_changes "COCOAPODS" "Cleaning and installing CocoaPods dependencies"

if [ -f "$SCRIPT_DIR/setup_cocoapods.sh" ]; then
    "$SCRIPT_DIR/setup_cocoapods.sh" || {
        log_message "ERROR" "Failed to setup CocoaPods"
        exit 1
    }
else
    log_message "WARN" "setup_cocoapods.sh not found, skipping CocoaPods setup"
fi

# Step 8: Update Xcode Project Settings
log_message "INFO" "🛠️ Step 8: Updating Xcode project settings"
capture_changes "XCODE" "Updating Xcode project for code signing"

if [ -f "$SCRIPT_DIR/update_xcode_settings.sh" ]; then
    "$SCRIPT_DIR/update_xcode_settings.sh" || {
        log_message "ERROR" "Failed to update Xcode settings"
        exit 1
    }
else
    log_message "WARN" "update_xcode_settings.sh not found, skipping Xcode settings"
fi

# Step 9: Create Entitlements File
log_message "INFO" "📄 Step 9: Creating entitlements file"
capture_changes "ENTITLEMENTS" "Creating app entitlements file"

if [ -f "$SCRIPT_DIR/create_entitlements.sh" ]; then
    "$SCRIPT_DIR/create_entitlements.sh" || {
        log_message "ERROR" "Failed to create entitlements file"
        exit 1
    }
else
    log_message "WARN" "create_entitlements.sh not found, skipping entitlements creation"
fi

# Step 10: Archive the app
log_message "INFO" "🏗️ Step 10: Archiving the app"
capture_changes "ARCHIVE" "Creating Xcode archive"

if [ -f "$SCRIPT_DIR/archive_app.sh" ]; then
    "$SCRIPT_DIR/archive_app.sh" || {
        log_message "ERROR" "Failed to archive app"
        exit 1
    }
else
    log_message "WARN" "archive_app.sh not found, skipping app archiving"
fi

# Step 11: Export the IPA
log_message "INFO" "📦 Step 11: Exporting IPA"
capture_changes "EXPORT" "Exporting IPA from archive"

if [ -f "$SCRIPT_DIR/export_ipa.sh" ]; then
    "$SCRIPT_DIR/export_ipa.sh" || {
        log_message "ERROR" "Failed to export IPA"
        exit 1
    }
else
    log_message "WARN" "export_ipa.sh not found, skipping IPA export"
fi

# Step 12: Move outputs to final location
log_message "INFO" "📁 Step 12: Moving build outputs"
capture_changes "OUTPUTS" "Moving build artifacts to output directory"

if [ -f "$SCRIPT_DIR/move_outputs.sh" ]; then
    "$SCRIPT_DIR/move_outputs.sh" || {
        log_message "ERROR" "Failed to move outputs"
        exit 1
    }
else
    log_message "WARN" "move_outputs.sh not found, skipping output move"
fi

# Step 13: Send success notification
log_message "INFO" "📧 Step 13: Sending success notification"
capture_changes "NOTIFICATION" "Sending build success email"

# Calculate build duration
BUILD_START_TIME=$(head -n1 "$LOG_FILE" | cut -d' ' -f1,2)
BUILD_END_TIME=$(date +"%Y-%m-%d %H:%M:%S")
BUILD_DURATION=$(date -u -d @$(($(date +%s) - $(date -d "$BUILD_START_TIME" +%s))) +"%H:%M:%S" 2>/dev/null || echo "Unknown")

if [ -f "$SCRIPT_DIR/send_error_email.sh" ]; then
    source "$SCRIPT_DIR/send_error_email.sh"
    report_success "main.sh" "$BUILD_DURATION" || {
        log_message "WARN" "Failed to send success email, but build completed"
    }
else
    log_message "WARN" "send_error_email.sh not found, skipping email notification"
fi

# Step 14: Final cleanup
log_message "INFO" "🧹 Step 14: Final cleanup"
capture_changes "CLEANUP" "Performing final cleanup"

if [ -f "$SCRIPT_DIR/cleanup.sh" ]; then
    "$SCRIPT_DIR/cleanup.sh" || {
        log_message "WARN" "Cleanup failed, but build completed successfully"
    }
else
    log_message "WARN" "cleanup.sh not found, skipping cleanup"
fi

# Build completed successfully
log_message "INFO" "🎉 iOS Build completed successfully!"
log_message "INFO" "📱 App: $APP_NAME ($PKG_NAME) v$VERSION_NAME"
log_message "INFO" "📁 Output Directory: $BUILD_OUTPUT_DIR"
log_message "INFO" "📝 Build Log: $LOG_FILE"

# Display build summary
echo ""
echo "🎉 iOS Build Summary"
echo "==================="
echo "📱 App: $APP_NAME ($PKG_NAME)"
echo "🔢 Version: $VERSION_NAME+$VERSION_CODE"
echo "📁 Output: $BUILD_OUTPUT_DIR"
echo "📝 Log: $LOG_FILE"
echo "⏱️ Duration: $BUILD_DURATION"
echo ""

exit 0 