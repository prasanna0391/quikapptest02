# QuikApp Email Notification System

## Overview

The QuikApp Email Notification System provides comprehensive, beautiful HTML email notifications for both successful builds and build failures. It includes intelligent error detection, detailed project information, and helpful resolution steps.

## Features

### 🎨 Beautiful HTML Templates

- **Success Email**: Modern design with green gradient header, project details, and artifact list
- **Error Email**: Professional error reporting with red gradient header, error details, and resolution steps
- **Responsive Design**: Works perfectly on desktop, tablet, and mobile devices
- **Branded Design**: Consistent QuikApp branding with gradients, icons, and professional styling

### 📧 Comprehensive Notifications

- **Success Notifications**: Include greetings, success message, project details, artifacts list, and contact support
- **Error Notifications**: Include error summary, detailed error information, resolution steps, project details, and contact support
- **Dynamic Content**: All content is dynamically generated based on build context and environment variables

### 🔍 Intelligent Error Detection

- **Automatic Error Classification**: Detects common build errors and categorizes them
- **Smart Resolution Steps**: Provides specific resolution steps based on error type
- **Detailed Error Logging**: Captures comprehensive build logs and environment information

### 📦 Artifact Management

- **Automatic Attachment**: Attaches build artifacts (APK, AAB, IPA) to success emails
- **Size Management**: Handles large files gracefully with size limits
- **File Type Icons**: Different icons for different file types (📱 APK, 📦 AAB, 🍎 IPA)

## File Structure

```
lib/scripts/
├── email_notification.py          # Main email notification system
├── handle_build_error.sh          # Comprehensive error handler
├── email_templates/
│   ├── success_email.html         # Success email template
│   └── error_email.html           # Error email template
├── android/
│   ├── send_error_email.sh        # Legacy error email script
│   └── send_output_email.py       # Legacy output email script
└── ios/
    ├── send_error_email.sh        # Legacy error email script
    └── send_output_email.sh       # Legacy output email script
```

## Email Templates

### Success Email Template (`success_email.html`)

**Features:**

- 🎉 Celebratory design with green gradient header
- 📱 Project details section with all build information
- 📦 Artifacts list with file sizes and icons
- 💬 Contact support section with multiple contact methods
- 📱 Responsive design for all devices

**Template Variables:**

- `{{APP_NAME}}` - Application name
- `{{PKG_NAME}}` - Package name
- `{{BUNDLE_ID}}` - Bundle identifier
- `{{VERSION_NAME}}` - Version name
- `{{VERSION_CODE}}` - Version code
- `{{WORKFLOW_NAME}}` - Workflow name
- `{{BUILD_TIME}}` - Build timestamp
- `{{BUILD_ID}}` - Unique build identifier
- `{{RECIPIENT_NAME}}` - Recipient's name (derived from email)
- `{{ARTIFACTS_LIST}}` - HTML list of build artifacts

### Error Email Template (`error_email.html`)

**Features:**

- 🚨 Error-focused design with red gradient header
- ❌ Error summary section
- 🔍 Detailed error information with code formatting
- 🔧 Step-by-step resolution guide
- 📱 Project details section
- 💬 Contact support section

**Template Variables:**

- All success template variables plus:
- `{{ERROR_MESSAGE}}` - Human-readable error message
- `{{ERROR_DETAILS}}` - Detailed error information
- `{{ERROR_TYPE}}` - Categorized error type
- `{{RESOLVE_STEPS}}` - HTML list of resolution steps

## Usage

### Basic Usage

```bash
# Send success notification
python3 lib/scripts/email_notification.py success

# Send error notification
python3 lib/scripts/email_notification.py error "Error message" "Error details"
```

### In Codemagic Workflows

The email system is automatically integrated into all Codemagic workflows:

```yaml
- name: Send success notification
  script: |
    #!/usr/bin/env bash
    set -e
    echo "Sending success notification..."

    # Make email notification script executable
    chmod +x lib/scripts/email_notification.py

    # Send success email
    python3 lib/scripts/email_notification.py success

    echo "Success notification sent"
```

### Error Handling

For comprehensive error handling, use the error handler script:

```bash
# Handle build errors automatically
lib/scripts/handle_build_error.sh "flutter build apk" "Android APK Build"
```

## Configuration

### Environment Variables

The email system uses the following environment variables:

```bash
# Email Configuration
EMAIL_ID="user@example.com"
SMTP_SERVER="smtp.gmail.com"
SMTP_PORT="587"
SMTP_USERNAME="your-email@gmail.com"
SMTP_PASSWORD="your-app-password"

# App Configuration
APP_NAME="My App"
PKG_NAME="com.example.myapp"
BUNDLE_ID="com.example.myapp"
VERSION_NAME="1.0.0"
VERSION_CODE="1"
WORKFLOW_NAME="Android Publish"
```

### SMTP Configuration

The system supports various SMTP providers:

**Gmail:**

```bash
SMTP_SERVER="smtp.gmail.com"
SMTP_PORT="587"
SMTP_USERNAME="your-email@gmail.com"
SMTP_PASSWORD="your-app-password"
```

