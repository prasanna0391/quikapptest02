#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Function to handle errors
handle_error() {
    local error_msg="$1"
    echo "❌ Error: $error_msg"
    bash "$SCRIPT_DIR/send_error_email.sh" "Build Failed" "$error_msg"
    exit 1
}

# Function to print section header
print_section() {
    echo ""
    echo "=== $1 ==="
    echo ""
}

# Function to clean previous builds
clean_builds() {
    print_section "Cleaning Previous Builds"
    
    echo "🧹 Cleaning Flutter build..."
    flutter clean || handle_error "Failed to clean Flutter build"
    
    echo "🧹 Cleaning output directory..."
    rm -rf output || true
    
    echo "✅ Clean complete"
}

# Function to setup Flutter SDK path
setup_flutter_sdk() {
    print_section "Setting up Flutter SDK"
    
    # Create local.properties file in project root
    echo "📝 Creating local.properties file..."
    cat > local.properties << EOF
flutter.sdk=$FLUTTER_ROOT
EOF

    # Also create local.properties in android directory for compatibility
    echo "📝 Creating android/local.properties file..."
    cat > android/local.properties << EOF
flutter.sdk=$FLUTTER_ROOT
EOF

    echo "✅ Flutter SDK path configured"
}

# Function to setup Gradle wrapper
setup_gradle_wrapper() {
    print_section "Setting up Gradle Wrapper"
    
    cd android
    
    # Create Gradle wrapper directory
    mkdir -p gradle/wrapper
    
    # Download gradle-wrapper.jar
    echo "📥 Downloading gradle-wrapper.jar..."
    curl -L -o gradle/wrapper/gradle-wrapper.jar \
        "https://github.com/gradle/gradle/raw/v8.12.0/gradle/wrapper/gradle-wrapper.jar"
    
    # Create gradle-wrapper.properties
    echo "📝 Creating gradle-wrapper.properties..."
    cat > gradle/wrapper/gradle-wrapper.properties << EOF
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.12-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF
    
    # Make gradlew executable
    chmod +x gradlew
    
    cd ..
    echo "✅ Gradle wrapper setup complete"
}

# Main build process
echo "🚀 Starting combined build process..."

# Source environment variables
print_section "Loading Environment"
source "$SCRIPT_DIR/export.sh" || handle_error "Failed to load environment variables"

# Validate environment
print_section "Validating Environment"
bash "$SCRIPT_DIR/validate.sh" || handle_error "Environment validation failed"

# Clean previous builds
clean_builds

# Setup build environment
setup_flutter_sdk
setup_gradle_wrapper

# Configure app
print_section "Configuring App"
bash "$SCRIPT_DIR/configure_app.sh" || handle_error "App configuration failed"

# Build Android
print_section "Building Android"
bash "$SCRIPT_DIR/build_android.sh" || handle_error "Android build failed"

# Build iOS
print_section "Building iOS"
bash "$SCRIPT_DIR/build_ios.sh" || handle_error "iOS build failed"

# Print build summary
print_section "Build Summary"
echo "📱 App Name: $APP_NAME"
echo "📦 Package: $PKG_NAME"
echo "📱 Bundle ID: $BUNDLE_ID"
echo "📊 Version: $VERSION_NAME ($VERSION_CODE)"
echo ""
echo "📦 Generated Artifacts:"
ls -lh output/

echo "✅ Combined build process completed successfully" 