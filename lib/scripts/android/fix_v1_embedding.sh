#!/bin/bash

# Fix V1 Embedding Issues Script
# This script automatically detects and fixes any Android v1 embedding issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ANDROID_DIR="$PROJECT_ROOT/android"
APP_DIR="$ANDROID_DIR/app"

echo -e "${BLUE}🔧 Fixing Android V1 Embedding Issues${NC}"
echo "=================================="

# Create local.properties file
create_local_properties() {
    echo -e "${YELLOW}📝 Creating local.properties file...${NC}"
    cd "$PROJECT_ROOT/android"
    
    # Try to find Flutter SDK path
    FLUTTER_SDK_PATH=""
    
    # Method 1: Check FLUTTER_ROOT environment variable
    if [ -n "$FLUTTER_ROOT" ] && [ -d "$FLUTTER_ROOT" ]; then
        FLUTTER_SDK_PATH="$FLUTTER_ROOT"
        echo -e "${GREEN}✅ Found Flutter SDK via FLUTTER_ROOT: $FLUTTER_SDK_PATH${NC}"
    else
        # Method 2: Find Flutter in PATH
        FLUTTER_BIN=$(which flutter 2>/dev/null || echo "")
        if [ -n "$FLUTTER_BIN" ]; then
            # Get the directory containing the flutter binary
            FLUTTER_BIN_DIR=$(dirname "$FLUTTER_BIN")
            # Get the parent directory (should be Flutter SDK root)
            FLUTTER_SDK_PATH=$(dirname "$FLUTTER_BIN_DIR")
            echo -e "${GREEN}✅ Found Flutter SDK via PATH: $FLUTTER_SDK_PATH${NC}"
        else
            # Method 3: Common Flutter installation locations
            COMMON_PATHS=(
                "/Users/builder/programs/flutter"
                "/usr/local/flutter"
                "/opt/flutter"
                "$HOME/flutter"
            )
            
            for path in "${COMMON_PATHS[@]}"; do
                if [ -d "$path" ]; then
                    FLUTTER_SDK_PATH="$path"
                    echo -e "${GREEN}✅ Found Flutter SDK in common location: $FLUTTER_SDK_PATH${NC}"
                    break
                fi
            done
        fi
    fi
    
    if [ -z "$FLUTTER_SDK_PATH" ]; then
        echo -e "${RED}❌ Could not find Flutter SDK path${NC}"
        exit 1
    fi
    
    # Create local.properties file
    cat > local.properties << EOF
flutter.sdk=$FLUTTER_SDK_PATH
EOF
    
    echo -e "${GREEN}✅ Created local.properties with Flutter SDK path${NC}"
    cd "$PROJECT_ROOT"
}

