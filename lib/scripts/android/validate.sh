#!/bin/bash
set -e

# Function to handle errors
handle_error() {
    echo "❌ Validation failed!"
    echo "📍 Error occurred at line: $1"
    echo "🔧 Failed command: $2"
    echo "📊 Exit code: $3"
    exit 1
}

# Function to print section headers
print_section() {
    echo "-------------------------------------------------"
    echo "🔍 $1"
    echo "-------------------------------------------------"
}

# Function to validate environment variables
validate_env_vars() {
    print_section "Validating Environment Variables"
    
    # Required variables
    local required_vars=(
        "APP_NAME"
        "PKG_NAME"
        "VERSION_NAME"
        "VERSION_CODE"
        "ORG_NAME"
        "WEB_URL"
        "EMAIL_ID"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            handle_error ${LINENO} "Missing required environment variable: $var" 1
        fi
    done
    
    # Validate version format
    if ! [[ "$VERSION_NAME" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        handle_error ${LINENO} "Invalid VERSION_NAME format. Expected format: X.Y.Z" 1
    fi
    
    if ! [[ "$VERSION_CODE" =~ ^[0-9]+$ ]]; then
        handle_error ${LINENO} "Invalid VERSION_CODE format. Expected format: number" 1
    fi
    
    # Validate package name format
    if ! [[ "$PKG_NAME" =~ ^[a-z][a-z0-9_]*(\.[a-z0-9_]+)+[0-9a-z_]$ ]]; then
        handle_error ${LINENO} "Invalid PKG_NAME format. Expected format: com.example.app" 1
    fi
    
    echo "✅ Environment variables validated"
}

# Function to validate Flutter installation
validate_flutter() {
    print_section "Validating Flutter Installation"
    
    # Check if Flutter is installed
    if ! command -v flutter &> /dev/null; then
        handle_error ${LINENO} "Flutter is not installed or not in PATH" 1
    fi
    
    # Check Flutter version
    local flutter_version=$(flutter --version | grep -o "Flutter [0-9]\+\.[0-9]\+\.[0-9]\+" | cut -d' ' -f2)
    if [ -z "$flutter_version" ]; then
        handle_error ${LINENO} "Could not determine Flutter version" 1
    fi
    
    echo "✅ Flutter $flutter_version detected"
    
    # Check Flutter doctor
    if ! flutter doctor &> /dev/null; then
        handle_error ${LINENO} "Flutter doctor reported issues" 1
    fi
    
    echo "✅ Flutter doctor passed"
}

# Function to validate Android SDK
validate_android_sdk() {
    print_section "Validating Android SDK"
    
    # Check if ANDROID_SDK_ROOT is set
    if [ -z "$ANDROID_SDK_ROOT" ]; then
        handle_error ${LINENO} "ANDROID_SDK_ROOT is not set" 1
    fi
    
    # Check if Android SDK exists
    if [ ! -d "$ANDROID_SDK_ROOT" ]; then
        handle_error ${LINENO} "Android SDK directory not found: $ANDROID_SDK_ROOT" 1
    fi
    
    # Check for required SDK components
    local required_components=(
        "platform-tools"
        "build-tools"
        "platforms"
    )
    
    for component in "${required_components[@]}"; do
        if [ ! -d "$ANDROID_SDK_ROOT/$component" ]; then
            handle_error ${LINENO} "Missing Android SDK component: $component" 1
        fi
    done
    
    echo "✅ Android SDK validated"
}

# Function to validate keystore configuration
validate_keystore() {
    print_section "Validating Keystore Configuration"
    
    if [ -n "$KEY_STORE" ]; then
        # Check if keystore URL is accessible
        if ! curl --output /dev/null --silent --head --fail "$KEY_STORE"; then
            handle_error ${LINENO} "Keystore URL is not accessible: $KEY_STORE" 1
        fi
        
        # Check if keystore password is set
        if [ -z "$CM_KEYSTORE_PASSWORD" ]; then
            handle_error ${LINENO} "Keystore password is not set" 1
        fi
        
        # Check if key alias is set
        if [ -z "$CM_KEY_ALIAS" ]; then
            handle_error ${LINENO} "Key alias is not set" 1
        fi
        
        # Check if key password is set
        if [ -z "$CM_KEY_PASSWORD" ]; then
            handle_error ${LINENO} "Key password is not set" 1
        fi
        
        echo "✅ Keystore configuration validated"
    else
        echo "⚠️ Keystore configuration skipped (not required)"
    fi
}

# Function to validate Firebase configuration
validate_firebase() {
    print_section "Validating Firebase Configuration"
    
    if [ "$PUSH_NOTIFY" = "true" ]; then
        # Check if Firebase config URL is set
        if [ -z "$FIREBASE_CONFIG_ANDROID" ]; then
            handle_error ${LINENO} "Firebase config URL is not set" 1
        fi
        
        # Check if Firebase config URL is accessible
        if ! curl --output /dev/null --silent --head --fail "$FIREBASE_CONFIG_ANDROID"; then
            handle_error ${LINENO} "Firebase config URL is not accessible: $FIREBASE_CONFIG_ANDROID" 1
        fi
        
        echo "✅ Firebase configuration validated"
    else
        echo "⚠️ Firebase configuration skipped (PUSH_NOTIFY=false)"
    fi
}

# Function to validate project structure
validate_project() {
    print_section "Validating Project Structure"
    
    # Check for required directories
    local required_dirs=(
        "android"
        "lib"
        "ios"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            handle_error ${LINENO} "Required directory not found: $dir" 1
        fi
    done
    
    # Check for required files
    local required_files=(
        "pubspec.yaml"
        "android/build.gradle"
        "android/app/build.gradle"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            handle_error ${LINENO} "Required file not found: $file" 1
        fi
    done
    
    echo "✅ Project structure validated"
}

# Main validation process
echo "🔍 Starting validation process..."

# Run all validations
validate_env_vars
validate_flutter
validate_android_sdk
validate_keystore
validate_firebase
validate_project

echo "✅ All validations passed successfully!" 