**Outlook/Hotmail:**

```bash
SMTP_SERVER="smtp-mail.outlook.com"
SMTP_PORT="587"
SMTP_USERNAME="your-email@outlook.com"
SMTP_PASSWORD="your-password"
```

**Custom SMTP:**

```bash
SMTP_SERVER="your-smtp-server.com"
SMTP_PORT="587"
SMTP_USERNAME="your-username"
SMTP_PASSWORD="your-password"
```

## Error Detection

The system automatically detects and categorizes common build errors:

### Android Errors

- **v1 Embedding Issue**: Detects deprecated Flutter embedding
- **Missing Resources**: Detects missing drawable/mipmap resources
- **Firebase Configuration**: Detects Google Services configuration issues
- **Gradle Issues**: Detects build.gradle configuration problems
- **Compilation Errors**: Detects syntax and import issues

### iOS Errors

- **Code Signing**: Detects certificate and provisioning profile issues
- **CocoaPods**: Detects dependency installation problems
- **Xcode Build**: Detects archive and export issues

### General Errors

- **Flutter Environment**: Detects SDK and dependency issues
- **Permission Issues**: Detects file system and network access problems
- **Network Issues**: Detects connection and download problems
- **Memory Issues**: Detects out-of-memory conditions
- **Disk Space**: Detects insufficient disk space

## Resolution Steps

For each error type, the system provides specific resolution steps:

### Android v1 Embedding Issue

1. Run the fix_v1_embedding.sh script to resolve Android v1 embedding issues
2. Ensure all Android files are using v2 embedding
3. Clean the build cache with 'flutter clean'
4. Update Flutter to the latest stable version

### Firebase Configuration Error

1. Verify that google-services.json is properly configured
2. Check that the package name in google-services.json matches your app's package name
3. Ensure Firebase project is properly set up
4. Verify Firebase dependencies in pubspec.yaml

### Code Signing Error

1. Verify that certificates and provisioning profiles are valid
2. Check that the bundle identifier matches the provisioning profile
3. Ensure certificates are not expired
4. Verify keychain access and permissions

## Customization

### Adding Custom Error Types

To add custom error detection, modify the `detect_error_type` method in `email_notification.py`:

```python
def detect_error_type(self, error_message):
    error_message_lower = error_message.lower()

    # Add your custom error detection
    if "your-custom-error" in error_message_lower:
        return "Custom Error Type"

    # ... existing error detection
```

### Adding Custom Resolution Steps

To add custom resolution steps, modify the `generate_resolve_steps` method:

```python
def generate_resolve_steps(self, error_type):
    steps_map = {
        "Custom Error Type": [
            "Step 1: Your custom resolution step",
            "Step 2: Another custom resolution step",
        ],
        # ... existing error types
    }
```

### Customizing Email Templates

To customize email templates, edit the HTML files in `email_templates/`:

1. **Styling**: Modify the CSS in the `<style>` section
2. **Content**: Update the HTML structure and content
3. **Variables**: Add new template variables as needed
4. **Branding**: Update colors, logos, and contact information

## Troubleshooting

### Common Issues

**Email Not Sending:**

- Check SMTP configuration
- Verify email credentials
- Check network connectivity
- Review email service provider settings

**Template Not Found:**

- Ensure email templates exist in `lib/scripts/email_templates/`
- Check file permissions
- Verify template file names

**Error Detection Not Working:**

- Review error log format
- Check error message patterns
- Update error detection logic

### Debug Mode

Enable debug mode by setting environment variables:

```bash
export DEBUG_EMAIL=true
export VERBOSE_LOGGING=true
```

### Log Files

The system creates several log files for debugging:

- `build_error_log_YYYYMMDD_HHMMSS.txt` - Detailed build error logs
- `error_summary_YYYYMMDD_HHMMSS.txt` - Error summary files
- `build_success_email_YYYYMMDD_HHMMSS.html` - Success email content (if sending fails)
- `build_error_email_YYYYMMDD_HHMMSS.html` - Error email content (if sending fails)

## Support

For support with the email notification system:

- **Email**: support@quikapp.co
- **Website**: https://quikapp.co
- **Documentation**: https://docs.quikapp.co
- **GitHub**: https://github.com/quikapp

## Migration from Legacy System

The new email system is backward compatible with the legacy scripts:

- `lib/scripts/android/send_error_email.sh` - Still works as fallback
- `lib/scripts/android/send_output_email.py` - Still works as fallback
- `lib/scripts/ios/send_error_email.sh` - Still works as fallback
- `lib/scripts/ios/send_output_email.sh` - Still works as fallback

The new system will automatically use the legacy scripts if the main Python script fails.

## Future Enhancements

Planned improvements for the email notification system:

- **Email Templates**: More template variations and themes
- **Error Detection**: Enhanced error pattern recognition
- **Integration**: Better integration with external services
- **Analytics**: Email delivery and open rate tracking
- **Customization**: More customization options for users
