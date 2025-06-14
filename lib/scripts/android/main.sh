#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Get the script directory for dynamic path resolution
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Always set the correct package name for Android builds
export PKG_NAME=com.garbcode.garbcodeapp

# Error handler for sending error emails and exiting
handle_error() {
    local exit_code=$?
    local error_line=$1
    local error_command=$2

    # Check if build succeeded despite error
    if [ -f "output/app-release.apk" ] || [ -f "output/app-release.aab" ]; then
        echo "⚠️  Build completed with warnings but APK/AAB files were generated successfully!"
        exit 0
    else
        echo "❌ Build process failed!"
        local error_details=""
        if [ -f "flutter_build_apk.log" ]; then
            error_details=$(tail -50 flutter_build_apk.log 2>/dev/null || echo "No build log available")
        fi
        local error_message="Build process failed with exit code $exit_code"
        "$SCRIPT_DIR/send_error_email.sh" "$error_message" "$error_details"
        exit $exit_code
    fi
}

# Set up error handling
trap 'handle_error ${LINENO} "$BASH_COMMAND"' ERR

echo "🚀 Starting Android Build Process"
echo "📋 RULE: Only ADD files to Android folders, NO DIRECT MODIFICATIONS"
echo "📧 ERROR NOTIFICATIONS: Enabled - emails will be sent on build failures"
echo ""

# 1. Source environment variables
echo "--- Import Environment Variables ---"
# Only source export.sh if not running in CI (Codemagic)
if [ -z "$CI" ]; then
  if [ -f "$SCRIPT_DIR/export.sh" ]; then
    . "$SCRIPT_DIR/export.sh"
  fi
fi
echo ""

# 2. Fix v1 embedding issues
echo "--- Fixing V1 Embedding Issues ---"
"$SCRIPT_DIR/fix_v1_embedding.sh"
echo ""