# Initialize Gradle wrapper if not present
initialize_gradle_wrapper() {
    echo -e "${YELLOW}📦 Initializing Gradle wrapper...${NC}"
    cd "$PROJECT_ROOT/android"
    
    # Create gradle/wrapper directory if it doesn't exist
    mkdir -p gradle/wrapper
    
    # Download gradle-wrapper.jar if not present
    if [ ! -f "gradle/wrapper/gradle-wrapper.jar" ]; then
        echo -e "${YELLOW}📥 Downloading gradle-wrapper.jar...${NC}"
        curl -L -o gradle/wrapper/gradle-wrapper.jar \
            "https://github.com/gradle/gradle/raw/v8.12.0/gradle/wrapper/gradle-wrapper.jar"
    fi
    
    # Create gradle-wrapper.properties if not present
    if [ ! -f "gradle/wrapper/gradle-wrapper.properties" ]; then
        echo -e "${YELLOW}📝 Creating gradle-wrapper.properties...${NC}"
        cat > gradle/wrapper/gradle-wrapper.properties << EOF
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.12-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF
    fi
    
    # Create gradlew script if not present
    if [ ! -f "gradlew" ]; then
        echo -e "${YELLOW}📝 Creating gradlew script...${NC}"
        cat > gradlew << 'EOF'
#!/bin/sh
# Gradle start up script for UN*X

# Attempt to set APP_HOME
PRG="$0"
while [ -h "$PRG" ] ; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '/.*' > /dev/null; then
        PRG="$link"
    else
        PRG=`dirname "$PRG"`"/$link"
    fi
done
SAVED="`pwd`"
cd "`dirname \"$PRG\"`/" >/dev/null
APP_HOME="`pwd -P`"
cd "$SAVED" >/dev/null

APP_NAME="Gradle"
APP_BASE_NAME=`basename "$0"`
DEFAULT_JVM_OPTS="-Xmx64m -Xms64m"
MAX_FD="maximum"

warn () {
    echo "$*"
}

die () {
    echo
    echo "$*"
    echo
    exit 1
}

# OS specific support
cygwin=false
msys=false
darwin=false
nonstop=false
case "`uname`" in
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

CLASSPATH=$APP_HOME/gradle/wrapper/gradle-wrapper.jar

# Determine the Java command to use
if [ -n "$JAVA_HOME" ] ; then
    if [ -x "$JAVA_HOME/jre/sh/java" ] ; then
        JAVACMD="$JAVA_HOME/jre/sh/java"
    else
        JAVACMD="$JAVA_HOME/bin/java"
    fi
    if [ ! -x "$JAVACMD" ] ; then
        die "ERROR: JAVA_HOME is set to an invalid directory: $JAVA_HOME"
    fi
else
    JAVACMD="java"
    which java >/dev/null 2>&1 || die "ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH."
fi

# Increase the maximum file descriptors if we can
if [ "$cygwin" = "false" -a "$darwin" = "false" -a "$nonstop" = "false" ] ; then
    MAX_FD_LIMIT=`ulimit -H -n`
    if [ $? -eq 0 ] ; then
        if [ "$MAX_FD" = "maximum" -o "$MAX_FD" = "max" ] ; then
            MAX_FD="$MAX_FD_LIMIT"
        fi
        ulimit -n $MAX_FD
        if [ $? -ne 0 ] ; then
            warn "Could not set maximum file descriptor limit: $MAX_FD"
        fi
    else
        warn "Could not query maximum file descriptor limit: $MAX_FD_LIMIT"
    fi
fi

# For Darwin, add dock options
if [ "$darwin" = "true" ]; then
    GRADLE_OPTS="$GRADLE_OPTS -Xdock:name=$APP_NAME -Xdock:icon=$APP_HOME/media/gradle.icns"
fi

# For Cygwin or MSYS, switch paths to Windows format
if [ "$cygwin" = "true" -o "$msys" = "true" ] ; then
    APP_HOME=`cygpath --path --mixed "$APP_HOME"`
    CLASSPATH=`cygpath --path --mixed "$CLASSPATH"`
    JAVACMD=`cygpath --unix "$JAVACMD"`
fi

# Split up the JVM_OPTS And GRADLE_OPTS values into an array, following the shell quoting and substitution rules
function splitJvmOpts() {
    JVM_OPTS=("$@")
}
eval splitJvmOpts $DEFAULT_JVM_OPTS $JAVA_OPTS $GRADLE_OPTS
JVM_OPTS[${#JVM_OPTS[*]}]="-Dorg.gradle.appname=$APP_BASE_NAME"

# Execute Gradle
exec "$JAVACMD" "${JVM_OPTS[@]}" -classpath "$CLASSPATH" org.gradle.wrapper.GradleWrapperMain "$@"
EOF
        chmod +x gradlew
    fi
    
    # Verify Gradle wrapper setup
    if [ -f "gradlew" ] && [ -f "gradle/wrapper/gradle-wrapper.jar" ] && [ -f "gradle/wrapper/gradle-wrapper.properties" ]; then
        echo -e "${GREEN}✅ Gradle wrapper initialized successfully${NC}"
    else
        echo -e "${RED}❌ Failed to initialize Gradle wrapper${NC}"
        exit 1
    fi
    
    cd "$PROJECT_ROOT"
}

# Create local.properties before initializing Gradle wrapper
create_local_properties

# Initialize Gradle wrapper before proceeding
initialize_gradle_wrapper

# Function to check if a file exists
check_file() {
    if [ ! -f "$1" ]; then
        echo -e "${RED}❌ File not found: $1${NC}"
        return 1
    fi
    return 0
}

# Function to backup a file
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "$file.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${YELLOW}📦 Backed up: $file${NC}"
    fi
}

# 1. Fix MainApplication.kt
echo -e "${BLUE}1. Checking MainApplication.kt...${NC}"
MAIN_APP_FILE="$APP_DIR/src/main/kotlin/com/garbcode/garbcodeapp/MainApplication.kt"

if check_file "$MAIN_APP_FILE"; then
    backup_file "$MAIN_APP_FILE"
    
    # Check if it's using v1 embedding
    if grep -q "io.flutter.app.FlutterApplication" "$MAIN_APP_FILE"; then
        echo -e "${YELLOW}⚠️  Found v1 embedding in MainApplication.kt, fixing...${NC}"
        
        # Create v2 embedding MainApplication.kt
        cat > "$MAIN_APP_FILE" << 'EOF'
package com.garbcode.garbcodeapp

import android.app.Application

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
    }
}
EOF
        echo -e "${GREEN}✅ Fixed MainApplication.kt to use v2 embedding${NC}"
    else
        echo -e "${GREEN}✅ MainApplication.kt is already using v2 embedding${NC}"
    fi
