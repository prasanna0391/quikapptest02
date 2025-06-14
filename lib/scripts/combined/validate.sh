#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Function to handle errors
handle_error() {
    local error_msg="$1"
    echo "❌ Error: $error_msg"
    bash "$(dirname "$0")/send_error_email.sh" "Validation Failed" "$error_msg"
    exit 1
}

# Function to validate environment variables
validate_variables() {
    echo "🔍 Validating environment variables..."
    
    local required_vars=(
        "APP_NAME"
        "PKG_NAME"
        "BUNDLE_ID"
        "VERSION_NAME"
        "VERSION_CODE"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            handle_error "Required environment variable $var is not set"
        fi
    done
    
    echo "✅ Environment variables validated"
}

# Function to validate Flutter installation
validate_flutter() {
    echo "🔍 Validating Flutter installation..."
    
    if ! command -v flutter &> /dev/null; then
        handle_error "Flutter is not installed or not in PATH"
    fi
    
    # Check Flutter version
    flutter --version
    
    echo "✅ Flutter installation validated"
}

# Function to validate Android SDK
validate_android_sdk() {
    echo "🔍 Validating Android SDK..."
    
    if [ -z "$ANDROID_HOME" ]; then
        handle_error "ANDROID_HOME environment variable is not set"
    fi
    
    # Check Android SDK tools
    if [ ! -d "$ANDROID_HOME/tools" ] && [ ! -d "$ANDROID_HOME/cmdline-tools" ]; then
        handle_error "Android SDK tools not found"
    fi
    
    echo "✅ Android SDK validated"
}

# Function to validate iOS requirements
validate_ios_requirements() {
    echo "🔍 Validating iOS requirements..."
    
    # Check Xcode installation
    if ! command -v xcodebuild &> /dev/null; then
        handle_error "Xcode is not installed or not in PATH"
    fi
    
    # Check CocoaPods
    if ! command -v pod &> /dev/null; then
        handle_error "CocoaPods is not installed"
    fi
    
    echo "✅ iOS requirements validated"
}

# Main validation process
echo "🚀 Starting validation process..."

validate_variables
validate_flutter
validate_android_sdk
validate_ios_requirements

echo "✅ All validations completed successfully" 