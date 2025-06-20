# QuikApp Build System

This directory contains the build scripts for the QuikApp project. The build system supports building for Android, iOS, and combined builds.

## Directory Structure

```
lib/scripts/
├── android/              # Android-specific build scripts
│   ├── main.sh          # Main Android build script
│   └── send_error_email.sh
├── ios/                 # iOS-specific build scripts
│   ├── main.sh          # Main iOS build script
│   └── send_error_email.sh
├── combined/            # Combined build scripts
│   ├── main.sh          # Main combined build script
│   ├── export.sh        # Environment variables
│   ├── validate.sh      # Environment validation
│   ├── configure_app.sh # App configuration
│   ├── build_android.sh # Android build
│   ├── build_ios.sh     # iOS build
│   └── send_error_email.sh
└── README.md           # This file
```

## Prerequisites

Before running the build scripts, ensure you have:

1. Flutter SDK installed and in your PATH
2. Android SDK installed (for Android builds)
3. Xcode installed (for iOS builds)
4. Required environment variables set (see Environment Variables section)

## Environment Variables

### Required Variables

- `APP_NAME`: Name of your application
- `PKG_NAME`: Android package name (e.g., com.example.app)
- `BUNDLE_ID`: iOS bundle identifier (e.g., com.example.app)
- `VERSION_NAME`: App version name (e.g., 1.0.0)
- `VERSION_CODE`: App version code (e.g., 1)
- `ORG_NAME`: Organization name
- `WEB_URL`: Web URL for the app
- `EMAIL_ID`: Email for notifications

### Optional Variables

#### Feature Flags

- `PUSH_NOTIFY`: Enable push notifications (true/false)
- `IS_CHATBOT`: Enable chatbot feature (true/false)
- `IS_DEEPLINK`: Enable deep linking (true/false)
- `IS_SPLASH`: Enable splash screen (true/false)
- `IS_PULLDOWN`: Enable pull-to-refresh (true/false)
- `IS_BOTTOMMENU`: Enable bottom menu (true/false)
- `IS_LOAD_IND`: Enable loading indicator (true/false)

#### Firebase Configuration

- `FIREBASE_CONFIG_ANDROID`: URL to google-services.json
- `FIREBASE_CONFIG_IOS`: URL to GoogleService-Info.plist

#### Android Configuration

- `KEY_STORE`: URL to keystore file
- `CM_KEYSTORE_PASSWORD`: Keystore password
- `CM_KEY_ALIAS`: Key alias
- `CM_KEY_PASSWORD`: Key password

#### iOS Configuration

- `APPLE_TEAM_ID`: Apple Team ID
- `APNS_KEY_ID`: APNS Key ID
- `APNS_AUTH_KEY_URL`: URL to APNS auth key
- `CERT_PASSWORD`: Certificate password
- `PROFILE_URL`: URL to provisioning profile
- `CERT_CER_URL`: URL to certificate
- `CERT_KEY_URL`: URL to private key

## Usage

### Android Build

```bash
# Make scripts executable
chmod +x lib/scripts/android/*.sh

# Run Android build
bash lib/scripts/android/main.sh
```

### iOS Build

```bash
# Make scripts executable
chmod +x lib/scripts/ios/*.sh

# Run iOS build
bash lib/scripts/ios/main.sh
```

### Combined Build

```bash
# Make scripts executable
chmod +x lib/scripts/combined/*.sh

# Run combined build
bash lib/scripts/combined/main.sh
```

## Build Output

The build system generates the following artifacts:

### Android

- APK file: `output/app-release.apk`
- AAB file: `output/app-release.aab`

### iOS

- IPA file: `output/Runner.ipa`

## Error Handling

The build system includes comprehensive error handling:

1. Environment validation
2. Build process monitoring
3. Email notifications on failure
4. Detailed error logs

## Troubleshooting

### Common Issues

1. **Permission Denied**

   ```bash
   chmod +x lib/scripts/*/*.sh
   ```

2. **Missing Environment Variables**

   - Check `export.sh` for required variables
   - Ensure all required variables are set

3. **Build Failures**
   - Check build logs in `android/build/reports/problems/`
   - Verify Firebase configuration
   - Check keystore configuration

### Getting Help

For issues not covered in this README:

1. Check the build logs
2. Review error notifications
3. Contact the development team

## Contributing

1. Follow the existing script structure
2. Add error handling to new scripts
3. Update this README with new features
4. Test changes thoroughly

## License

This build system is proprietary and confidential.
