#!/bin/bash

# Android File Manager Script
# This script enforces the rule: ONLY ADD FILES, NO DIRECT CHANGES TO EXISTING ANDROID FILES
# All modifications must go through this script to maintain consistency and trackability

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ANDROID_ROOT="../../android"
BACKUP_DIR="../../android_backups"
LOG_FILE="android_changes.log"
TEMPLATE_DIR="templates"

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ANDROID_ROOT="$PROJECT_ROOT/android"
BACKUP_DIR="$PROJECT_ROOT/android_backups"
LOG_FILE="$SCRIPT_DIR/android_changes.log"
TEMPLATE_DIR="$SCRIPT_DIR/templates"

# Session tracking for build process
SESSION_ID=""
SESSION_CHANGES_FILE=""
SESSION_BACKUP_DIR=""

# Initialize the script
init_android_manager() {
    echo -e "${BLUE}🔧 Initializing Android File Manager...${NC}"
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    # Create template directory if it doesn't exist
    mkdir -p "$TEMPLATE_DIR"
    
    # Create log file if it doesn't exist
    touch "$LOG_FILE"
    
    echo -e "${GREEN}✅ Android File Manager initialized${NC}"
}

# Start a new build session
start_build_session() {
    SESSION_ID="build_$(date +%Y%m%d_%H%M%S)"
    SESSION_CHANGES_FILE="$SCRIPT_DIR/${SESSION_ID}_changes.log"
    SESSION_BACKUP_DIR="$BACKUP_DIR/$SESSION_ID"
    
    # Create session directories
    mkdir -p "$SESSION_BACKUP_DIR"
    touch "$SESSION_CHANGES_FILE"
    
    echo -e "${BLUE}🚀 Starting build session: $SESSION_ID${NC}"
    echo -e "${YELLOW}📝 All changes will be tracked for reversion${NC}"
    
    # Log session start
    log_session_change "SESSION_START" "Build session started" "$SESSION_ID"
}

# End build session and revert all changes
end_build_session() {
    if [ -z "$SESSION_ID" ]; then
        echo -e "${RED}❌ No active build session to end${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🔄 Ending build session: $SESSION_ID${NC}"
    echo -e "${YELLOW}🔄 Reverting all changes...${NC}"
    
    # Revert all changes made during this session
    revert_session_changes
    
    # Clean up session files
    cleanup_session
    
    echo -e "${GREEN}✅ Build session ended and all changes reverted${NC}"
    log_change "SESSION_END" "Build session ended and reverted" "$SESSION_ID"
}

# Log changes during build session
log_session_change() {
    local action="$1"
    local description="$2"
    local file_path="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [ -n "$SESSION_CHANGES_FILE" ]; then
        echo "[$timestamp] $action: $file_path - $description" >> "$SESSION_CHANGES_FILE"
    fi
    
    # Also log to main log
    log_change "$action" "$file_path" "$description"
}

# Revert all changes made during the current session
revert_session_changes() {
    if [ ! -f "$SESSION_CHANGES_FILE" ]; then
        echo -e "${YELLOW}⚠️  No session changes file found${NC}"
        return 0
    fi
    
    echo -e "${BLUE}🔄 Reverting session changes...${NC}"
    
    # Read the session changes file in reverse order to revert properly
    local temp_file=$(mktemp)
    tac "$SESSION_CHANGES_FILE" > "$temp_file"
    
    while IFS= read -r line; do
        # Parse the log line
        if [[ $line =~ \[(.*)\]\ ([A-Z_]+):\ (.+)\ -\ (.+) ]]; then
            local timestamp="${BASH_REMATCH[1]}"
            local action="${BASH_REMATCH[2]}"
            local file_path="${BASH_REMATCH[3]}"
            local description="${BASH_REMATCH[4]}"
            
            case "$action" in
                "ADD"|"REPLACE"|"GENERATE_TEMPLATE")
                    # Remove added/replaced files
                    if [ -f "$file_path" ]; then
                        rm "$file_path"
                        echo -e "${GREEN}🗑️  Removed: $file_path${NC}"
                    fi
                    ;;
                "UPDATE")
                    # Restore from session backup
                    local backup_file="$SESSION_BACKUP_DIR/$(basename "$file_path").backup"
                    if [ -f "$backup_file" ]; then
                        cp "$backup_file" "$file_path"
                        echo -e "${GREEN}🔄 Restored: $file_path${NC}"
                    fi
                    ;;
                "CREATE_DIR")
                    # Remove created directories (if empty)
                    if [ -d "$file_path" ] && [ -z "$(ls -A "$file_path")" ]; then
                        rmdir "$file_path"
                        echo -e "${GREEN}🗑️  Removed empty directory: $file_path${NC}"
                    fi
                    ;;
                "DELETE")
                    # Restore deleted files from session backup
                    local backup_file="$SESSION_BACKUP_DIR/$(basename "$file_path").backup"
                    if [ -f "$backup_file" ]; then
                        cp "$backup_file" "$file_path"
                        echo -e "${GREEN}🔄 Restored deleted: $file_path${NC}"
                    fi
                    ;;
            esac
        fi
    done < "$temp_file"
    
    rm "$temp_file"
    echo -e "${GREEN}✅ All session changes reverted${NC}"
}

