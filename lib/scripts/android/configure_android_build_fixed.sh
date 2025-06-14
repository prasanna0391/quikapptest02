#!/usr/bin/env bash

set -euo pipefail
echo "🛠️ Configuring a complete and modern Android build..."

# --- START: SDK Version Configuration ---
export PKG_NAME="${PKG_NAME:-com.example.app}"
export COMPILE_SDK_VERSION="${COMPILE_SDK_VERSION:-35}"
export MIN_SDK_VERSION="${MIN_SDK_VERSION:-21}"
export TARGET_SDK_VERSION="${TARGET_SDK_VERSION:-35}"
# --- END: SDK Version Configuration ---

echo "Using PKG_NAME: $PKG_NAME"
echo "Using COMPILE_SDK_VERSION: $COMPILE_SDK_VERSION"

# Added debugging to verify file locations
echo "-------------------------------------------------"
echo "🔍 Listing contents of the /android/ directory to verify file locations..."
ls -laR android/
echo "-------------------------------------------------"

# --- Common Gradle Configuration ---
echo "✍️ Writing root Gradle files..."
cat <<EOF > android/settings.gradle.kts
pluginManagement {
    includeBuild("$FLUTTER_ROOT/packages/flutter_tools/gradle")
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.3.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}
include(":app")
EOF

cat <<'EOF' > android/build.gradle.kts
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
EOF

# --- Conditionally Generate app/build.gradle.kts with Correct Paths ---

if [ "${PUSH_NOTIFY:-false}" = "true" ]; then
  echo "✅ PUSH_NOTIFY is true. Generating build.gradle.kts WITH Firebase."
  cat <<EOF > android/app/build.gradle.kts
import java.util.Properties
import java.io.FileInputStream
import java.io.File

// Load local.properties for flutter.sdk path
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties") // This is correct, relative to project root
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { input ->
        localProperties.load(input)
    }
}
val flutterRoot = localProperties.getProperty("flutter.sdk")
if (flutterRoot == null) {
    throw GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
}

// Load key.properties for signing credentials
val keystoreProperties = Properties()
// CRITICAL FIX: Reference key.properties relative to the current module directory (android/app)
// If key.properties is in 'android/', then from 'android/app/', it's '../key.properties'
val keystorePropertiesFile = file("../key.properties") // Use 'file' without 'rootProject' for relative paths within module
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { input ->
        keystoreProperties.load(input)
    }
} else {
    println("WARNING: android/key.properties not found at \${keystorePropertiesFile.absolutePath}")
    println("This might be expected during initial setup, but ensure it exists for release builds.")
}

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = System.getenv("PKG_NAME") ?: "com.example.app"
    compileSdk = (System.getenv("COMPILE_SDK_VERSION") ?: "35").toInt()

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = System.getenv("PKG_NAME") ?: "com.example.app"
        minSdk = (System.getenv("MIN_SDK_VERSION") ?: "21").toInt()
        targetSdk = (System.getenv("TARGET_SDK_VERSION") ?: "35").toInt()
        versionCode = (System.getenv("VERSION_CODE") ?: "1").toInt()
        versionName = System.getenv("VERSION_NAME") ?: "1.0"
    }

    signingConfigs {
        create("release") {
            if (keystoreProperties.isNotEmpty()) {
                // CRITICAL FIX: Reference keystore.jks relative to the current module directory (android/app)
                // If keystore.jks is in 'android/', then from 'android/app/', it's '../keystore.jks'
                storeFile = file("../" + keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            } else {
                println("ERROR: Keystore properties not loaded. Ensure android/key.properties exists and is valid.")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
EOF
else
  # This block is for when PUSH_NOTIFY is false
  echo "🚫 PUSH_NOTIFY is false. Generating build.gradle.kts WITHOUT Firebase."
  cat <<EOF > android/app/build.gradle.kts
import java.util.Properties
import java.io.FileInputStream
import java.io.File

// Load local.properties for flutter.sdk path
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { input ->
        localProperties.load(input)
    }
}
val flutterRoot = localProperties.getProperty("flutter.sdk")
if (flutterRoot == null) {
    throw GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
}

// Load key.properties for signing credentials
val keystoreProperties = Properties()
// CRITICAL FIX: Reference key.properties relative to the current module directory (android/app)
// If key.properties is in 'android/', then from 'android/app/', it's '../key.properties'
val keystorePropertiesFile = file("../key.properties") // Use 'file' without 'rootProject' for relative paths within module
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { input ->
        keystoreProperties.load(input)
    }
} else {
    println("WARNING: android/key.properties not found at \${keystorePropertiesFile.absolutePath}")
    println("This might be expected during initial setup, but ensure it exists for release builds.")
}
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = System.getenv("PKG_NAME") ?: "com.example.app"
    compileSdk = (System.getenv("COMPILE_SDK_VERSION") ?: "35").toInt()

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = System.getenv("PKG_NAME") ?: "com.example.app"
        minSdk = (System.getenv("MIN_SDK_VERSION") ?: "21").toInt()
        targetSdk = (System.getenv("TARGET_SDK_VERSION") ?: "35").toInt()
        versionCode = (System.getenv("VERSION_CODE") ?: "1").toInt()
        versionName = System.getenv("VERSION_NAME") ?: "1.0"
    }

    signingConfigs {
        create("release") {
            if (keystoreProperties.isNotEmpty()) {
                // CRITICAL FIX: Reference keystore.jks relative to the current module directory (android/app)
                // If keystore.jks is in 'android/', then from 'android/app/', it's '../keystore.jks'
                storeFile = file("../" + keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            } else {
                println("ERROR: Keystore properties not loaded. Ensure android/key.properties exists and is valid.")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
EOF
fi

echo "✅ All Android Gradle files configured successfully."