else
    echo -e "${RED}❌ MainApplication.kt not found, creating it...${NC}"
    
    # Create the directory structure if it doesn't exist
    mkdir -p "$(dirname "$MAIN_APP_FILE")"
    
    # Create v2 embedding MainApplication.kt
    cat > "$MAIN_APP_FILE" << 'EOF'
package com.garbcode.garbcodeapp

import android.app.Application

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
    }
}
EOF
    echo -e "${GREEN}✅ Created MainApplication.kt with v2 embedding${NC}"
fi

# 2. Fix MainActivity.kt
echo -e "${BLUE}2. Checking MainActivity.kt...${NC}"
MAIN_ACTIVITY_FILE="$APP_DIR/src/main/kotlin/com/garbcode/garbcodeapp/MainActivity.kt"

if check_file "$MAIN_ACTIVITY_FILE"; then
    backup_file "$MAIN_ACTIVITY_FILE"
    
    # Check if it's using v1 embedding
    if grep -q "io.flutter.app.FlutterActivity" "$MAIN_ACTIVITY_FILE"; then
        echo -e "${YELLOW}⚠️  Found v1 embedding in MainActivity.kt, fixing...${NC}"
        
        # Create v2 embedding MainActivity.kt
        cat > "$MAIN_ACTIVITY_FILE" << 'EOF'
package com.garbcode.garbcodeapp

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
}
EOF
        echo -e "${GREEN}✅ Fixed MainActivity.kt to use v2 embedding${NC}"
    else
        echo -e "${GREEN}✅ MainActivity.kt is already using v2 embedding${NC}"
    fi
else
    echo -e "${RED}❌ MainActivity.kt not found, creating it...${NC}"
    
    # Create the directory structure if it doesn't exist
    mkdir -p "$(dirname "$MAIN_ACTIVITY_FILE")"
    
    # Create v2 embedding MainActivity.kt
    cat > "$MAIN_ACTIVITY_FILE" << 'EOF'
package com.garbcode.garbcodeapp

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
}
EOF
    echo -e "${GREEN}✅ Created MainActivity.kt with v2 embedding${NC}"
fi

# 3. Fix AndroidManifest.xml
echo -e "${BLUE}3. Checking AndroidManifest.xml...${NC}"
MANIFEST_FILE="$APP_DIR/src/main/AndroidManifest.xml"

if check_file "$MANIFEST_FILE"; then
    backup_file "$MANIFEST_FILE"
    
    # Check if it has v2 embedding metadata
    if ! grep -q "flutterEmbedding" "$MANIFEST_FILE"; then
        echo -e "${YELLOW}⚠️  Missing v2 embedding metadata in AndroidManifest.xml, fixing...${NC}"
        
        # Add v2 embedding metadata before the closing </application> tag
        sed -i '' '/<\/application>/i\
        <!-- Flutter V2 Embedding Metadata -->\
        <meta-data\
            android:name="flutterEmbedding"\
            android:value="2" />\
' "$MANIFEST_FILE"
        
        echo -e "${GREEN}✅ Added v2 embedding metadata to AndroidManifest.xml${NC}"
    else
        echo -e "${GREEN}✅ AndroidManifest.xml already has v2 embedding metadata${NC}"
    fi
    
    # Check if it has NormalTheme metadata
    if ! grep -q "io.flutter.embedding.android.NormalTheme" "$MANIFEST_FILE"; then
        echo -e "${YELLOW}⚠️  Missing NormalTheme metadata in AndroidManifest.xml, fixing...${NC}"
        
        # Add NormalTheme metadata before the intent-filter
        sed -i '' '/<intent-filter>/i\
            <meta-data\
                android:name="io.flutter.embedding.android.NormalTheme"\
                android:resource="@style/NormalTheme" />\
' "$MANIFEST_FILE"
        
        echo -e "${GREEN}✅ Added NormalTheme metadata to AndroidManifest.xml${NC}"
    else
        echo -e "${GREEN}✅ AndroidManifest.xml already has NormalTheme metadata${NC}"
    fi