# Clean up session files
cleanup_session() {
    if [ -n "$SESSION_BACKUP_DIR" ] && [ -d "$SESSION_BACKUP_DIR" ]; then
        rm -rf "$SESSION_BACKUP_DIR"
        echo -e "${YELLOW}🗑️  Cleaned up session backup directory${NC}"
    fi
    
    if [ -n "$SESSION_CHANGES_FILE" ] && [ -f "$SESSION_CHANGES_FILE" ]; then
        rm "$SESSION_CHANGES_FILE"
        echo -e "${YELLOW}🗑️  Cleaned up session changes file${NC}"
    fi
    
    # Reset session variables
    SESSION_ID=""
    SESSION_CHANGES_FILE=""
    SESSION_BACKUP_DIR=""
}

# Enhanced backup function for session tracking
backup_file() {
    local file_path="$1"
    local backup_path="$BACKUP_DIR/$(basename "$file_path").backup.$(date +%Y%m%d_%H%M%S)"
    
    if [ -f "$file_path" ]; then
        cp "$file_path" "$backup_path"
        echo -e "${YELLOW}📦 Backed up: $file_path -> $backup_path${NC}"
        log_change "BACKUP" "$file_path" "Backed up to $backup_path"
        
        # Also backup to session directory if in a session
        if [ -n "$SESSION_BACKUP_DIR" ]; then
            local session_backup="$SESSION_BACKUP_DIR/$(basename "$file_path").backup"
            cp "$file_path" "$session_backup"
        fi
    fi
}

# Log all changes
log_change() {
    local action="$1"
    local file_path="$2"
    local description="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $action: $file_path - $description" >> "$LOG_FILE"
}

# Safe file addition - only adds new files, never modifies existing ones
add_file_safely() {
    local source_file="$1"
    local target_path="$2"
    local description="$3"
    
    if [ -f "$target_path" ]; then
        echo -e "${RED}❌ ERROR: Cannot add file $target_path - file already exists!${NC}"
        echo -e "${YELLOW}💡 Use update_file_safely() for existing files${NC}"
        return 1
    fi
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$target_path")"
    
    # Copy the file
    cp "$source_file" "$target_path"
    echo -e "${GREEN}✅ Added new file: $target_path${NC}"
    log_session_change "ADD" "$target_path" "$description"
}

# Safe file update - creates backup and updates existing files
update_file_safely() {
    local source_file="$1"
    local target_path="$2"
    local description="$3"
    
    if [ ! -f "$target_path" ]; then
        echo -e "${RED}❌ ERROR: Cannot update file $target_path - file does not exist!${NC}"
        echo -e "${YELLOW}💡 Use add_file_safely() for new files${NC}"
        return 1
    fi
    
    # Backup existing file
    backup_file "$target_path"
    
    # Update the file
    cp "$source_file" "$target_path"
    echo -e "${GREEN}✅ Updated file: $target_path${NC}"
    log_session_change "UPDATE" "$target_path" "$description"
}

