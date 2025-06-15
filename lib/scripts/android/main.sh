#!/bin/bash
set -e

# Ensure we're using bash
if [ -z "$BASH_VERSION" ]; then
    exec /bin/bash "$0" "$@"
fi

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Make all .sh files executable
make_scripts_executable() {
    print_section "Making scripts executable"
    find "$SCRIPT_DIR/.." -type f -name "*.sh" -exec chmod +x {} \;
    echo "✅ All .sh files are now executable"
}

# Print section header
print_section() {
    echo "=== $1 ==="
}

# Source the admin variables
if [ -f "${SCRIPT_DIR}/admin_vars.sh" ]; then
    source "${SCRIPT_DIR}/admin_vars.sh"
else
    echo "Error: admin_vars.sh not found in ${SCRIPT_DIR}"
    exit 1
fi

# Source download functions
if [ -f "${SCRIPT_DIR}/../combined/download.sh" ]; then
    source "${SCRIPT_DIR}/../combined/download.sh"
else
    echo "Error: download.sh not found in ${SCRIPT_DIR}/../combined"
    exit 1
fi

# Load the email configuration
if [ -f "${SCRIPT_DIR}/email_config.sh" ]; then
    source "${SCRIPT_DIR}/email_config.sh"
else
    echo "Error: email_config.sh not found in ${SCRIPT_DIR}"
    exit 1
fi

# Phase 1: Project Setup & Core Configuration
setup_build_environment() {
    echo "Setting up build environment..."
    
    # Source variables from admin panel
    if [ -f "lib/scripts/android/admin_vars.sh" ]; then
        source lib/scripts/android/admin_vars.sh
    else
        echo "Error: admin_vars.sh not found"
        return 1
    fi
    
    # Validate required variables
    if [ -z "$APP_NAME" ] || [ -z "$PKG_NAME" ] || [ -z "$VERSION_NAME" ] || [ -z "$VERSION_CODE" ]; then
        echo "Error: Required variables not set"
        return 1
    fi
    
    # Create necessary directories
    mkdir -p "$ASSETS_DIR"
    mkdir -p "$ANDROID_MIPMAP_DIR"
    mkdir -p "$ANDROID_DRAWABLE_DIR"
    mkdir -p "$ANDROID_VALUES_DIR"
    
    return 0
}

download_splash_assets() {
    echo "Downloading splash assets..."
    
    # Download logo if provided
    if [ -n "$LOGO_URL" ]; then
        curl -L "$LOGO_URL" -o "$ASSETS_DIR/logo.png"
    fi
    
    # Download splash screen if provided
    if [ -n "$SPLASH" ]; then
        curl -L "$SPLASH" -o "$ASSETS_DIR/splash.png"
    fi
    
    # Download splash background if provided
    if [ -n "$SPLASH_BG" ]; then
        curl -L "$SPLASH_BG" -o "$ASSETS_DIR/splash_bg.png"
    fi
    
    return 0
}

generate_launcher_icons() {
    echo "Generating launcher icons..."
    
    # Check if flutter_launcher_icons is in pubspec.yaml
    if ! grep -q "flutter_launcher_icons" pubspec.yaml; then
        echo "Error: flutter_launcher_icons not found in pubspec.yaml"
        return 1
    fi
    
    # Run icon generation
    flutter pub run flutter_launcher_icons:main
    
    # Verify icons were generated
    local icon_paths=(
        "$ANDROID_MIPMAP_DIR-hdpi/ic_launcher.png"
        "$ANDROID_MIPMAP_DIR-mdpi/ic_launcher.png"
        "$ANDROID_MIPMAP_DIR-xhdpi/ic_launcher.png"
        "$ANDROID_MIPMAP_DIR-xxhdpi/ic_launcher.png"
        "$ANDROID_MIPMAP_DIR-xxxhdpi/ic_launcher.png"
    )
    
    local missing_icons=0
    for icon_path in "${icon_paths[@]}"; do
        if [ ! -f "$icon_path" ]; then
            echo "Error: Missing icon at $icon_path"
            missing_icons=$((missing_icons + 1))
        fi
    done
    
    if [ $missing_icons -gt 0 ]; then
        echo "Error: $missing_icons icons are missing"
        return 1
    fi
    
    return 0
}

