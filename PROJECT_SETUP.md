# QuikApp Project Setup Documentation

## Table of Contents

1. [Project Overview](#project-overview)
2. [System Requirements](#system-requirements)
3. [Project Structure](#project-structure)
4. [Workflow Configuration](#workflow-configuration)
5. [Environment Variables](#environment-variables)
6. [Build Process](#build-process)
7. [Email Configuration](#email-configuration)
8. [Security Considerations](#security-considerations)
9. [Troubleshooting](#troubleshooting)

## Project Overview

QuikApp is a Flutter-based mobile application build system that supports both Android and iOS platforms. The system is designed to be highly configurable and automated, with support for various features and customizations.

### Key Features

- Multi-platform build support (Android & iOS)
- Automated build process
- Configurable app settings
- Email notifications
- Asset management
- Security features

## System Requirements

### Development Environment

- macOS (for iOS builds)
- Flutter SDK (latest stable version)
- Xcode (latest version)
- Android Studio
- Node.js (latest LTS version)
- Git

### Build Environment (Codemagic)

- Instance Type: mac_mini_m2
- Max Build Duration: 120 minutes
- Required Integrations:
  - App Store Connect
  - Google Play Console
  - Firebase

## Project Structure

```
project_root/
├── lib/
│   └── scripts/
│       ├── android/
│       │   ├── main.sh
│       │   ├── balance_vars.sh
│       │   └── email_config.sh
│       ├── ios/
│       │   ├── main.sh
│       │   ├── balance_vars.sh
│       │   └── email_config.sh
│       ├── combined/
│       │   ├── main.sh
│       │   ├── balance_vars.sh
│       │   └── email_config.sh
│       └── email_config.sh
├── assets/
│   ├── icon.png
│   ├── splash.png
│   └── splash_bg.png
└── codemagic.yaml
```

## Workflow Configuration

### Available Workflows

1. **Android Build Workflow**

   - Name: Android Build
   - Purpose: Builds Android APK and AAB files
   - Output: APK and AAB artifacts

2. **iOS Build Workflow**

   - Name: iOS Build
   - Purpose: Builds iOS IPA file
   - Output: IPA artifact

3. **Combined Build Workflow**
   - Name: Combined Build
   - Purpose: Builds both Android and iOS artifacts
   - Output: APK, AAB, and IPA artifacts

### Workflow Steps

Each workflow follows these steps:

1. Load Balance Variables
2. Load Email Configuration
3. Run Build Process
4. Send Build Notification

## Environment Variables

### Required API Variables

```yaml
VERSION_NAME: "${VERSION_NAME}"
VERSION_CODE: "${VERSION_CODE}"
APP_NAME: "${APP_NAME}"
ORG_NAME: "${ORG_NAME}"
WEB_URL: "${WEB_URL}"
PKG_NAME: "${PKG_NAME}"
BUNDLE_ID: "${BUNDLE_ID}"
EMAIL_ID: "${EMAIL_ID}"
```

### Feature Flags

```yaml
PUSH_NOTIFY: "${PUSH_NOTIFY}"
IS_CHATBOT: "${IS_CHATBOT}"
IS_DEEPLINK: "${IS_DEEPLINK}"
IS_SPLASH: "${IS_SPLASH}"
IS_PULLDOWN: "${IS_PULLDOWN}"
IS_BOTTOMMENU: "${IS_BOTTOMMENU}"
IS_LOAD_IND: "${IS_LOAD_IND}"
```

### Permission Flags

```yaml
IS_CAMERA: "${IS_CAMERA}"
IS_LOCATION: "${IS_LOCATION}"
IS_MIC: "${IS_MIC}"
IS_NOTIFICATION: "${IS_NOTIFICATION}"
IS_CONTACT: "${IS_CONTACT}"
IS_BIOMETRIC: "${IS_BIOMETRIC}"
IS_CALENDAR: "${IS_CALENDAR}"
IS_STORAGE: "${IS_STORAGE}"
```

### UI Configuration

```yaml
LOGO_URL: "${LOGO_URL}"
SPLASH: "${SPLASH}"
SPLASH_BG: "${SPLASH_BG}"
SPLASH_BG_COLOR: "${SPLASH_BG_COLOR}"
SPLASH_TAGLINE: "${SPLASH_TAGLINE}"
SPLASH_TAGLINE_COLOR: "${SPLASH_TAGLINE_COLOR}"
SPLASH_ANIMATION: "${SPLASH_ANIMATION}"
SPLASH_DURATION: "${SPLASH_DURATION}"
```

### Bottom Menu Configuration

```yaml
BOTTOMMENU_ITEMS: "${BOTTOMMENU_ITEMS}"
BOTTOMMENU_BG_COLOR: "${BOTTOMMENU_BG_COLOR}"
BOTTOMMENU_ICON_COLOR: "${BOTTOMMENU_ICON_COLOR}"
BOTTOMMENU_TEXT_COLOR: "${BOTTOMMENU_TEXT_COLOR}"
BOTTOMMENU_FONT: "${BOTTOMMENU_FONT}"
BOTTOMMENU_FONT_SIZE: "${BOTTOMMENU_FONT_SIZE}"
BOTTOMMENU_FONT_BOLD: "${BOTTOMMENU_FONT_BOLD}"
BOTTOMMENU_FONT_ITALIC: "${BOTTOMMENU_FONT_ITALIC}"
BOTTOMMENU_ACTIVE_TAB_COLOR: "${BOTTOMMENU_ACTIVE_TAB_COLOR}"
BOTTOMMENU_ICON_POSITION: "${BOTTOMMENU_ICON_POSITION}"
BOTTOMMENU_VISIBLE_ON: "${BOTTOMMENU_VISIBLE_ON}"
```

### Security Configuration

```yaml
firebase_config_android: "${firebase_config_android}"
firebase_config_ios: "${firebase_config_ios}"
APPLE_TEAM_ID: "${APPLE_TEAM_ID}"
APNS_KEY_ID: "${APNS_KEY_ID}"
APNS_AUTH_KEY_URL: "${APNS_AUTH_KEY_URL}"
CERT_PASSWORD: "${CERT_PASSWORD}"
PROFILE_URL: "${PROFILE_URL}"
CERT_CER_URL: "${CERT_CER_URL}"
CERT_KEY_URL: "${CERT_KEY_URL}"
APP_STORE_CONNECT_KEY_IDENTIFIER: "${APP_STORE_CONNECT_KEY_IDENTIFIER}"
KEY_STORE: "${KEY_STORE}"
CM_KEYSTORE_PASSWORD: "${CM_KEYSTORE_PASSWORD}"
CM_KEY_ALIAS: "${CM_KEY_ALIAS}"
CM_KEY_PASSWORD: "${CM_KEY_PASSWORD}"
```

## Build Process

### Android Build Process

1. Load balance variables
2. Configure app details
3. Download and configure assets
4. Generate launcher icons
5. Build APK/AAB
6. Send build notification

### iOS Build Process

1. Load balance variables
2. Configure app details
3. Download and configure assets
4. Generate launcher icons
5. Setup certificates and provisioning
6. Build IPA
7. Send build notification

### Combined Build Process

1. Load balance variables
2. Configure app details for both platforms
3. Download and configure assets
4. Generate launcher icons
5. Build both Android and iOS artifacts
6. Send build notification

## Email Configuration

### SMTP Configuration

```bash
SMTP_SERVER="smtp.gmail.com"
SMTP_PORT="587"
SMTP_USER="your-email@gmail.com"
SMTP_PASS="your-app-password"
FROM_EMAIL="no-reply@quikapp.co"
REPLY_TO="support@quikapp.co"
```

### Email Templates

- Success Notification
- Error Notification
- Build Completion Notification

## Security Considerations

### API Security

- All API variables are passed through environment variables
- No hardcoded credentials in scripts
- Secure storage of sensitive information

### Build Security

- Secure certificate handling
- Protected keystore management
- Secure provisioning profile management

### Email Security

- SMTP over TLS
- App passwords for Gmail
- Redacted sensitive information in logs

## Troubleshooting

### Common Issues

1. **Build Failures**

   - Check environment variables
   - Verify API configurations
   - Review build logs

2. **Email Notification Issues**

   - Validate SMTP configuration
   - Check email credentials
   - Verify recipient addresses

3. **Asset Download Issues**
   - Verify asset URLs
   - Check network connectivity
   - Validate file permissions

### Debug Commands

```bash
# Validate email configuration
source lib/scripts/email_config.sh
validate_email_config

# Debug email settings
debug_email_config

# Check build environment
flutter doctor -v
```

## Support

For support and questions:

- Email: support@quikapp.co
- Documentation: [QuikApp Documentation](https://docs.quikapp.co)
- Issue Tracker: [GitHub Issues](https://github.com/quikapp/issues)

---

**Last Updated**: 2024
**Version**: 1.0
