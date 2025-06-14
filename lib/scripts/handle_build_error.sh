#!/bin/bash

# Comprehensive Build Error Handler
# This script captures build errors and sends detailed error notifications

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Function to print colored output
print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to capture build logs
capture_build_logs() {
    local log_file="$PROJECT_ROOT/build_error_log_$(date +%Y%m%d_%H%M%S).txt"
    
    print_colored $BLUE "📋 Capturing build logs..."
    
    # Capture recent build output
    {
        echo "=== BUILD ERROR LOG ==="
        echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Workflow: ${WORKFLOW_NAME:-Unknown}"
        echo "App: ${APP_NAME:-Unknown}"
        echo "Package: ${PKG_NAME:-Unknown}"
        echo "Version: ${VERSION_NAME:-Unknown}"
        echo ""
        echo "=== ENVIRONMENT VARIABLES ==="
        env | grep -E "(APP_|PKG_|VERSION_|BUNDLE_|WORKFLOW_|SMTP_)" | sort
        echo ""
        echo "=== RECENT BUILD OUTPUT ==="
        # Capture last 100 lines of build output
        tail -n 100 /tmp/build_output.log 2>/dev/null || echo "No build output available"
        echo ""
        echo "=== FLUTTER DOCTOR ==="
        flutter doctor -v 2>&1 || echo "Flutter doctor failed"
        echo ""
        echo "=== PROJECT STATUS ==="
        echo "Flutter version: $(flutter --version 2>/dev/null | head -n 1 || echo 'Unknown')"
        echo "Dart version: $(dart --version 2>/dev/null | head -n 1 || echo 'Unknown')"
        echo "Project directory: $PROJECT_ROOT"
        echo "Current working directory: $(pwd)"
        echo ""
        echo "=== FILE SYSTEM STATUS ==="
        ls -la 2>/dev/null || echo "Cannot list current directory"
        echo ""
        if [ -d "android" ]; then
            echo "=== ANDROID STATUS ==="
            ls -la android/ 2>/dev/null || echo "Cannot list android directory"
            echo ""
        fi
        if [ -d "ios" ]; then
            echo "=== IOS STATUS ==="
            ls -la ios/ 2>/dev/null || echo "Cannot list ios directory"
            echo ""
        fi
        echo "=== END OF LOG ==="
    } > "$log_file"
    
    print_colored $GREEN "✅ Build logs captured: $log_file"
    echo "$log_file"
}

# Function to detect error type and generate error message
detect_error_and_message() {
    local error_log="$1"
    local error_message=""
    local error_details=""
    
    # Read the error log
    if [ -f "$error_log" ]; then
        error_details=$(cat "$error_log")
    else
        error_details="No error log available"
    fi
    
    # Detect common error patterns
    if echo "$error_details" | grep -qi "v1 embedding\|FlutterApplication\|FlutterActivity"; then
        error_message="Android v1 embedding issue detected. The project is using deprecated Flutter embedding."
    elif echo "$error_details" | grep -qi "resource.*not found\|mipmap\|drawable"; then
        error_message="Missing resource files detected. Required Android resources are not found."
    elif echo "$error_details" | grep -qi "google-services\|Firebase\|package name"; then
        error_message="Firebase configuration error. Google Services configuration is invalid."
    elif echo "$error_details" | grep -qi "compilation\|syntax\|import"; then
        error_message="Compilation error detected. There are syntax or import issues in the code."
    elif echo "$error_details" | grep -qi "gradle\|build.gradle"; then
        error_message="Gradle configuration error. Build configuration files have issues."
    elif echo "$error_details" | grep -qi "certificate\|provisioning\|code signing"; then
        error_message="Code signing error. Certificate or provisioning profile issues detected."
    elif echo "$error_details" | grep -qi "cocoapods\|pod install"; then
        error_message="CocoaPods dependency error. iOS dependencies failed to install."
    elif echo "$error_details" | grep -qi "xcode\|archive\|export"; then
        error_message="Xcode build error. iOS build process failed."
    elif echo "$error_details" | grep -qi "flutter.*not found\|command.*not found"; then
        error_message="Flutter environment error. Flutter SDK or dependencies are not properly configured."
    elif echo "$error_details" | grep -qi "permission\|access\|denied"; then
        error_message="Permission error. File system or network access issues detected."
    elif echo "$error_details" | grep -qi "timeout\|connection\|network"; then
        error_message="Network error. Connection or download issues detected."
    elif echo "$error_details" | grep -qi "memory\|out of memory\|heap"; then
        error_message="Memory error. Build process ran out of memory."
    elif echo "$error_details" | grep -qi "disk.*full\|no space"; then
        error_message="Disk space error. Insufficient disk space for build process."
    else
        error_message="Unknown build error. The build process failed for an undetermined reason."
    fi
    
    echo "$error_message|$error_details"
}