# Phase 2: Conditional Integration (Firebase & Keystore)
setup_firebase() {
    echo "Setting up Firebase configuration..."
    
    # Check if Firebase is required
    if [ "$PUSH_NOTIFY" != "true" ]; then
        echo "Firebase integration not required (PUSH_NOTIFY is false)"
        return 0
    fi
    
    # Check if Firebase config is provided
    if [ -z "$firebase_config_android" ]; then
        echo "Error: Firebase configuration not provided"
        return 1
    fi
    
    # Remove any existing google-services.json
    rm -f "$ANDROID_FIREBASE_CONFIG_PATH"
    
    # Create Firebase config directory
    mkdir -p "$(dirname "$ANDROID_FIREBASE_CONFIG_PATH")"
    
    # Write Firebase config to file
    echo "$firebase_config_android" > "$ANDROID_FIREBASE_CONFIG_PATH"
    
    # Copy to assets if needed
    cp "$ANDROID_FIREBASE_CONFIG_PATH" "$ASSETS_DIR/google-services.json"
    
    # Verify Firebase config was created
    if [ ! -f "$ANDROID_FIREBASE_CONFIG_PATH" ]; then
        echo "Error: Failed to create Firebase configuration file"
        return 1
    fi
    
    echo "Firebase configuration setup completed successfully"
    return 0
}

setup_keystore() {
    echo "Setting up Android keystore..."
    
    # Check if keystore is required
    if [ -z "$KEY_STORE" ]; then
        echo "Keystore not provided, using debug keystore"
        return 0
    fi
    
    # Create keystore directory
    mkdir -p "$(dirname "$ANDROID_KEYSTORE_PATH")"
    
    # Remove any existing keystore
    rm -f "$ANDROID_KEYSTORE_PATH"
    
    # Write keystore to file
    echo "$KEY_STORE" > "$ANDROID_KEYSTORE_PATH"
    
    # Verify keystore was created
    if [ ! -f "$ANDROID_KEYSTORE_PATH" ]; then
        echo "Error: Failed to create keystore file"
        return 1
    fi
    
    # Create key.properties file
    cat > "$ANDROID_KEY_PROPERTIES_PATH" << EOF
storeFile=keystore.jks
storePassword=$CM_KEYSTORE_PASSWORD
keyAlias=$CM_KEY_ALIAS
keyPassword=$CM_KEY_PASSWORD
EOF
    
    echo "Keystore setup completed successfully"
    return 0
}

# Email notification functions
handle_build_error() {
    local error_message="$1"
    echo "Build Error: $error_message"
    
    # Send error notification if email is configured
    if [ -n "$EMAIL_ID" ]; then
        echo "Sending error notification to $EMAIL_ID"
        python3 lib/scripts/email_notification.py error "Build Failed" "$error_message"
    fi
    
    exit 1
}

handle_build_success() {
    echo "Build completed successfully"
    
    # Send success notification if email is configured
    if [ -n "$EMAIL_ID" ]; then
        echo "Sending success notification to $EMAIL_ID"
        python3 lib/scripts/email_notification.py success
    fi
    
    exit 0
}

