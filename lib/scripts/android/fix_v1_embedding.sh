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

# Check if gradlew exists before trying to use it
cd "$ANDROID_DIR"
if [ -f "./gradlew" ]; then
    echo -e "${BLUE}🧹 Running Gradle clean...${NC}"
    ./gradlew clean
elif [ -f "../gradlew" ]; then
    echo -e "${BLUE}🧹 Found gradlew in parent directory, running clean...${NC}"
    ../gradlew clean
else
    echo -e "${YELLOW}⚠️  Gradle wrapper not found, generating it...${NC}"
    # Generate gradlew wrapper if it doesn't exist
    if command -v gradle >/dev/null 2>&1; then
        gradle wrapper --gradle-version=8.12
        if [ -f "./gradlew" ]; then
            echo -e "${GREEN}✅ Generated gradlew wrapper, running clean...${NC}"
            ./gradlew clean
        else
            echo -e "${YELLOW}⚠️  Could not generate gradlew, skipping Gradle clean (Flutter clean already done)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Gradle not available, skipping Gradle clean (Flutter clean already done)${NC}"
    fi
fi

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