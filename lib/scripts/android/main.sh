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
        echo "✅ Admin variables loaded successfully"
    else
        echo "Error: admin_vars.sh not found"
        return 1
    fi
    
    # Set default values for required variables
    APP_NAME="${APP_NAME:-Garbcode App}"
    PACKAGE_NAME="${PACKAGE_NAME:-com.garbcode.app}"
    VERSION_NAME="${VERSION_NAME:-1.0.0}"
    VERSION_CODE="${VERSION_CODE:-1}"
    
    # Validate required variables
    if [ -z "${APP_NAME}" ] || [ -z "${PACKAGE_NAME}" ] || [ -z "${VERSION_NAME}" ] || [ -z "${VERSION_CODE}" ]; then
        echo "Error: Required variables not set"
        echo "APP_NAME: ${APP_NAME}"
        echo "PACKAGE_NAME: ${PACKAGE_NAME}"
        echo "VERSION_NAME: ${VERSION_NAME}"
        echo "VERSION_CODE: ${VERSION_CODE}"
        return 1
    fi
    
    # Set default paths if not provided
    ASSETS_DIR="${ASSETS_DIR:-assets}"
    ANDROID_MIPMAP_DIR="${ANDROID_MIPMAP_DIR:-android/app/src/main/res/mipmap}"
    ANDROID_DRAWABLE_DIR="${ANDROID_DRAWABLE_DIR:-android/app/src/main/res/drawable}"
    ANDROID_VALUES_DIR="${ANDROID_VALUES_DIR:-android/app/src/main/res/values}"
    
    # Create necessary directories
    mkdir -p "${ASSETS_DIR}"
    mkdir -p "${ANDROID_MIPMAP_DIR}"
    mkdir -p "${ANDROID_DRAWABLE_DIR}"
    mkdir -p "${ANDROID_VALUES_DIR}"
    
    echo "✅ Build environment setup completed"
    return 0
}

download_splash_assets() {
    echo "Downloading splash assets..."
    
    # Create assets directory if it doesn't exist
    mkdir -p "${ASSETS_DIR}"
    
    # Function to download and verify asset
    download_asset() {
        local url="$1"
        local output_path="$2"
        local asset_name="$3"
        
        if [ -n "${url}" ]; then
            echo "Downloading ${asset_name} from ${url}..."
            
            # Remove existing file if it exists
            if [ -f "${output_path}" ]; then
                echo "Removing existing ${asset_name}..."
                rm -f "${output_path}"
            fi
            
            # Download the asset
            if curl -L "${url}" -o "${output_path}" --fail --silent --show-error; then
                # Verify the downloaded file
                if [ -f "${output_path}" ] && [ -s "${output_path}" ]; then
                    echo "✅ ${asset_name} downloaded successfully"
                    return 0
                else
                    echo "❌ Failed to download ${asset_name}: File is empty or missing"
                    return 1
                fi
            else
                echo "❌ Failed to download ${asset_name} from ${url}"
                return 1
            fi
        else
            echo "⚠️ ${asset_name} URL not provided, skipping..."
            return 0
        fi
    }
    
    # Check and download logo
    if [ -n "${LOGO_URL:-}" ]; then
        download_asset "${LOGO_URL}" "${ASSETS_DIR}/logo.png" "Logo"
    else
        echo "⚠️ LOGO_URL not set in environment variables"
    fi
    
    # Check and download splash screen
    if [ -n "${SPLASH:-}" ]; then
        download_asset "${SPLASH}" "${ASSETS_DIR}/splash.png" "Splash Screen"
    else
        echo "⚠️ SPLASH not set in environment variables"
    fi
    
    # Check and download splash background (optional)
    if [ -n "${SPLASH_BG:-}" ]; then
        download_asset "${SPLASH_BG}" "${ASSETS_DIR}/splash_bg.png" "Splash Background"
    else
        echo "ℹ️ SPLASH_BG not set in environment variables (optional)"
    fi
    
    # Verify at least one asset was downloaded
    if [ ! -f "${ASSETS_DIR}/logo.png" ] && [ ! -f "${ASSETS_DIR}/splash.png" ]; then
        echo "❌ No required assets were downloaded"
    fi
    
    echo "✅ Asset download process completed"
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
        "${ANDROID_MIPMAP_DIR:-android/app/src/main/res/mipmap}-hdpi/ic_launcher.png"
        "${ANDROID_MIPMAP_DIR:-android/app/src/main/res/mipmap}-mdpi/ic_launcher.png"
        "${ANDROID_MIPMAP_DIR:-android/app/src/main/res/mipmap}-xhdpi/ic_launcher.png"
        "${ANDROID_MIPMAP_DIR:-android/app/src/main/res/mipmap}-xxhdpi/ic_launcher.png"
        "${ANDROID_MIPMAP_DIR:-android/app/src/main/res/mipmap}-xxxhdpi/ic_launcher.png"
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
    if [ "${PUSH_NOTIFY:-false}" != "true" ]; then
        echo "Firebase integration not required (PUSH_NOTIFY is false)"
        return 0
    fi
    
    # Check if Firebase config is provided
    if [ -z "${firebase_config_android:-}" ]; then
        echo "Error: Firebase configuration not provided"
        return 1
    fi
    
    # Remove any existing google-services.json
    rm -f "${ANDROID_FIREBASE_CONFIG_PATH:-android/app/google-services.json}"
    
    # Create Firebase config directory
    mkdir -p "$(dirname "${ANDROID_FIREBASE_CONFIG_PATH:-android/app/google-services.json}")"
    
    # Write Firebase config to file
    echo "${firebase_config_android}" > "${ANDROID_FIREBASE_CONFIG_PATH:-android/app/google-services.json}"
    
    # Copy to assets if needed
    cp "${ANDROID_FIREBASE_CONFIG_PATH:-android/app/google-services.json}" "${ASSETS_DIR:-assets}/google-services.json"
    
    # Verify Firebase config was created
    if [ ! -f "${ANDROID_FIREBASE_CONFIG_PATH:-android/app/google-services.json}" ]; then
        echo "Error: Failed to create Firebase configuration file"
        return 1
    fi
    
    echo "Firebase configuration setup completed successfully"
    return 0
}