update_gradle_files() {
    echo "Updating Gradle files..."
    
    # Remove any existing .kts files to avoid conflicts
    find android -name "*.gradle.kts" -type f -delete
    
    # Check for Firebase and keystore
    local has_firebase="false"
    local has_keystore="false"
    
    if [ "$PUSH_NOTIFY" = "true" ]; then
        has_firebase="true"
    fi
    
    if [ -n "$KEY_STORE" ]; then
        has_keystore="true"
    fi
    
    # Update root build.gradle
    local root_build_gradle="android/build.gradle"
    cat > "$root_build_gradle" << EOF
buildscript {
    ext.kotlin_version = '1.9.20'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:8.2.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:\$kotlin_version"
        classpath 'com.google.gms:google-services:4.4.0'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = '../build'
subprojects {
    project.buildDir = "\${rootProject.buildDir}/\${project.name}"
}
EOF

    # Update app build.gradle
    local app_build_gradle="android/app/build.gradle"
    cat > "$app_build_gradle" << EOF
def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterRoot = localProperties.getProperty('flutter.sdk')
if (flutterRoot == null) {
    throw new GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
}

apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply from: "\$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"
${has_firebase ? "apply plugin: 'com.google.gms.google-services'" : ""}

android {
    namespace "$PACKAGE_NAME"
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
        applicationId "$PACKAGE_NAME"
        minSdkVersion flutter.minSdkVersion
        targetSdkVersion flutter.targetSdkVersion
        versionCode $VERSION_CODE
        versionName "$VERSION_NAME"
    }

    signingConfigs {
        ${has_keystore ? "release {
            storeFile file('$KEY_STORE')
            storePassword '$KEY_STORE_PASSWORD'
            keyAlias '$KEY_ALIAS'
            keyPassword '$KEY_PASSWORD'
        }" : ""}
    }

    buildTypes {
        release {
            signingConfig ${has_keystore ? "signingConfigs.release" : "null"}
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}

flutter {
    source '../..'
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:\$kotlin_version"
    ${has_firebase ? "implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'" : ""}
}
EOF

    # Update settings.gradle
    local settings_gradle="android/settings.gradle"
    cat > "$settings_gradle" << EOF
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        google()
        mavenCentral()
    }
}

include ':app'

def flutterProjectRoot = rootProject.projectDir.parentFile
def pluginsFile = new File(flutterProjectRoot, '.flutter-plugins')
if (pluginsFile.exists()) {
    pluginsFile.withReader('UTF-8') { reader ->
        def plugins = new Properties()
        plugins.load(reader)
        plugins.each { name, path ->
            def pluginDirectory = new File(flutterProjectRoot, path).resolve('android')
            if (pluginDirectory.exists()) {
                include ":\$name"
                project(":\$name").projectDir = pluginDirectory
            }
        }
    }
}

def flutterSdkPath = System.getenv('FLUTTER_ROOT') ?: System.getProperty('user.home') + '/flutter'
if (new File(flutterSdkPath).exists()) {
    include ':flutter'
    project(':flutter').projectDir = new File(flutterSdkPath)
}
EOF

    # Create gradle.properties if it doesn't exist
    local gradle_properties="android/gradle.properties"
    if [ ! -f "$gradle_properties" ]; then
        cat > "$gradle_properties" << EOF
org.gradle.jvmargs=-Xmx1536M
android.useAndroidX=true
android.enableJetifier=true
EOF
    fi

    return 0
}

# Phase 3: Verification & Build
verify_requirements() {
    echo "Verifying requirements..."
    
    # Check Flutter environment
    if ! command -v flutter &> /dev/null; then
        echo "Error: Flutter not found"
        return 1
    fi
    
    # Check Android SDK
    if [ -z "$ANDROID_HOME" ]; then
        echo "Error: ANDROID_HOME not set"
        return 1
    fi
    
    # Check Firebase config if needed
    if [ "$PUSH_NOTIFY" = "true" ] && [ ! -f "$ANDROID_FIREBASE_CONFIG_PATH" ]; then
        echo "Error: Firebase config not found"
        return 1
    fi
    
    # Check keystore if provided
    if [ -n "$KEY_STORE" ] && [ ! -f "$ANDROID_KEYSTORE_PATH" ]; then
        echo "Error: Keystore not found"
        return 1
    fi
    
    return 0
}