else
    echo -e "${RED}❌ AndroidManifest.xml not found!${NC}"
    exit 1
fi

# 3.5. Fix AndroidManifest_template.xml
echo -e "${BLUE}3.5. Checking AndroidManifest_template.xml...${NC}"
TEMPLATE_FILE="$APP_DIR/src/main/AndroidManifest_template.xml"

if check_file "$TEMPLATE_FILE"; then
    backup_file "$TEMPLATE_FILE"
    
    # Check if it has v2 embedding metadata
    if ! grep -q "flutterEmbedding" "$TEMPLATE_FILE"; then
        echo -e "${YELLOW}⚠️  Missing v2 embedding metadata in AndroidManifest_template.xml, fixing...${NC}"
        
        # Add v2 embedding metadata before the closing </application> tag
        sed -i '' '/<\/application>/i\
        <!-- Flutter V2 Embedding Metadata -->\
        <meta-data\
            android:name="flutterEmbedding"\
            android:value="2" />\
' "$TEMPLATE_FILE"
        
        echo -e "${GREEN}✅ Added v2 embedding metadata to AndroidManifest_template.xml${NC}"
    else
        echo -e "${GREEN}✅ AndroidManifest_template.xml already has v2 embedding metadata${NC}"
    fi
    
    # Check if it has NormalTheme metadata
    if ! grep -q "io.flutter.embedding.android.NormalTheme" "$TEMPLATE_FILE"; then
        echo -e "${YELLOW}⚠️  Missing NormalTheme metadata in AndroidManifest_template.xml, fixing...${NC}"
        
        # Add NormalTheme metadata before the intent-filter
        sed -i '' '/<intent-filter>/i\
            <meta-data\
                android:name="io.flutter.embedding.android.NormalTheme"\
                android:resource="@style/NormalTheme" />\
' "$TEMPLATE_FILE"
        
        echo -e "${GREEN}✅ Added NormalTheme metadata to AndroidManifest_template.xml${NC}"
    else
        echo -e "${GREEN}✅ AndroidManifest_template.xml already has NormalTheme metadata${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  AndroidManifest_template.xml not found - this is optional${NC}"
fi

# 4. Check for any remaining v1 embedding references
echo -e "${BLUE}4. Scanning for any remaining v1 embedding references...${NC}"
V1_REFERENCES=$(find "$ANDROID_DIR" -name "*.kt" -o -name "*.java" -o -name "*.xml" | xargs grep -l "io.flutter.app" 2>/dev/null || true)

if [ -n "$V1_REFERENCES" ]; then
    echo -e "${YELLOW}⚠️  Found remaining v1 embedding references:${NC}"
    echo "$V1_REFERENCES"
    echo -e "${YELLOW}💡 These files may need manual review${NC}"
else
    echo -e "${GREEN}✅ No remaining v1 embedding references found${NC}"
fi

# 5. Clean build cache
echo -e "${BLUE}5. Cleaning build cache...${NC}"
cd "$PROJECT_ROOT"
flutter clean
cd "$ANDROID_DIR"
./gradlew clean
cd "$PROJECT_ROOT"

echo ""
echo -e "${GREEN}🎉 V1 Embedding Fix Complete!${NC}"
echo "=================================="
echo -e "${GREEN}✅ All Android files have been updated to use v2 embedding${NC}"
echo -e "${GREEN}✅ Build cache has been cleaned${NC}"
echo ""
echo -e "${BLUE}📝 Next steps:${NC}"
echo "1. Run your build script again"
echo "2. If issues persist, check the generated files in android/app/build/"
echo "3. Consider updating any outdated plugins with: flutter pub upgrade"
echo ""
echo -e "${YELLOW}💡 Tip: Run this script before each build to ensure v2 embedding is properly configured${NC}" 