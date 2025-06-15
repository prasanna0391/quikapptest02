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
    local build_type="$1"
    local build_paths="$2"
    local has_keystore="$3"
    local has_push="$4"
    
    echo "✅ Build completed successfully!"
    
    # Prepare build status message
    local build_status="App Build Status:\n"
    build_status+="- Build Type: Release\n"
    build_status+="- Push Notification: ${has_push:-No}\n"
    build_status+="- Keystore: ${has_keystore:-No}\n"
    if [ "$has_keystore" = "true" ]; then
        build_status+="- Output: APK, AAB\n"
    else
        build_status+="- Output: APK\n"
    fi
    
    # Send success notification
    if [ -n "$EMAIL_ID" ]; then
        echo "Sending success notification..."
        if [ -f "lib/scripts/android/email_config.sh" ]; then
            source "lib/scripts/android/email_config.sh"
            send_email_notification "success" "$build_status" "$build_paths"
        else
            echo "❌ Email configuration not found"
        fi
    fi
    
    echo "📦 Build artifacts:"
    echo "$build_paths" | while read -r path; do
        echo "   - $path"
    done
}

generate_build_gradle_kts() {
    local has_firebase=$1
    local has_keystore=$2
    local build_gradle_path="android/build.gradle.kts"
    
    echo "Generating build.gradle.kts configuration..."
    echo "Firebase: $has_firebase, Keystore: $has_keystore"
    
    # Create build.gradle.kts with appropriate configuration
    cat > "$build_gradle_path" << EOF
buildscript {
    val kotlinVersion = "1.8.10"
    
    repositories {
        google()
        mavenCentral()
    }
    
    dependencies {
        classpath("com.android.tools.build:gradle:7.3.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:\$kotlinVersion")
EOF

    # Add Firebase if enabled
    if [ "$has_firebase" = "true" ]; then
        cat >> "$build_gradle_path" << EOF
        classpath("com.google.gms:google-services:4.4.0")
EOF
    fi

    cat >> "$build_gradle_path" << EOF
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}
EOF

    # Create app-level build.gradle.kts
    local app_build_gradle_path="android/app/build.gradle.kts"
    cat > "$app_build_gradle_path" << EOF
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("kotlin-kapt")
    id("dev.flutter.flutter-gradle-plugin")
EOF

    # Add Firebase plugin if enabled
    if [ "$has_firebase" = "true" ]; then
        cat >> "$app_build_gradle_path" << EOF
    id("com.google.gms.google-services")
EOF
    fi

    cat >> "$app_build_gradle_path" << EOF
}

android {
    namespace = "$PKG_NAME"
    compileSdk = 34
    
    defaultConfig {
        applicationId = "$PKG_NAME"
        minSdk = 21
        targetSdk = 34
        versionCode = $VERSION_CODE
        versionName = "$VERSION_NAME"
    }
EOF

    # Add signing config if keystore is present
    if [ "$has_keystore" = "true" ]; then
        cat >> "$app_build_gradle_path" << EOF
    signingConfigs {
        create("release") {
            storeFile = file("keystore.jks")
            storePassword = System.getenv("KEY_STORE_PASSWORD")
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
        }
    }
    
    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("release")
        }
    }
EOF
    else
        cat >> "$app_build_gradle_path" << EOF
    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
EOF
    fi

    cat >> "$app_build_gradle_path" << EOF
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    
    kotlinOptions {
        jvmTarget = "1.8"
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.8.10")
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
EOF

    # Add Firebase dependencies if enabled
    if [ "$has_firebase" = "true" ]; then
        cat >> "$app_build_gradle_path" << EOF
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
EOF
    fi

    cat >> "$app_build_gradle_path" << EOF
}
EOF

    echo "Generated build.gradle.kts configuration"
    return 0
}