build_android_app() {
    echo "Building Android app..."
    
    # Clean the project
    flutter clean
    
    # Get dependencies
    flutter pub get
    
    # Create/update Gradle wrapper
    cd android
    if [ ! -f "gradlew" ]; then
        echo "Creating Gradle wrapper..."
        gradle wrapper --gradle-version 8.2
    else
        echo "Updating Gradle wrapper..."
        ./gradlew wrapper --gradle-version 8.2
    fi
    
    # Make gradlew executable
    chmod +x gradlew
    
    # Verify Gradle wrapper
    if [ ! -f "gradlew" ]; then
        echo "Error: Failed to create/update Gradle wrapper"
        return 1
    fi
    
    # Clean Gradle
    ./gradlew clean
    
    cd ..
    
    # Build the app with all Dart defines
    if [ -n "$KEY_STORE" ]; then
        flutter build apk --release --verbose \
            --dart-define=WEB_URL="$WEB_URL" \
            --dart-define=PUSH_NOTIFY="$PUSH_NOTIFY" \
            --dart-define=PKG_NAME="$PKG_NAME" \
            --dart-define=APP_NAME="$APP_NAME" \
            --dart-define=ORG_NAME="$ORG_NAME" \
            --dart-define=VERSION_NAME="$VERSION_NAME" \
            --dart-define=VERSION_CODE="$VERSION_CODE" \
            --dart-define=EMAIL_ID="$EMAIL_ID" \
            --dart-define=IS_SPLASH="$IS_SPLASH" \
            --dart-define=SPLASH="$SPLASH" \
            --dart-define=SPLASH_BG="$SPLASH_BG" \
            --dart-define=SPLASH_ANIMATION="$SPLASH_ANIMATION" \
            --dart-define=SPLASH_BG_COLOR="$SPLASH_BG_COLOR" \
            --dart-define=SPLASH_TAGLINE="$SPLASH_TAGLINE" \
            --dart-define=SPLASH_TAGLINE_COLOR="$SPLASH_TAGLINE_COLOR" \
            --dart-define=SPLASH_DURATION="$SPLASH_DURATION" \
            --dart-define=IS_PULLDOWN="$IS_PULLDOWN" \
            --dart-define=LOGO_URL="$LOGO_URL" \
            --dart-define=IS_BOTTOMMENU="$IS_BOTTOMMENU" \
            --dart-define=BOTTOMMENU_ITEMS="$BOTTOMMENU_ITEMS" \
            --dart-define=BOTTOMMENU_BG_COLOR="$BOTTOMMENU_BG_COLOR" \
            --dart-define=BOTTOMMENU_ICON_COLOR="$BOTTOMMENU_ICON_COLOR" \
            --dart-define=BOTTOMMENU_TEXT_COLOR="$BOTTOMMENU_TEXT_COLOR" \
            --dart-define=BOTTOMMENU_FONT="$BOTTOMMENU_FONT" \
            --dart-define=BOTTOMMENU_FONT_SIZE="$BOTTOMMENU_FONT_SIZE" \
            --dart-define=BOTTOMMENU_FONT_BOLD="$BOTTOMMENU_FONT_BOLD" \
            --dart-define=BOTTOMMENU_FONT_ITALIC="$BOTTOMMENU_FONT_ITALIC" \
            --dart-define=BOTTOMMENU_ACTIVE_TAB_COLOR="$BOTTOMMENU_ACTIVE_TAB_COLOR" \
            --dart-define=BOTTOMMENU_ICON_POSITION="$BOTTOMMENU_ICON_POSITION" \
            --dart-define=BOTTOMMENU_VISIBLE_ON="$BOTTOMMENU_VISIBLE_ON" \
            --dart-define=IS_DEEPLINK="$IS_DEEPLINK" \
            --dart-define=IS_LOAD_IND="$IS_LOAD_IND" \
            --dart-define=IS_CHATBOT="$IS_CHATBOT" \
            --dart-define=IS_CAMERA="$IS_CAMERA" \
            --dart-define=IS_LOCATION="$IS_LOCATION" \
            --dart-define=IS_BIOMETRIC="$IS_BIOMETRIC" \
            --dart-define=IS_MIC="$IS_MIC" \
            --dart-define=IS_CONTACT="$IS_CONTACT" \
            --dart-define=IS_CALENDAR="$IS_CALENDAR" \
            --dart-define=IS_NOTIFICATION="$IS_NOTIFICATION" \
            --dart-define=IS_STORAGE="$IS_STORAGE" \
            --dart-define=firebase_config_android="$firebase_config_android" \
            --dart-define=firebase_config_ios="$firebase_config_ios" \
            --dart-define=APNS_KEY_ID="$APNS_KEY_ID" \
            --dart-define=APPLE_TEAM_ID="$APPLE_TEAM_ID" \
            --dart-define=APNS_AUTH_KEY_URL="$APNS_AUTH_KEY_URL"
    else
        flutter build apk --debug --verbose \
            --dart-define=WEB_URL="$WEB_URL" \
            --dart-define=PUSH_NOTIFY="$PUSH_NOTIFY" \
            --dart-define=PKG_NAME="$PKG_NAME" \
            --dart-define=APP_NAME="$APP_NAME" \
            --dart-define=ORG_NAME="$ORG_NAME" \
            --dart-define=VERSION_NAME="$VERSION_NAME" \
            --dart-define=VERSION_CODE="$VERSION_CODE" \
            --dart-define=EMAIL_ID="$EMAIL_ID" \
            --dart-define=IS_SPLASH="$IS_SPLASH" \
            --dart-define=SPLASH="$SPLASH" \
            --dart-define=SPLASH_BG="$SPLASH_BG" \
            --dart-define=SPLASH_ANIMATION="$SPLASH_ANIMATION" \
            --dart-define=SPLASH_BG_COLOR="$SPLASH_BG_COLOR" \
            --dart-define=SPLASH_TAGLINE="$SPLASH_TAGLINE" \
            --dart-define=SPLASH_TAGLINE_COLOR="$SPLASH_TAGLINE_COLOR" \
            --dart-define=SPLASH_DURATION="$SPLASH_DURATION" \
            --dart-define=IS_PULLDOWN="$IS_PULLDOWN" \
            --dart-define=LOGO_URL="$LOGO_URL" \
            --dart-define=IS_BOTTOMMENU="$IS_BOTTOMMENU" \
            --dart-define=BOTTOMMENU_ITEMS="$BOTTOMMENU_ITEMS" \
            --dart-define=BOTTOMMENU_BG_COLOR="$BOTTOMMENU_BG_COLOR" \
            --dart-define=BOTTOMMENU_ICON_COLOR="$BOTTOMMENU_ICON_COLOR" \
            --dart-define=BOTTOMMENU_TEXT_COLOR="$BOTTOMMENU_TEXT_COLOR" \
            --dart-define=BOTTOMMENU_FONT="$BOTTOMMENU_FONT" \
            --dart-define=BOTTOMMENU_FONT_SIZE="$BOTTOMMENU_FONT_SIZE" \
            --dart-define=BOTTOMMENU_FONT_BOLD="$BOTTOMMENU_FONT_BOLD" \
            --dart-define=BOTTOMMENU_FONT_ITALIC="$BOTTOMMENU_FONT_ITALIC" \
            --dart-define=BOTTOMMENU_ACTIVE_TAB_COLOR="$BOTTOMMENU_ACTIVE_TAB_COLOR" \
            --dart-define=BOTTOMMENU_ICON_POSITION="$BOTTOMMENU_ICON_POSITION" \
            --dart-define=BOTTOMMENU_VISIBLE_ON="$BOTTOMMENU_VISIBLE_ON" \
            --dart-define=IS_DEEPLINK="$IS_DEEPLINK" \
            --dart-define=IS_LOAD_IND="$IS_LOAD_IND" \
            --dart-define=IS_CHATBOT="$IS_CHATBOT" \
            --dart-define=IS_CAMERA="$IS_CAMERA" \
            --dart-define=IS_LOCATION="$IS_LOCATION" \
            --dart-define=IS_BIOMETRIC="$IS_BIOMETRIC" \
            --dart-define=IS_MIC="$IS_MIC" \
            --dart-define=IS_CONTACT="$IS_CONTACT" \
            --dart-define=IS_CALENDAR="$IS_CALENDAR" \
            --dart-define=IS_NOTIFICATION="$IS_NOTIFICATION" \
            --dart-define=IS_STORAGE="$IS_STORAGE" \
            --dart-define=firebase_config_android="$firebase_config_android" \
            --dart-define=firebase_config_ios="$firebase_config_ios" \
            --dart-define=APNS_KEY_ID="$APNS_KEY_ID" \
            --dart-define=APPLE_TEAM_ID="$APPLE_TEAM_ID" \
            --dart-define=APNS_AUTH_KEY_URL="$APNS_AUTH_KEY_URL"
    fi
    
    # Check build result
    if [ $? -eq 0 ]; then
        echo "Build completed successfully"
        return 0
    else
        echo "Build failed"
        return 1
    fi
}

# Main build process
main() {
    echo "Starting Android build process..."
    
    # Phase 1: Project Setup & Core Configuration
    setup_build_environment || handle_build_error "Failed to setup build environment"
    download_splash_assets || handle_build_error "Failed to download splash assets"
    generate_launcher_icons || handle_build_error "Failed to generate launcher icons"
    
    # Phase 2: Conditional Integration
    setup_firebase || handle_build_error "Failed to setup Firebase"
    setup_keystore || handle_build_error "Failed to setup keystore"
    update_gradle_files || handle_build_error "Failed to update Gradle files"
    
    # Phase 3: Verification & Build
    verify_requirements || handle_build_error "Failed to verify requirements"
    build_android_app || handle_build_error "Failed to build Android app"
    
    # Success
    handle_build_success
}

# Run the main process
main
