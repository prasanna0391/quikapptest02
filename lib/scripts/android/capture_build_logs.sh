#!/bin/bash

# Capture Build Logs Script
# This script captures build output for error reporting

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Function to capture command output
capture_command() {
    local command="$1"
    local log_file="$2"
    local description="$3"
    
    echo -e "${BLUE}🔄 Running: $description${NC}"
    echo "Command: $command" >> "$log_file"
    echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')" >> "$log_file"
    echo "----------------------------------------" >> "$log_file"
    
    # Run command and capture output
    if eval "$command" 2>&1 | tee -a "$log_file"; then
        echo -e "${GREEN}✅ $description completed successfully${NC}"
        echo "Status: SUCCESS" >> "$log_file"
    else
        local exit_code=${PIPESTATUS[0]}
        echo -e "${RED}❌ $description failed with exit code $exit_code${NC}"
        echo "Status: FAILED (exit code: $exit_code)" >> "$log_file"
        return $exit_code
    fi
    
    echo "----------------------------------------" >> "$log_file"
    echo "" >> "$log_file"
}

# Function to get recent build logs
get_recent_logs() {
    local log_file="$1"
    local lines="${2:-50}"
    
    if [ -f "$log_file" ]; then
        tail -n "$lines" "$log_file" 2>/dev/null || echo "Unable to read log file"
    else
        echo "Log file not found: $log_file"
    fi
}

# Function to analyze build logs for common errors
analyze_build_logs() {
    local log_file="$1"
    
    if [ ! -f "$log_file" ]; then
        echo "No build log available for analysis"
        return
    fi
    
    echo "🔍 Analyzing build logs for common errors..."
    
    # Check for common error patterns
    local errors_found=0
    
    if grep -qi "v1 embedding\|FlutterApplication\|FlutterActivity" "$log_file"; then
        echo "⚠️  Found v1 embedding issues"
        errors_found=$((errors_found + 1))
    fi
    
    if grep -qi "resource.*not found\|mipmap.*not found\|drawable.*not found" "$log_file"; then
        echo "⚠️  Found missing resource issues"
        errors_found=$((errors_found + 1))
    fi
    
    if grep -qi "google-services\|Firebase\|package name.*mismatch" "$log_file"; then
        echo "⚠️  Found Google Services configuration issues"
        errors_found=$((errors_found + 1))
    fi
    
    if grep -qi "compilation.*failed\|syntax.*error\|import.*error" "$log_file"; then
        echo "⚠️  Found compilation errors"
        errors_found=$((errors_found + 1))
    fi
    
    if grep -qi "gradle.*error\|build.gradle.*error" "$log_file"; then
        echo "⚠️  Found Gradle configuration errors"
        errors_found=$((errors_found + 1))
    fi
    
    if [ $errors_found -eq 0 ]; then
        echo "✅ No common error patterns detected"
    fi
}

# Function to create build summary
create_build_summary() {
    local log_file="$1"
    local summary_file="$2"
    
    echo "📊 Creating build summary..."
    
    cat > "$summary_file" << EOF
Build Summary Report
===================

Build Information:
- Project: Garbcode App
- Package: ${PKG_NAME:-com.garbcode.garbcodeapp}
- Version: ${VERSION_NAME:-1.0.0}
- Build Time: $(date '+%Y-%m-%d %H:%M:%S')
- Build ID: $(date '+%Y%m%d_%H%M%S')

Environment:
- Flutter Version: $(flutter --version 2>/dev/null | head -1 || echo "Unknown")
- Dart Version: $(dart --version 2>/dev/null | head -1 || echo "Unknown")
- Android SDK: ${ANDROID_SDK_ROOT:-"Not set"}

Build Status: FAILED

Error Analysis:
EOF

    # Add error analysis
    analyze_build_logs "$log_file" >> "$summary_file"
    
    echo "" >> "$summary_file"
    echo "Recent Build Logs:" >> "$summary_file"
    echo "=================" >> "$summary_file"
    get_recent_logs "$log_file" 100 >> "$summary_file"
    
    echo "✅ Build summary created: $summary_file"
}

# Main function
main() {
    local command="$1"
    local log_file="${PROJECT_ROOT}/build_log_$(date +%Y%m%d_%H%M%S).log"
    local summary_file="${PROJECT_ROOT}/build_summary_$(date +%Y%m%d_%H%M%S).txt"
    
    # Initialize log file
    echo "Build Log - $(date '+%Y-%m-%d %H:%M:%S')" > "$log_file"
    echo "Command: $command" >> "$log_file"
    echo "========================================" >> "$log_file"
    
    echo -e "${BLUE}📝 Starting build with log capture...${NC}"
    echo -e "${BLUE}📄 Log file: $log_file${NC}"
    
    # Capture the command
    if capture_command "$command" "$log_file" "Build Process"; then
        echo -e "${GREEN}🎉 Build completed successfully!${NC}"
        echo -e "${GREEN}📄 Full log available at: $log_file${NC}"
    else
        local exit_code=$?
        echo -e "${RED}💥 Build failed with exit code $exit_code${NC}"
        
        # Create build summary
        create_build_summary "$log_file" "$summary_file"
        
        # Send error notification
        local error_message="Build process failed with exit code $exit_code"
        local error_details=$(get_recent_logs "$log_file" 50)
        
        echo -e "${BLUE}📧 Sending error notification...${NC}"
        "$SCRIPT_DIR/send_error_email.sh" "$error_message" "$error_details"
        
        exit $exit_code
    fi
}

# If script is called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <command>"
        echo "Example: $0 'flutter build apk --release'"
        exit 1
    fi
    
    main "$@"
fi 