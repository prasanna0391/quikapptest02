# Android File Management Rules

## 🚨 IMPORTANT RULE: ONLY ADD FILES, NO DIRECT MODIFICATIONS

**All changes to Android folder files must go through the `android_file_manager.sh` script. Direct modifications to Android files are strictly prohibited.**

## 🔄 BUILD SESSION MANAGEMENT

**NEW FEATURE**: The system now automatically tracks all changes during the build process and reverts them back to the original state after build completion.

### How It Works:

1. **Start Session**: `main.sh` automatically starts a build session
2. **Track Changes**: All file modifications are logged and backed up
3. **Build Process**: Normal build operations proceed with tracked changes
4. **End Session**: All changes are automatically reverted to original state
5. **Clean Up**: Session files are cleaned up

## Overview

This system enforces a strict rule for managing Android project files:

- ✅ **ALLOWED**: Adding new files to Android folders
- ❌ **PROHIBITED**: Directly modifying existing Android files
- ✅ **ALLOWED**: Using the file manager script to update files (with automatic backups)
- 🔄 **AUTOMATIC REVERSION**: All changes are reverted after build completion

## File Manager Script: `android_file_manager.sh`

### Features

1. **Automatic Backups**: All file modifications are automatically backed up
2. **Change Logging**: All operations are logged with timestamps and descriptions
3. **Validation**: Ensures Android project structure integrity
4. **Safe Operations**: Prevents accidental file overwrites
5. **Template Generation**: Can generate standard Android files from templates
6. **🆕 Session Management**: Tracks and reverts all changes during build process
7. **🆕 Automatic Reversion**: Restores original state after build completion

### Usage

```bash
# Initialize the file manager
./lib/scripts/android/android_file_manager.sh init

# Start a build session (tracks changes for reversion)
./lib/scripts/android/android_file_manager.sh start-session

# Add a new file (fails if file exists)
./lib/scripts/android/android_file_manager.sh add <source_file> <target_path> <description>

# Update existing file (with backup)
./lib/scripts/android/android_file_manager.sh update <source_file> <target_path> <description>

# Replace file (with backup)
./lib/scripts/android/android_file_manager.sh replace <source_file> <target_path> <description>

# Create directory safely
./lib/scripts/android/android_file_manager.sh create-dir <dir_path> <description>

# Delete file (with backup)
./lib/scripts/android/android_file_manager.sh delete <file_path> <description>

# Generate template file
./lib/scripts/android/android_file_manager.sh generate <template_name> <target_path>

# Restore from backup
./lib/scripts/android/android_file_manager.sh restore <backup_file> <target_path>

# List available backups
./lib/scripts/android/android_file_manager.sh backups

# Show change history
./lib/scripts/android/android_file_manager.sh changes

# Validate Android project structure
./lib/scripts/android/android_file_manager.sh validate

# End build session and revert all changes
./lib/scripts/android/android_file_manager.sh end-session

# Show help
./lib/scripts/android/android_file_manager.sh help
```

### Examples

```bash
# Manual session management (usually handled by main.sh)
./lib/scripts/android/android_file_manager.sh start-session
./lib/scripts/android/android_file_manager.sh add templates/new_manifest.xml android/app/src/main/AndroidManifest.xml "Updated manifest with new permissions"
./lib/scripts/android/android_file_manager.sh update templates/build.gradle android/app/build.gradle.kts "Updated build configuration"
./lib/scripts/android/android_file_manager.sh generate build.gradle android/app/build.gradle.kts
./lib/scripts/android/android_file_manager.sh end-session

# Create a new directory
./lib/scripts/android/android_file_manager.sh create-dir android/app/src/main/java/com/example/app "Created package directory"
```

## Integration with main.sh

The `main.sh` script now automatically:

1. Initializes the file manager
2. **🆕 Starts a build session** to track all changes
3. Validates Android project structure
4. Uses file manager for all Android file operations
5. Shows a summary of all changes before reversion
6. **🆕 Ends the build session and reverts all changes**
7. **🆕 Cleans up session files**

