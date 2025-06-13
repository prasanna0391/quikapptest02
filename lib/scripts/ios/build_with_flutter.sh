#!/usr/bin/env bash

set -euo pipefail

echo "🚀 Starting iOS build with Flutter and dynamic Podfile injection..."

# Source environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/export.sh" ]; then
    source "$SCRIPT_DIR/export.sh"
else
    echo "❌ Error: export.sh not found at $SCRIPT_DIR/export.sh"
    exit 1
fi

# Build configuration
BUILD_TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BUILD_LOG_DIR="$PROJECT_ROOT/build_logs"
BUILD_OUTPUT_DIR="$PROJECT_ROOT/build_outputs"

# Create necessary directories
mkdir -p "$BUILD_LOG_DIR" "$BUILD_OUTPUT_DIR"

# Log file setup
LOG_FILE="$BUILD_LOG_DIR/ios_flutter_build_${BUILD_TIMESTAMP}.log"

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_message "INFO" "🚀 Starting iOS Build with Flutter and Dynamic Podfile"
log_message "INFO" "📱 App: $APP_NAME ($BUNDLE_ID) v$VERSION_NAME"
log_message "INFO" "📦 Export Method: $EXPORT_METHOD"

# Step 1: Setup CocoaPods with dynamic values first
log_message "INFO" "📦 Step 1: Setting up CocoaPods with dynamic values"
if [ -f "$SCRIPT_DIR/setup_cocoapods.sh" ]; then
    if ! "$SCRIPT_DIR/setup_cocoapods.sh"; then
        log_message "ERROR" "CocoaPods setup failed"
        exit 1
    fi
else
    log_message "ERROR" "setup_cocoapods.sh not found"
    exit 1
fi
log_message "INFO" "✅ CocoaPods setup completed"

# Step 2: Run Flutter build
log_message "INFO" "📦 Step 2: Running Flutter build for iOS"
cd "$PROJECT_ROOT"

echo "🔨 Building Flutter app for iOS..."
if ! flutter build ios --release --no-codesign; then
    log_message "ERROR" "Flutter build failed"
    exit 1
fi
log_message "INFO" "✅ Flutter build completed successfully"

# Step 3: Run xcodebuild archive
log_message "INFO" "🏗️ Step 3: Running xcodebuild archive"
cd ios

# Set up xcodebuild parameters
WORKSPACE="Runner.xcworkspace"
SCHEME="Runner"
CONFIGURATION="Release"
ARCHIVE_PATH="$PROJECT_ROOT/build/Runner.xcarchive"
EXPORT_PATH="$PROJECT_ROOT/build/export"
EXPORT_OPTIONS_PLIST="$PROJECT_ROOT/build/ExportOptions.plist"

# Create ExportOptions.plist for the export method
log_message "INFO" "📄 Creating ExportOptions.plist for $EXPORT_METHOD"
cat > "$EXPORT_OPTIONS_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$EXPORT_METHOD</string>
    <key>teamID</key>
    <string>$APPLE_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF

# Run xcodebuild archive
log_message "INFO" "🔨 Running xcodebuild archive..."
echo "Command: xcodebuild -workspace $WORKSPACE -scheme $SCHEME -configuration $CONFIGURATION -archivePath $ARCHIVE_PATH -sdk iphoneos -destination generic/platform=iOS -allowProvisioningUpdates archive"

if ! xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" -configuration "$CONFIGURATION" -archivePath "$ARCHIVE_PATH" -sdk iphoneos -destination generic/platform=iOS -allowProvisioningUpdates archive; then
    log_message "ERROR" "xcodebuild archive failed"
    exit 1
fi
log_message "INFO" "✅ xcodebuild archive completed successfully"

# Step 4: Export IPA
log_message "INFO" "📦 Step 4: Exporting IPA"
mkdir -p "$EXPORT_PATH"

echo "Command: xcodebuild -exportArchive -archivePath $ARCHIVE_PATH -exportPath $EXPORT_PATH -exportOptionsPlist $EXPORT_OPTIONS_PLIST"

if ! xcodebuild -exportArchive -archivePath "$ARCHIVE_PATH" -exportPath "$EXPORT_PATH" -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"; then
    log_message "ERROR" "xcodebuild export failed"
    exit 1
fi
log_message "INFO" "✅ IPA export completed successfully"

# Step 5: Move outputs to final location
log_message "INFO" "📁 Step 5: Moving build outputs"
if [ -f "$EXPORT_PATH/Runner.ipa" ]; then
    cp "$EXPORT_PATH/Runner.ipa" "$BUILD_OUTPUT_DIR/Garbcode_App_v${VERSION_NAME}_${BUILD_TIMESTAMP}.ipa"
    log_message "INFO" "✅ IPA moved to: $BUILD_OUTPUT_DIR/Garbcode_App_v${VERSION_NAME}_${BUILD_TIMESTAMP}.ipa"
else
    log_message "WARN" "IPA file not found at expected location"
fi

# Step 6: Cleanup
log_message "INFO" "🧹 Step 6: Cleaning up temporary files"
rm -rf "$EXPORT_PATH" "$EXPORT_OPTIONS_PLIST" || true

# Build completed successfully
log_message "INFO" "🎉 iOS Build with Flutter completed successfully!"
log_message "INFO" "📱 App: $APP_NAME ($BUNDLE_ID) v$VERSION_NAME"
log_message "INFO" "📁 Output Directory: $BUILD_OUTPUT_DIR"
log_message "INFO" "📝 Build Log: $LOG_FILE"

# Display build summary
echo ""
echo "🎉 iOS Build Summary"
echo "==================="
echo "📱 App: $APP_NAME ($BUNDLE_ID)"
echo "🔢 Version: $VERSION_NAME+$VERSION_CODE"
echo "📦 Export Method: $EXPORT_METHOD"
echo "📁 Output: $BUILD_OUTPUT_DIR"
echo "📝 Log: $LOG_FILE"
echo ""

exit 0 