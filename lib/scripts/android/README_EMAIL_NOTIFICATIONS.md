# Email Notification System for Android Builds

This document explains the email notification system that automatically sends error notifications when the Android build process fails.

## Overview

The email notification system is integrated into the main build script (`main.sh`) and automatically sends detailed error notifications to the registered email address when any build step fails.

## Features

- ✅ **Automatic Error Detection**: Captures build failures and error details
- ✅ **Smart Error Analysis**: Identifies common error types and provides specific resolution steps
- ✅ **Professional Email Format**: Beautiful HTML emails with error details and resolution steps
- ✅ **Build Information**: Includes project details, version, and build timestamp
- ✅ **Multiple Error Types**: Handles v1 embedding, missing resources, Google Services, compilation, and Gradle errors

## Email Configuration

### Recipient Email

The recipient email is configured in `export.sh`:

```bash
export EMAIL_ID="prasannasrie@gmail.com"
```

### Sender Email

Emails are sent from: `build@quikapp.co`

## How It Works

### 1. Error Detection

When `main.sh` runs, it includes error handling that:

- Captures any command failures
- Records the error line number and command
- Captures recent build logs for detailed error information

### 2. Error Analysis

The system automatically analyzes errors and categorizes them:

- **v1_embedding**: Flutter v1 embedding issues
- **missing_resource**: Missing resource files (icons, drawables, etc.)
- **google_services**: Google Services/Firebase configuration issues
- **compilation**: Kotlin/Java compilation errors
- **gradle**: Gradle build configuration errors
- **unknown**: Other unexpected errors

### 3. Email Generation

For each error type, the system generates:

- **Error Summary**: Brief description of the issue
- **Error Details**: Full error message and stack trace
- **Resolution Steps**: Specific steps to fix the issue
- **Build Information**: Project details and build metadata

## Email Content

### Email Structure

```
🚨 Build Failed - Garbcode App Android Build
├── Hello, [Greeting]
├── ❌ Error Summary: [Brief error description]
├── 📋 Error Details: [Full error logs]
├── 🔧 Resolution Steps: [Numbered list of fixes]
├── Build Information: [Project details]
└── Footer: [Automated notification disclaimer]
```

### Example Email Content

```html
🚨 Build Failed Hello, The Android build process for Garbcode App has
encountered an error and failed to complete successfully. ❌ Error Summary:
Android v1 embedding detected - FlutterApplication is deprecated 📋 Error
Details: Error: io.flutter.app.FlutterApplication is not available in Flutter v2
embedding. Please update MainApplication.kt to use android.app.Application
instead. 🔧 Resolution Steps: 1. Run the fix_v1_embedding.sh script to resolve
Android v1 embedding issues 2. Ensure all Android files are using v2 embedding
3. Clean the build cache with 'flutter clean' Build Information: • Project:
Garbcode App • Package: com.garbcode.garbcodeapp • Version: 1.0.22 • Build Time:
2025-06-12 13:22:33 • Build ID: 20250612_132233
```

## Files and Scripts

### Core Scripts

- `main.sh` - Main build script with integrated error handling
- `send_error_email.sh` - Email notification script
- `capture_build_logs.sh` - Build log capture and analysis
- `test_error_email.sh` - Test script for email notifications

### Configuration Files

- `export.sh` - Contains EMAIL_ID configuration

## Usage

### Running the Build with Email Notifications

```bash
# Run the main build script (includes error notifications)
lib/scripts/android/main.sh
```

### Testing Email Notifications

```bash
# Test the email notification system
lib/scripts/android/test_error_email.sh
```

### Manual Error Email

```bash
# Send a custom error email
lib/scripts/android/send_error_email.sh "Error message" "Error details"
```

## Error Types and Resolution Steps

### 1. V1 Embedding Errors

**Detection**: Contains "v1 embedding", "FlutterApplication", or "FlutterActivity"
**Resolution Steps**:

- Run the fix_v1_embedding.sh script
- Ensure all Android files use v2 embedding
- Clean build cache with 'flutter clean'

### 2. Missing Resource Errors

**Detection**: Contains "resource not found", "mipmap", or "drawable"
**Resolution Steps**:

- Check required resource files in android/app/src/main/res/
- Verify launcher icons are properly configured
- Run 'flutter pub get' to ensure dependencies

### 3. Google Services Errors

**Detection**: Contains "google-services", "Firebase", or "package name"
**Resolution Steps**:

- Verify google-services.json configuration
- Check package name matches in google-services.json
- Ensure Firebase project is properly set up

### 4. Compilation Errors

**Detection**: Contains "compilation", "syntax", or "import"
**Resolution Steps**:

- Check for syntax errors in Kotlin/Java files
- Verify all required imports are present
- Run 'flutter clean' and try building again

### 5. Gradle Errors

**Detection**: Contains "gradle" or "build.gradle"
**Resolution Steps**:

- Check Gradle configuration files for errors
- Verify all dependencies are compatible
- Try updating Gradle version if needed

## Email Service Integration

### Current Implementation

The current implementation saves email content as HTML files for debugging. To actually send emails, you need to integrate with an email service.

### Recommended Email Services

1. **SendGrid**: REST API for sending emails
2. **Mailgun**: Email service with API
3. **SMTP**: Direct SMTP server integration
4. **AWS SES**: Amazon Simple Email Service

### Example SendGrid Integration

```bash
# In send_error_email.sh, replace the placeholder with:
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SENDGRID_API_KEY" \
  -d "{\"to\":\"${recipient_email}\",\"from\":\"${from_email}\",\"subject\":\"${subject}\",\"html\":\"${html_content}\"}" \
  https://api.sendgrid.com/v3/mail/send
```

## Troubleshooting

### Email Not Sent

- Check if `EMAIL_ID` is set in `export.sh`
- Verify curl is installed: `which curl`
- Check email service API keys and configuration
- Review generated HTML files for email content

### Error Detection Issues

- Check build logs for error patterns
- Update error detection patterns in `send_error_email.sh`
- Test with `test_error_email.sh`

### Build Logs Not Captured

- Ensure `capture_build_logs.sh` is properly integrated
- Check file permissions for log writing
- Verify log file paths are correct

## Security Considerations

- Store email service API keys securely
- Use environment variables for sensitive configuration
- Implement rate limiting for email sending
- Validate email addresses before sending

## Future Enhancements

- [ ] Add success email notifications
- [ ] Include build performance metrics
- [ ] Add email templates for different project types
- [ ] Implement email scheduling and retry logic
- [ ] Add webhook notifications for CI/CD integration

## Support

For issues with the email notification system:

1. Check the generated HTML files for email content
2. Review build logs for error details
3. Test with `test_error_email.sh`
4. Contact the development team for assistance