## File Structure

```
lib/scripts/android/
├── android_file_manager.sh     # Main file manager script
├── main.sh                     # Updated main build script
├── templates/                  # Template files directory
├── android_backups/           # Backup files directory
├── android_changes.log        # Change log file
├── build_YYYYMMDD_HHMMSS_changes.log  # Session-specific change logs
└── README_ANDROID_RULES.md    # This file
```

## Backup System

- All file modifications are automatically backed up to `android_backups/`
- **🆕 Session-specific backups** are created in `android_backups/build_YYYYMMDD_HHMMSS/`
- Backup files are named with timestamps: `filename.backup.YYYYMMDD_HHMMSS`
- Original files are never directly modified without backup
- **🆕 Session backups are automatically cleaned up after reversion**

## Change Logging

All operations are logged to `android_changes.log` with:

- Timestamp
- Operation type (ADD, UPDATE, DELETE, etc.)
- File path
- Description

**🆕 Session-specific logging** is also maintained in `build_YYYYMMDD_HHMMSS_changes.log`

## Session Management

### Build Session Lifecycle:

1. **Session Start**: Creates session ID and backup directory
2. **Change Tracking**: All operations are logged to session file
3. **Backup Creation**: Original files are backed up before modification
4. **Session End**: All changes are reverted in reverse order
5. **Cleanup**: Session files and backups are removed

### Reversion Process:

- **Added Files**: Removed completely
- **Updated Files**: Restored from session backup
- **Replaced Files**: Removed completely
- **Created Directories**: Removed if empty
- **Deleted Files**: Restored from session backup

## Validation

The system validates that all required Android files exist:

- `android/build.gradle.kts`
- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `android/gradle.properties`
- `android/settings.gradle.kts`

## Templates

Available templates:

- `build.gradle` - Standard Flutter app build.gradle
- `AndroidManifest.xml` - Basic Android manifest

## Error Handling

- Script exits immediately on any error (`set -e`)
- Clear error messages with color coding
- Automatic rollback capabilities through backups
- Validation before destructive operations
- **🆕 Automatic session cleanup on errors**

## Best Practices

1. **Always use the file manager** for Android file changes
2. **Provide descriptive messages** for all operations
3. **Validate structure** before making changes
4. **Check backups** if something goes wrong
5. **Review change logs** regularly
6. **🆕 Let main.sh handle session management** automatically
7. **🆕 Don't manually end sessions** unless necessary

## Troubleshooting

### File Already Exists Error

```bash
# Use 'update' instead of 'add' for existing files
./lib/scripts/android/android_file_manager.sh update source_file target_file "description"
```

### Missing Required Files

```bash
# Validate structure first
./lib/scripts/android/android_file_manager.sh validate

# Generate missing files from templates
./lib/scripts/android/android_file_manager.sh generate template_name target_path
```

### Restore from Backup

```bash
# List available backups
./lib/scripts/android/android_file_manager.sh backups

# Restore specific backup
./lib/scripts/android/android_file_manager.sh restore backup_file target_path
```

### Session Issues

```bash
# If session gets stuck, manually end it
./lib/scripts/android/android_file_manager.sh end-session

# Check for orphaned session files
ls -la lib/scripts/android/build_*_changes.log
ls -la android_backups/build_*
```

## Security

- All file operations are logged
- Automatic backups prevent data loss
- Validation ensures project integrity
- No direct file modifications allowed
- **🆕 Automatic reversion prevents permanent changes**
- **🆕 Session isolation prevents cross-contamination**

## Compliance

This system ensures:

- ✅ All Android file changes are tracked
- ✅ Automatic backups for safety
- ✅ Clear audit trail
- ✅ No accidental file overwrites
- ✅ Project structure validation
- ✅ Consistent file management practices
- **🆕 Automatic reversion to original state**
- **🆕 Clean separation between build and source files**
- **🆕 No permanent modifications to Android project files**