# Safe file replacement - replaces file with backup
replace_file_safely() {
    local source_file="$1"
    local target_path="$2"
    local description="$3"
    
    # Backup existing file if it exists
    if [ -f "$target_path" ]; then
        backup_file "$target_path"
    fi
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$target_path")"
    
    # Replace the file
    cp "$source_file" "$target_path"
    echo -e "${GREEN}✅ Replaced file: $target_path${NC}"
    log_session_change "REPLACE" "$target_path" "$description"
}

# Safe directory creation
create_directory_safely() {
    local dir_path="$1"
    local description="$2"
    
    if [ -d "$dir_path" ]; then
        echo -e "${YELLOW}⚠️  Directory already exists: $dir_path${NC}"
        return 0
    fi
    
    mkdir -p "$dir_path"
    echo -e "${GREEN}✅ Created directory: $dir_path${NC}"
    log_session_change "CREATE_DIR" "$dir_path" "$description"
}

# Safe file deletion with backup
delete_file_safely() {
    local file_path="$1"
    local description="$2"
    
    if [ ! -f "$file_path" ]; then
        echo -e "${YELLOW}⚠️  File does not exist: $file_path${NC}"
        return 0
    fi
    
    # Backup before deletion
    backup_file "$file_path"
    
    # Delete the file
    rm "$file_path"
    echo -e "${GREEN}✅ Deleted file: $file_path${NC}"
    log_session_change "DELETE" "$file_path" "$description"
}

# Generate template files
generate_template() {
    local template_name="$1"
    local target_path="$2"
    local variables="$3"
    
    case "$template_name" in
        "build.gradle")
            cat > "$target_path" << 'EOF'
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '1'
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0'
}

android {
    namespace "com.example.app"
    compileSdkVersion flutter.compileSdkVersion
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        applicationId "com.example.app"
        minSdkVersion flutter.minSdkVersion
        targetSdkVersion flutter.targetSdkVersion
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
        }
    }
}

flutter {
    source '../..'
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
}
EOF
            ;;
        "AndroidManifest.xml")
            cat > "$target_path" << 'EOF'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="Flutter App"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
EOF
            ;;
        *)
            echo -e "${RED}❌ Unknown template: $template_name${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}✅ Generated template: $target_path${NC}"
    log_session_change "GENERATE_TEMPLATE" "$target_path" "Generated from template: $template_name"
}

# Show change history
show_changes() {
    echo -e "${BLUE}📋 Android File Changes History:${NC}"
    if [ -f "$LOG_FILE" ]; then
        cat "$LOG_FILE"
    else
        echo -e "${YELLOW}No changes logged yet.${NC}"
    fi
}

# Restore from backup
restore_from_backup() {
    local backup_file="$1"
    local target_path="$2"
    
    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}❌ Backup file not found: $backup_file${NC}"
        return 1
    fi
    
    # Create backup of current file if it exists
    if [ -f "$target_path" ]; then
        backup_file "$target_path"
    fi
    
    # Restore from backup
    cp "$backup_file" "$target_path"
    echo -e "${GREEN}✅ Restored file: $target_path from $backup_file${NC}"
    log_change "RESTORE" "$target_path" "Restored from $backup_file"
}

# List available backups
list_backups() {
    echo -e "${BLUE}📦 Available Backups:${NC}"
    if [ -d "$BACKUP_DIR" ]; then
        ls -la "$BACKUP_DIR"
    else
        echo -e "${YELLOW}No backups found.${NC}"
    fi
}

# Validate Android project structure
validate_android_structure() {
    echo -e "${BLUE}🔍 Validating Android Project Structure...${NC}"
    
    local required_files=(
        "$ANDROID_ROOT/build.gradle.kts"
        "$ANDROID_ROOT/app/build.gradle.kts"
        "$ANDROID_ROOT/app/src/main/AndroidManifest.xml"
        "$ANDROID_ROOT/gradle.properties"
        "$ANDROID_ROOT/settings.gradle.kts"
    )
    
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -eq 0 ]; then
        echo -e "${GREEN}✅ Android project structure is valid${NC}"
        return 0
    else
        echo -e "${RED}❌ Missing required files:${NC}"
        for file in "${missing_files[@]}"; do
            echo -e "${RED}   - $file${NC}"
        done
        return 1
    fi
}