setup_keystore() {
    echo "Setting up Android keystore..."
    
    # Check if keystore is required
    if [ -z "${KEY_STORE:-}" ]; then
        echo "Keystore not provided, using debug keystore"
        return 0
    fi
    
    # Create keystore directory
    mkdir -p "$(dirname "${ANDROID_KEYSTORE_PATH:-android/app/keystore.jks}")"
    
    # Remove any existing keystore
    rm -f "${ANDROID_KEYSTORE_PATH:-android/app/keystore.jks}"
    
    # Write keystore to file
    echo "${KEY_STORE}" > "${ANDROID_KEYSTORE_PATH:-android/app/keystore.jks}"
    
    # Verify keystore was created
    if [ ! -f "${ANDROID_KEYSTORE_PATH:-android/app/keystore.jks}" ]; then
        echo "Error: Failed to create keystore file"
        return 1
    fi
    
    # Create key.properties file
    cat > "${ANDROID_KEY_PROPERTIES_PATH:-android/key.properties}" << EOF
storeFile=keystore.jks
storePassword=${STORE_PASSWORD:-}
keyAlias=${KEY_ALIAS:-}
keyPassword=${KEY_PASSWORD:-}
EOF
    
    echo "Keystore setup completed successfully"
    return 0
}

# Email notification functions
handle_build_error() {
    local error_message="$1"
    echo "Build Error: $error_message"
    
    # Send error notification if email is configured
    if [ -n "${EMAIL_ID:-}" ]; then
        echo "Sending error notification to ${EMAIL_ID}"
        if [ -f "lib/scripts/android/email_config.sh" ]; then
            source "lib/scripts/android/email_config.sh"
            send_email_notification "error" "Build Failed" "$error_message"
        else
            echo "❌ Email configuration not found"
        fi
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
    if [ "${has_keystore:-false}" = "true" ]; then
        build_status+="- Output: APK, AAB\n"
    else
        build_status+="- Output: APK\n"
    fi
    
    # Send success notification
    if [ -n "${EMAIL_ID:-}" ]; then
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
    local has_firebase="$1"
    local has_keystore="$2"
    
    # Generate root build.gradle
    cat > "android/build.gradle" << EOF
buildscript {
    ext.kotlin_version = '1.9.20'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:8.2.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:\$kotlin_version"
        ${has_firebase:+classpath 'com.google.gms:google-services:4.4.0'}
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
subprojects {
    project.evaluationDependsOn(':app')
}

tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
EOF

    # Generate app/build.gradle
    cat > "android/app/build.gradle" << EOF
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

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '1'
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0'
}

apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply from: "\$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"
${has_firebase:+apply plugin: 'com.google.gms.google-services'}

android {
    namespace "${PACKAGE_NAME}"
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
        applicationId "${PACKAGE_NAME}"
        minSdkVersion flutter.minSdkVersion
        targetSdkVersion flutter.targetSdkVersion
        versionCode ${VERSION_CODE}
        versionName "${VERSION_NAME}"
    }

    ${has_keystore:+signingConfigs {
        release {
            keyAlias "${KEY_ALIAS}"
            keyPassword "${KEY_PASSWORD}"
            storeFile file("keystore.jks")
            storePassword "${STORE_PASSWORD}"
        }
    }}

    buildTypes {
        release {
            signingConfig ${has_keystore:+signingConfigs.release}
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
    ${has_firebase:+implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'com.google.firebase:firebase-messaging'}
}
EOF

    # Generate settings.gradle
    cat > "android/settings.gradle" << EOF
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

    # Create gradle.properties
    cat > "android/gradle.properties" << EOF
org.gradle.jvmargs=-Xmx1536M
android.useAndroidX=true
android.enableJetifier=true
EOF

    # Create gradle-wrapper.properties
    mkdir -p android/gradle/wrapper
    cat > "android/gradle/wrapper/gradle-wrapper.properties" << EOF
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.2-all.zip
EOF

    return 0
}

update_gradle_files() {
    echo "Updating Gradle files..."
    
    # Check for Firebase and keystore
    local has_firebase="false"
    local has_keystore="false"
    
    if [ "${PUSH_NOTIFY:-false}" = "true" ]; then
        has_firebase="true"
    fi
    
    if [ -n "${KEY_STORE:-}" ]; then
        has_keystore="true"
    fi
    
    # Generate appropriate build.gradle.kts
    generate_build_gradle_kts "$has_firebase" "$has_keystore"
    
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
    if [ -z "${ANDROID_HOME:-}" ]; then
        echo "Error: ANDROID_HOME not set"
        return 1
    fi
    
    # Check Firebase config if needed
    if [ "${PUSH_NOTIFY:-false}" = "true" ] && [ ! -f "${ANDROID_FIREBASE_CONFIG_PATH:-android/app/google-services.json}" ]; then
        echo "Error: Firebase config not found"
        return 1
    fi
    
    # Check keystore if provided
    if [ -n "${KEY_STORE:-}" ] && [ ! -f "${ANDROID_KEYSTORE_PATH:-android/app/keystore.jks}" ]; then
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
    
    # Update Gradle files
    update_gradle_files
    
    # Create Gradle wrapper with specific version
    echo "Creating Gradle wrapper..."
    cd android
    
    # Remove existing wrapper if it exists
    rm -f gradlew
    rm -f gradlew.bat
    rm -rf gradle/wrapper
    
    # Create wrapper directory
    mkdir -p gradle/wrapper
    
    # Create gradle-wrapper.properties
    cat > gradle/wrapper/gradle-wrapper.properties << EOF
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.2-all.zip
EOF
    
    # Download Gradle wrapper
    curl -o gradle/wrapper/gradle-wrapper.jar https://raw.githubusercontent.com/gradle/gradle/v8.2.0/gradle/wrapper/gradle-wrapper.jar
    
    # Create gradlew script
    cat > gradlew << EOF
#!/usr/bin/env sh

#
# Copyright 2015 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

##############################################################################
##
##  Gradle start up script for UN*X
##
##############################################################################

# Attempt to set APP_HOME
# Resolve links: \$0 may be a link
PRG="\$0"
# Need this for relative symlinks.
while [ -h "\$PRG" ] ; do
    ls=\`ls -ld "\$PRG"\`
    link=\`expr "\$ls" : '.*-> \\(.*\\)\$'\`
    if expr "\$link" : '/.*' > /dev/null; then
        PRG="\$link"
    else
        PRG=\`dirname "\$PRG"\`"/\$link"
    fi
done
SAVED="\`pwd\`"
cd "\`dirname "\$PRG"\`/" >/dev/null
APP_HOME="\`pwd -P\`"
cd "\$SAVED" >/dev/null

APP_NAME="Gradle"
APP_BASE_NAME=\`basename "\$0"\`

# Add default JVM options here. You can also use JAVA_OPTS and GRADLE_OPTS to pass JVM options to this script.
DEFAULT_JVM_OPTS='"-Xmx64m" "-Xms64m"'

# Use the maximum available, or set MAX_FD != -1 to use that value.
MAX_FD="maximum"

warn () {
    echo "\$*"
}

die () {
    echo
    echo "\$*"
    echo
    exit 1
}

# OS specific support (must be 'true' or 'false').
cygwin=false
msys=false
darwin=false
nonstop=false
case "\`uname\`" in
  CYGWIN* )
    cygwin=true
    ;;
  Darwin* )
    darwin=true
    ;;
  MINGW* )
    msys=true
    ;;
  NONSTOP* )
    nonstop=true
    ;;
esac

CLASSPATH=\$APP_HOME/gradle/wrapper/gradle-wrapper.jar

# Determine the Java command to use to start the JVM.
if [ -n "\$JAVA_HOME" ] ; then
    if [ -x "\$JAVA_HOME/jre/sh/java" ] ; then
        # IBM's JDK on AIX uses strange locations for the executables
        JAVACMD="\$JAVA_HOME/jre/sh/java"
    else
        JAVACMD="\$JAVA_HOME/bin/java"
    fi
    if [ ! -x "\$JAVACMD" ] ; then
        die "ERROR: JAVA_HOME is set to an invalid directory: \$JAVA_HOME

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
    fi
else
    JAVACMD="java"
    which java >/dev/null 2>&1 || die "ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
fi

# Increase the maximum file descriptors if we can.
if [ "\$cygwin" = "false" -a "\$darwin" = "false" -a "\$nonstop" = "false" ] ; then
    MAX_FD_LIMIT=\`ulimit -H -n\`
    if [ \$? -eq 0 ] ; then
        if [ "\$MAX_FD" = "maximum" -o "\$MAX_FD" = "max" ] ; then
            MAX_FD="\$MAX_FD_LIMIT"
        fi
        ulimit -n \$MAX_FD
        if [ \$? -ne 0 ] ; then
            warn "Could not set maximum file descriptor limit: \$MAX_FD"
        fi
    else
        warn "Could not query maximum file descriptor limit: \$MAX_FD_LIMIT"
    fi
fi

# For Darwin, add options to specify how the application appears in the dock
if \$darwin; then
    GRADLE_OPTS="\$GRADLE_OPTS \"-Xdock:name=\$APP_NAME\" \"-Xdock:icon=\$APP_HOME/media/gradle.icns\""
fi

# For Cygwin or MSYS, switch paths to Windows format before running java
if [ "\$cygwin" = "true" -o "\$msys" = "true" ] ; then
    APP_HOME=\`cygpath --path --mixed "\$APP_HOME"\`
    CLASSPATH=\`cygpath --path --mixed "\$CLASSPATH"\`
    JAVACMD=\`cygpath --unix "\$JAVACMD"\`

    # We build the pattern for arguments to be converted via cygpath
    ROOTDIRSRAW=\`find -L / -maxdepth 1 -mindepth 1 -type d 2>/dev/null\`
    SEP=""
    for dir in \$ROOTDIRSRAW ; do
        ROOTDIRS="\$ROOTDIRS\$SEP\$dir"
        SEP="|"
    done
    OURCYGPATTERN="(^(\$ROOTDIRS))"
    # Add a user-defined pattern to the cygpath arguments
    if [ "\$GRADLE_CYGPATTERN" != "" ] ; then
        OURCYGPATTERN="\$OURCYGPATTERN|(\$GRADLE_CYGPATTERN)"
    fi
    # Now convert the arguments - kludge to limit ourselves to /bin/sh
    i=0
    for arg in "\$@" ; do
        CHECK=\`echo "\$arg"|egrep -c "\$OURCYGPATTERN" -\`
        CHECK2=\`echo "\$arg"|egrep -c "^-"\`                                 ### Determine if an option

        if [ \$CHECK -ne 0 ] && [ \$CHECK2 -eq 0 ] ; then                    ### Added a condition
            eval \`echo args\$i\`=\`cygpath --path --ignore --mixed "\$arg"\`
        else
            eval \`echo args\$i\`="\"\$arg\""
        fi
        i=\`expr \$i + 1\`
    done
    case \$i in
        0) set -- ;;
        1) set -- "\$args0" ;;
        2) set -- "\$args0" "\$args1" ;;
        3) set -- "\$args0" "\$args1" "\$args2" ;;
        4) set -- "\$args0" "\$args1" "\$args2" "\$args3" ;;
        5) set -- "\$args0" "\$args1" "\$args2" "\$args3" "\$args4" ;;
        6) set -- "\$args0" "\$args1" "\$args2" "\$args3" "\$args4" "\$args5" ;;
        7) set -- "\$args0" "\$args1" "\$args2" "\$args3" "\$args4" "\$args5" "\$args6" ;;
        8) set -- "\$args0" "\$args1" "\$args2" "\$args3" "\$args4" "\$args5" "\$args6" "\$args7" ;;
        9) set -- "\$args0" "\$args1" "\$args2" "\$args3" "\$args4" "\$args5" "\$args6" "\$args7" "\$args8" ;;
    esac
fi

# Escape application args
save () {
    for i do printf %s\\n "\$i" | sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/' \\\\/" ; done
    echo " "
}
APP_ARGS=\`save "\$@"\`

# Collect all arguments for the java command, following the shell quoting and substitution rules
eval set -- \$DEFAULT_JVM_OPTS \$JAVA_OPTS \$GRADLE_OPTS "\"-Dorg.gradle.appname=\$APP_BASE_NAME\"" -classpath "\$CLASSPATH" org.gradle.wrapper.GradleWrapperMain "\$APP_ARGS"

exec "\$JAVACMD" "\$@"
EOF
    
    # Make gradlew executable
    chmod +x gradlew
    
    # Verify wrapper creation
    if [ ! -f "gradlew" ] || [ ! -f "gradle/wrapper/gradle-wrapper.jar" ]; then
        echo "❌ Failed to create Gradle wrapper"
        cd ..
        return 1
    fi
    
    cd ..
    
    # Determine build type and keystore presence
    local has_keystore="false"
    if [ -n "${KEY_STORE:-}" ]; then
        has_keystore="true"
    fi
    
    local has_push="false"
    if [ "${PUSH_NOTIFY:-false}" = "true" ]; then
        has_push="true"
    fi
    
    # Common Dart defines for all builds
    local dart_defines="--dart-define=APP_NAME=\"${APP_NAME}\" \
        --dart-define=PACKAGE_NAME=\"${PACKAGE_NAME}\" \
        --dart-define=VERSION_NAME=\"${VERSION_NAME}\" \
        --dart-define=VERSION_CODE=\"${VERSION_CODE}\" \
        --dart-define=IS_PULLDOWN=\"${IS_PULLDOWN:-false}\" \
        --dart-define=LOGO_URL=\"${LOGO_URL:-}\" \
        --dart-define=IS_DEEPLINK=\"${IS_DEEPLINK:-false}\" \
        --dart-define=IS_LOAD_IND=\"${IS_LOAD_IND:-false}\" \
        --dart-define=IS_CALENDAR=\"${IS_CALENDAR:-false}\" \
        --dart-define=IS_NOTIFICATION=\"${IS_NOTIFICATION:-false}\" \
        --dart-define=IS_STORAGE=\"${IS_STORAGE:-false}\""
    
    # Build based on keystore presence
    if [ "${has_keystore}" = "true" ]; then
        # Build both APK and AAB for release
        echo "Building release APK..."
        flutter build apk --release --verbose --target lib/main.dart $dart_defines
        
        if [ $? -eq 0 ]; then
            echo "Building release AAB..."
            flutter build appbundle --release --verbose --target lib/main.dart $dart_defines
            
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
        flutter build apk --release --verbose --target lib/main.dart $dart_defines
        
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
}

# Run the main process
main