# Function to send error notification
send_error_notification() {
    local error_message="$1"
    local error_details="$2"
    
    print_colored $BLUE "📧 Sending error notification..."
    
    # Make email notification script executable
    chmod +x "$SCRIPT_DIR/email_notification.py"
    
    # Send error email using the new notification system
    if python3 "$SCRIPT_DIR/email_notification.py" "error" "$error_message" "$error_details"; then
        print_colored $GREEN "✅ Error notification sent successfully"
        return 0
    else
        print_colored $YELLOW "⚠️  Failed to send error notification via Python script"
        
        # Fallback to shell script if Python fails
        if [ -f "$SCRIPT_DIR/send_error_email.sh" ]; then
            print_colored $BLUE "🔄 Trying fallback error notification..."
            chmod +x "$SCRIPT_DIR/send_error_email.sh"
            "$SCRIPT_DIR/send_error_email.sh" "$error_message" "$error_details"
        else
            print_colored $YELLOW "💡 Error notification scripts not available"
            print_colored $YELLOW "📧 Would send error notification to: ${EMAIL_ID:-No email configured}"
            print_colored $YELLOW "📧 Error: $error_message"
        fi
        
        return 1
    fi
}

# Function to create error summary
create_error_summary() {
    local error_log="$1"
    local summary_file="$PROJECT_ROOT/error_summary_$(date +%Y%m%d_%H%M%S).txt"
    
    print_colored $BLUE "📝 Creating error summary..."
    
    {
        echo "BUILD ERROR SUMMARY"
        echo "==================="
        echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Workflow: ${WORKFLOW_NAME:-Unknown}"
        echo "App: ${APP_NAME:-Unknown}"
        echo "Package: ${PKG_NAME:-Unknown}"
        echo "Version: ${VERSION_NAME:-Unknown}"
        echo "Build ID: $(date +%Y%m%d_%H%M%S)"
        echo ""
        echo "ERROR DETAILS:"
        echo "=============="
        if [ -f "$error_log" ]; then
            # Extract key error information
            grep -i -E "(error|failed|exception|fatal)" "$error_log" | head -20
        else
            echo "No detailed error log available"
        fi
        echo ""
        echo "NEXT STEPS:"
        echo "==========="
        echo "1. Review the error details above"
        echo "2. Check the full error log: $error_log"
        echo "3. Follow the resolution steps in the email notification"
        echo "4. Contact support if the issue persists"
        echo ""
        echo "SUPPORT CONTACT:"
        echo "================"
        echo "Email: support@quikapp.co"
        echo "Website: https://quikapp.co"
        echo "Documentation: https://docs.quikapp.co"
    } > "$summary_file"
    
    print_colored $GREEN "✅ Error summary created: $summary_file"
    echo "$summary_file"
}

# Main error handling function
handle_build_error() {
    local exit_code="${1:-1}"
    local error_context="${2:-Unknown error}"
    
    print_colored $RED "🚨 BUILD ERROR DETECTED (Exit Code: $exit_code)"
    print_colored $RED "Context: $error_context"
    
    # Capture build logs
    local error_log=$(capture_build_logs)
    
    # Detect error and generate message
    local error_info=$(detect_error_and_message "$error_log")
    local error_message=$(echo "$error_info" | cut -d'|' -f1)
    local error_details=$(echo "$error_info" | cut -d'|' -f2-)
    
    print_colored $YELLOW "🔍 Detected Error Type: $error_message"
    
    # Create error summary
    local summary_file=$(create_error_summary "$error_log")
    
    # Send error notification
    send_error_notification "$error_message" "$error_details"
    
    # Display error information
    print_colored $RED "❌ Build failed with error: $error_message"
    print_colored $YELLOW "📋 Error log: $error_log"
    print_colored $YELLOW "📝 Error summary: $summary_file"
    print_colored $BLUE "📧 Error notification sent to: ${EMAIL_ID:-No email configured}"
    
    # Exit with the original error code
    exit $exit_code
}

# Function to set up error handling for a command
setup_error_handling() {
    local command="$1"
    local context="$2"
    
    print_colored $BLUE "🔧 Setting up error handling for: $context"
    
    # Create a temporary file for build output
    local output_file="/tmp/build_output.log"
    
    # Run the command and capture output
    if eval "$command" 2>&1 | tee "$output_file"; then
        print_colored $GREEN "✅ Command completed successfully: $context"
        return 0
    else
        local exit_code=${PIPESTATUS[0]}
        handle_build_error $exit_code "$context"
    fi
}

# Function to handle script exit
cleanup_on_exit() {
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        print_colored $RED "🚨 Script exited with error code: $exit_code"
        handle_build_error $exit_code "Script execution failed"
    fi
}

# Set up exit trap
trap cleanup_on_exit EXIT

# If script is called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ $# -eq 0 ]; then
        print_colored $RED "❌ Usage: $0 <command> [context]"
        print_colored $YELLOW "Example: $0 'flutter build apk' 'Android APK Build'"
        exit 1
    fi
    
    local command="$1"
    local context="${2:-Command execution}"
    
    setup_error_handling "$command" "$context"
fi 