# Main function to handle commands
main() {
    case "$1" in
        "init")
            init_android_manager
            ;;
        "start-session")
            start_build_session
            ;;
        "end-session")
            end_build_session
            ;;
        "add")
            if [ $# -lt 4 ]; then
                echo -e "${RED}Usage: $0 add <source_file> <target_path> <description>${NC}"
                exit 1
            fi
            add_file_safely "$2" "$3" "$4"
            ;;
        "update")
            if [ $# -lt 4 ]; then
                echo -e "${RED}Usage: $0 update <source_file> <target_path> <description>${NC}"
                exit 1
            fi
            update_file_safely "$2" "$3" "$4"
            ;;
        "replace")
            if [ $# -lt 4 ]; then
                echo -e "${RED}Usage: $0 replace <source_file> <target_path> <description>${NC}"
                exit 1
            fi
            replace_file_safely "$2" "$3" "$4"
            ;;
        "create-dir")
            if [ $# -lt 3 ]; then
                echo -e "${RED}Usage: $0 create-dir <dir_path> <description>${NC}"
                exit 1
            fi
            create_directory_safely "$2" "$3"
            ;;
        "delete")
            if [ $# -lt 3 ]; then
                echo -e "${RED}Usage: $0 delete <file_path> <description>${NC}"
                exit 1
            fi
            delete_file_safely "$2" "$3"
            ;;
        "generate")
            if [ $# -lt 3 ]; then
                echo -e "${RED}Usage: $0 generate <template_name> <target_path>${NC}"
                exit 1
            fi
            generate_template "$2" "$3"
            ;;
        "restore")
            if [ $# -lt 3 ]; then
                echo -e "${RED}Usage: $0 restore <backup_file> <target_path>${NC}"
                exit 1
            fi
            restore_from_backup "$2" "$3"
            ;;
        "backups")
            list_backups
            ;;
        "changes")
            show_changes
            ;;
        "validate")
            validate_android_structure
            ;;
        "help")
            echo -e "${BLUE}Android File Manager - Usage Guide${NC}"
            echo ""
            echo -e "${GREEN}Commands:${NC}"
            echo "  init                    - Initialize the Android file manager"
            echo "  start-session           - Start a new build session (tracks changes for reversion)"
            echo "  end-session             - End build session and revert all changes"
            echo "  add <src> <dst> <desc>  - Add new file (fails if exists)"
            echo "  update <src> <dst> <desc> - Update existing file (with backup)"
            echo "  replace <src> <dst> <desc> - Replace file (with backup)"
            echo "  create-dir <path> <desc> - Create directory safely"
            echo "  delete <path> <desc>    - Delete file (with backup)"
            echo "  generate <type> <path>  - Generate template file"
            echo "  restore <backup> <path> - Restore file from backup"
            echo "  backups                 - List available backups"
            echo "  changes                 - Show change history"
            echo "  validate                - Validate Android project structure"
            echo "  help                    - Show this help message"
            echo ""
            echo -e "${YELLOW}Build Session Workflow:${NC}"
            echo "  1. start-session        - Start tracking changes"
            echo "  2. [perform build operations]"
            echo "  3. end-session          - Revert all changes and clean up"
            echo ""
            echo -e "${YELLOW}Examples:${NC}"
            echo "  $0 init"
            echo "  $0 start-session"
            echo "  $0 add templates/new_manifest.xml android/app/src/main/AndroidManifest.xml 'Updated manifest'"
            echo "  $0 update templates/build.gradle android/app/build.gradle.kts 'Updated build config'"
            echo "  $0 generate build.gradle android/app/build.gradle.kts"
            echo "  $0 end-session"
            echo "  $0 validate"
            ;;
        *)
            echo -e "${RED}❌ Unknown command: $1${NC}"
            echo -e "${YELLOW}Use '$0 help' for usage information${NC}"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 