update_gradle_files() {
    echo "Updating Gradle files..."
    
    # Check for Firebase and keystore
    local has_firebase="false"
    local has_keystore="false"
    
    if [ "$PUSH_NOTIFY" = "true" ]; then
        has_firebase="true"
    fi
    
    if [ -n "$KEY_STORE" ]; then
        has_keystore="true"
    fi
    
    # Generate appropriate build.gradle.kts
    generate_build_gradle_kts "$has_firebase" "$has_keystore"
    
    # Update settings.gradle to use only one settings file
    if [ -f "android/settings.gradle" ] && [ -f "android/settings.gradle.kts" ]; then
        rm "android/settings.gradle"
    fi
    
    # Create settings.gradle if it doesn't exist
    local settings_gradle_path="android/settings.gradle"
    cat > "$settings_gradle_path" << EOF
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

// Flutter settings
def flutterProjectRoot = rootProject.projectDir.parentFile
def pluginsFile = new File(flutterProjectRoot, '.flutter-plugins')
if (pluginsFile.exists()) {
    def plugins = new Properties()
    pluginsFile.withInputStream { plugins.load(it) }
    
    plugins.each { name, path ->
        def pluginDirectory = new File(new File(flutterProjectRoot, path), 'android')
        if (pluginDirectory.exists()) {
            include ":\${name}"
            project(":\${name}").projectDir = pluginDirectory
        }
    }
}

// Include Flutter SDK
def flutterSdkPath = System.getenv('FLUTTER_ROOT') ?: System.getProperty('user.home') + '/flutter'
if (new File(flutterSdkPath).exists()) {
    include ':flutter'
    project(':flutter').projectDir = new File(flutterSdkPath)
}
EOF
    
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
    
    # Create android directory if it doesn't exist
    mkdir -p android
    
    # Check if gradlew exists
    if [ ! -f "android/gradlew" ]; then
        echo "Creating Gradle wrapper..."
        cd android
        gradle wrapper --gradle-version 8.2 --distribution-type all
        cd ..
    else
        echo "Updating Gradle wrapper..."
        cd android
        ./gradlew wrapper --gradle-version 8.2 --distribution-type all
        cd ..
    fi
    
    # Make gradlew executable
    if [ -f "android/gradlew" ]; then
        chmod +x android/gradlew
    else
        echo "❌ Failed to create/update Gradle wrapper"
        return 1
    fi
    
    # Update Gradle files
    update_gradle_files
    
    # Determine build type and keystore presence
    local has_keystore="false"
    if [ -n "$KEY_STORE" ]; then
        has_keystore="true"
    fi
    
    local has_push="false"
    if [ "$PUSH_NOTIFY" = "true" ]; then
        has_push="true"
    fi
    
    # Common Dart defines for all builds
    local dart_defines="--dart-define=APP_NAME=\"$APP_NAME\" \
        --dart-define=PACKAGE_NAME=\"$PACKAGE_NAME\" \
        --dart-define=VERSION_NAME=\"$VERSION_NAME\" \
        --dart-define=VERSION_CODE=\"$VERSION_CODE\" \
        --dart-define=IS_PULLDOWN=\"$IS_PULLDOWN\" \
        --dart-define=LOGO_URL=\"$LOGO_URL\" \
        --dart-define=IS_DEEPLINK=\"$IS_DEEPLINK\" \
        --dart-define=IS_LOAD_IND=\"$IS_LOAD_IND\" \
        --dart-define=IS_CALENDAR=\"$IS_CALENDAR\" \
        --dart-define=IS_NOTIFICATION=\"$IS_NOTIFICATION\" \
        --dart-define=IS_STORAGE=\"$IS_STORAGE\""
    
    # Build based on keystore presence
    if [ "$has_keystore" = "true" ]; then
        # Build both APK and AAB for release
        echo "Building release APK..."
        flutter build apk --release --verbose $dart_defines
        
        if [ $? -eq 0 ]; then
            echo "Building release AAB..."
            flutter build appbundle --release --verbose $dart_defines
            
            if [ $? -eq 0 ]; then
                local build_paths="build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/bundle/release/app-release.aab"
                handle_build_success "Release" "$build_paths" "$has_keystore" "$has_push"
                return 0
            fi
        fi
    else
        # Build only APK for release
        echo "Building release APK..."
        flutter build apk --release --verbose $dart_defines
        
        if [ $? -eq 0 ]; then
            handle_build_success "Release" "build/app/outputs/flutter-apk/app-release.apk" "$has_keystore" "$has_push"
            return 0
        fi
    fi
    
    handle_build_error "Build failed"
    return 1
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
