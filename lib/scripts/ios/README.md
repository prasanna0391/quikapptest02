# iOS Build System

This directory contains a comprehensive iOS build system that mirrors the Android build structure, providing a complete Flutter-to-IPA pipeline with environment-driven configuration, code signing, and automated notifications.

## 🚀 Quick Start

```bash
# Run the complete iOS build
./lib/scripts/ios/main.sh
```

## 📁 Script Structure

### Main Orchestrator

- **`main.sh`** - Main build orchestrator that runs all steps sequentially

### Environment & Configuration

- **`export.sh`** - Centralized environment variables with defaults and validation

### Code Signing & Certificates

- **`download_certificates.sh`** - Downloads certificates, keys, and provisioning profiles
- **`verify_profile.sh`** - Validates provisioning profile compatibility
- **`generate_p12.sh`** - Creates .p12 certificate from .cer and .key files

### Project Configuration

- **`update_project_config.sh`** - Updates app name, bundle ID, and version
- **`handle_assets.sh`** - Downloads and configures app assets (logo, splash, icons)
- **`setup_cocoapods.sh`** - Sets up CocoaPods with proper configuration
- **`update_xcode_settings.sh`** - Updates Xcode project for code signing
- **`create_entitlements.sh`** - Generates app entitlements based on permissions

### Build & Export

- **`archive_app.sh`** - Creates Xcode archive
- **`export_ipa.sh`** - Exports IPA from archive
- **`move_outputs.sh`** - Moves artifacts to final output directory

### Notifications & Cleanup

- **`send_output_email.sh`** - Sends success email with IPA attachment (<25MB)
- **`send_error_email.sh`** - Sends error email with troubleshooting steps
- **`cleanup.sh`** - Cleans up temporary files and build artifacts

## 🔧 Environment Configuration

Edit `export.sh` to configure your build:

```bash
# App Information
export APP_NAME="My iOS App"
export BUNDLE_ID="com.example.myapp"
export VERSION_NAME="1.0.0"
export VERSION_CODE="1"

# Code Signing
export APPLE_TEAM_ID="YOUR_TEAM_ID"
export PROFILE_URL="https://example.com/profile.mobileprovision"
export CER_URL="https://example.com/certificate.cer"
export KEY_URL="https://example.com/private.key"

# Email Notifications
export EMAIL_ID="developer@example.com"
export SMTP_SERVER="smtp.gmail.com"
export SMTP_USERNAME="your-email@gmail.com"
export SMTP_PASSWORD="your-app-password"

# Features & Permissions
export IS_CAMERA="true"
export IS_LOCATION="false"
export PUSH_NOTIFY="true"
```

## 📱 Build Process

The build system follows this workflow:

1. **Environment Setup** - Loads and validates environment variables
2. **Certificate Management** - Downloads and verifies code signing files
3. **Project Configuration** - Updates app details and bundle ID
4. **Asset Handling** - Downloads logo, splash, and generates icons
5. **CocoaPods Setup** - Installs and configures dependencies
6. **Xcode Configuration** - Updates project settings for code signing
7. **Entitlements** - Generates app entitlements based on permissions
8. **Archive** - Creates Xcode archive
9. **Export** - Exports IPA using specified method
10. **Artifact Management** - Moves outputs to final directory
11. **Notification** - Sends success/error emails
12. **Cleanup** - Removes temporary files

## 🎯 Build Methods

Supported export methods:

- `ad-hoc` - For internal testing
- `app-store` - For App Store distribution
- `enterprise` - For enterprise distribution
- `development` - For development builds

## 📧 Email Notifications

### Success Email

- ✅ Greeting and success message
- 📱 App details and version information
- 📦 Build artifacts and file sizes
- 🔧 Build configuration summary
- 📎 IPA attachment (if <25MB)
- 🌐 App website link (if configured)

### Error Email

- ❌ Error details and exit code
- 📋 Recent log entries
- 🔧 Troubleshooting steps
- 📱 Project information
- 🌐 App website link (if configured)

## 🔐 Code Signing

The system supports:

- **Certificate Download** - From URLs specified in environment
- **Profile Verification** - Validates compatibility and expiration
- **P12 Generation** - Creates .p12 from .cer and .key
- **Manual Signing** - Configures Xcode for manual code signing
- **Entitlements** - Dynamic generation based on permissions

## 📋 Permissions & Features

Configurable permissions via environment variables:

- `IS_CAMERA` - Camera access
- `IS_LOCATION` - Location services
- `IS_MIC` - Microphone access
- `IS_CONTACT` - Contacts access
- `IS_CALENDAR` - Calendar access
- `IS_PHOTO_LIBRARY` - Photo library access
- `IS_BIOMETRIC` - Biometric authentication
- `PUSH_NOTIFY` - Push notifications

## 🛠️ Requirements

- **macOS** - Required for iOS builds
- **Xcode** - Command line tools and project
- **Flutter** - Flutter SDK and dependencies
- **CocoaPods** - For dependency management
- **Python 3** - For email notifications
- **OpenSSL** - For certificate operations

## 🔄 CI/CD Integration

The scripts are designed to work with Codemagic CI/CD:

```yaml
# In codemagic.yaml
scripts:
  - name: iOS Build
    script: |
      source lib/scripts/ios/export.sh
      lib/scripts/ios/main.sh
```

## 📊 Output Structure

```
build_outputs/
└── ios_20241201_143022/
    ├── my_app_v1.0.0_build1.ipa
    ├── Runner.xcarchive/
    ├── ExportOptions.plist
    ├── profile.mobileprovision
    └── build_info.txt
```

## 🚨 Troubleshooting

### Common Issues

1. **Code Signing Errors**

   - Verify certificate and key match
   - Check provisioning profile expiration
   - Ensure bundle ID matches profile

2. **CocoaPods Issues**

   - Run `pod install` manually
   - Check iOS deployment target
   - Verify Flutter dependencies

3. **Archive Failures**

   - Check Xcode project settings
   - Verify entitlements configuration
   - Ensure all dependencies are resolved

4. **Email Failures**
   - Check SMTP credentials
   - Verify network connectivity
   - Check file size limits

### Debug Mode

Run individual scripts for debugging:

```bash
# Test certificate download
./lib/scripts/ios/download_certificates.sh

# Test profile verification
./lib/scripts/ios/verify_profile.sh

# Test email configuration
./lib/scripts/ios/send_output_email.sh
```

## 📝 Logging

All builds generate detailed logs:

- **Build Log** - `build_logs/ios_build_TIMESTAMP.log`
- **Changes Log** - `build_logs/ios_build_TIMESTAMP_changes.log`
- **Build Info** - `build_outputs/ios_TIMESTAMP/build_info.txt`

## 🔗 Related Files

- **Android Build System** - `lib/scripts/android/`
- **Codemagic Configuration** - `lib/codemagic.yaml`
- **Flutter Configuration** - `pubspec.yaml`

## 📞 Support

For issues or questions:

1. Check the build logs for specific errors
2. Review the troubleshooting section
3. Verify environment configuration
4. Test individual script components

---

**iOS Build System** - Complete Flutter-to-IPA pipeline with automated code signing, notifications, and artifact management.