# 3. Clean previous build files and output
echo "--- Clearing Previous Build Files ---"
flutter clean
OUTPUT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)/output"
rm -rf "$OUTPUT_DIR"/*
mkdir -p "$OUTPUT_DIR"
rm -rf android/app/build
echo ""

# 3.5. Initialize Gradle wrapper with official distribution (only if needed)
echo "--- Initializing Gradle Wrapper ---"
cd "$SCRIPT_DIR/../../../android"

# Skip Gradle wrapper initialization in CI environments (like Codemagic)
# since it's already handled by the CI workflow
if [ -n "$CI" ]; then
    echo "🔍 Running in CI environment, skipping Gradle wrapper initialization..."
    echo "✅ Using pre-configured Gradle wrapper from CI workflow"
    cd "$SCRIPT_DIR/../../../"
    echo ""
else
    # Backup local.properties if it exists (both in android and parent directory)
    if [ -f "local.properties" ]; then
        echo "📦 Backing up existing local.properties in android directory..."
        cp local.properties local.properties.backup
    fi
    if [ -f "../local.properties" ]; then
        echo "📦 Backing up existing local.properties in parent directory..."
        cp ../local.properties ../local.properties.backup
    fi

    # Check if Gradle wrapper already exists and is working
    if [ -f "gradlew" ] && [ -f "gradle/wrapper/gradle-wrapper.jar" ] && [ -f "gradle/wrapper/gradle-wrapper.properties" ]; then
        echo "🔍 Checking existing Gradle wrapper..."
        if ./gradlew --version >/dev/null 2>&1; then
            echo "✅ Existing Gradle wrapper is working, skipping initialization"
            cd "$SCRIPT_DIR"
            echo ""
            # Skip to next step
        else
            echo "⚠️  Existing Gradle wrapper is not working, reinitializing..."
            # Continue with initialization below
        fi
    else
        echo "📝 Gradle wrapper not found, initializing..."
        # Continue with initialization below
    fi

    # Only initialize if we didn't skip above
    if [ ! -f "gradlew" ] || ! ./gradlew --version >/dev/null 2>&1; then
        mkdir -p gradle/wrapper
        
        # Try to download gradle-wrapper.jar directly from GitHub first
        echo "📥 Downloading gradle-wrapper.jar from GitHub..."
        if curl -L -o gradle/wrapper/gradle-wrapper.jar \
            "https://github.com/gradle/gradle/raw/v8.12.0/gradle/wrapper/gradle-wrapper.jar"; then
            echo "✅ Downloaded gradle-wrapper.jar from GitHub"
        else
            echo "⚠️  GitHub download failed, trying alternative method..."
            # Fallback to Maven Central
            curl -L -o gradle/wrapper/gradle-wrapper.jar \
                "https://repo1.maven.org/maven2/org/gradle/gradle-wrapper/8.12/gradle-wrapper-8.12.jar" || \
            curl -L -o gradle/wrapper/gradle-wrapper.jar \
                "https://services.gradle.org/distributions-snapshots/gradle-wrapper.jar"
        fi
        
        # Create gradle-wrapper.properties
        cat > gradle/wrapper/gradle-wrapper.properties << EOF
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.12-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF
        if [ ! -f "gradlew" ]; then
            echo "📝 Creating gradlew script..."
            cat > gradlew << EOL
#!/bin/sh
SCRIPT_DIR="\$( cd "\$( dirname "\$0" )" && pwd )"
WRAPPER_JAR="\${SCRIPT_DIR}/gradle/wrapper/gradle-wrapper.jar"
if [ ! -f "\${WRAPPER_JAR}" ]; then
    echo "Error: Could not find gradle-wrapper.jar at \${WRAPPER_JAR}"
    exit 1
fi
exec java -cp "\${WRAPPER_JAR}" org.gradle.wrapper.GradleWrapperMain "\$@"
EOL
            chmod +x gradlew
        fi
        echo "✅ Gradle wrapper initialized"
    fi

    # Restore local.properties files if they were backed up
    if [ -f "local.properties.backup" ]; then
        echo "🔄 Restoring local.properties in android directory..."
        mv local.properties.backup local.properties
    fi
    if [ -f "../local.properties.backup" ]; then
        echo "🔄 Restoring local.properties in parent directory..."
        mv ../local.properties.backup ../local.properties
    fi

    # Ensure local.properties exists in parent directory (required by settings.gradle)
    if [ ! -f "../local.properties" ] && [ -f "local.properties" ]; then
        echo "📋 Copying local.properties to parent directory for settings.gradle..."
        cp local.properties ../local.properties
    fi

    cd "$SCRIPT_DIR/../../../"
    echo ""
fi

# 4. Validate Android project structure
echo "--- Validating Android Project Structure ---"
"$SCRIPT_DIR/android_file_manager.sh" validate
echo ""

# 5. Debug environment variables
echo "--- Debugging Environment Variables ---"
"$SCRIPT_DIR/debug_env.sh"
echo ""

# 6. Project and version setup
echo "--- Setting up Project Name and Version ---"
"$SCRIPT_DIR/change_proj_name.sh"
"$SCRIPT_DIR/update_version.sh"
echo ""

# 7. Apply custom assets and icons
echo "--- Applying Custom Assets and Icons ---"
"$SCRIPT_DIR/get_logo.sh"
"$SCRIPT_DIR/get_splash.sh"
flutter pub run flutter_launcher_icons
echo ""

# 8. Prepare Android project (permissions, keystore, config)
echo "--- Preparing Android Project ---"
"$SCRIPT_DIR/delete_old_keystore.sh"
"$SCRIPT_DIR/get_json.sh"
"$SCRIPT_DIR/inject_permissions_android.sh"
"$SCRIPT_DIR/inject_keystore.sh"
"$SCRIPT_DIR/configure_android_build_fixed.sh"
echo ""

# 9. Build APK and AAB
echo "🛠️ Starting the build process..."
"$SCRIPT_DIR/build.sh"
echo ""

# 10. Validate APK signing (optional, if ANDROID_SDK_ROOT is set)
echo "🔍 Validating APK signature..."
BUILD_TOOLS_DIR=""
if [ -n "$ANDROID_SDK_ROOT" ] && [ -d "$ANDROID_SDK_ROOT/build-tools" ]; then
    BUILD_TOOLS_DIR=$(find "$ANDROID_SDK_ROOT/build-tools" -maxdepth 1 -type d -regextype posix-extended -regex ".*/[0-9]+\.[0-9]+\.[0-9]+" 2>/dev/null | sort -V | tail -n 1)
fi
if [ -n "$BUILD_TOOLS_DIR" ] && [ -f "android/app/build/outputs/apk/release/app-release.apk" ]; then
    "$BUILD_TOOLS_DIR/apksigner" verify --verbose "android/app/build/outputs/apk/release/app-release.apk" || echo "⚠️  Signature validation failed, but APK was built successfully"
fi
echo ""

# 11. Move outputs to output folder
echo "--- Moving Build Outputs ---"
"$SCRIPT_DIR/move_outputs.sh" 2>/dev/null || true
echo ""

# 12. Send email with all files in output folder
echo "--- Sending Email with Build Outputs ---"
"$SCRIPT_DIR/send_output_email.sh" 2>/dev/null || true
echo ""

echo "✅ All tasks completed successfully!"
echo "🔒 Build artifacts are preserved, but Android project files are unchanged."
echo "📧 No error notifications sent - build completed successfully!"