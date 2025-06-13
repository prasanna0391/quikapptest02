#!/usr/bin/env bash

set -euo pipefail

echo "--- Injecting Android Manifest Permissions ---"

TEMPLATE_FILE="android/app/src/main/AndroidManifest_template.xml"
OUTPUT_FILE="android/app/src/main/AndroidManifest.xml"
TEMP_PERMISSIONS_FILE="android/temp_permissions_content.tmp"

# Ensure the template exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "❌ Error: AndroidManifest_template.xml not found at $TEMPLATE_FILE"
    echo "Please ensure the template file exists and its path is correct."
    exit 1
fi

PERMISSIONS_RAW_LINES=""

# --- Collect Permissions Based on Environment Variables ---
if [ "${IS_CAMERA:-false}" = "true" ]; then
    PERMISSIONS_RAW_LINES+="    <uses-permission android:name=\"android.permission.CAMERA\" />\n"
fi
if [ "${IS_LOCATION:-false}" = "true" ]; then
    PERMISSIONS_RAW_LINES+="    <uses-permission android:name=\"android.permission.ACCESS_FINE_LOCATION\" />\n"
    PERMISSIONS_RAW_LINES+="    <uses-permission android:name=\"android.permission.ACCESS_COARSE_LOCATION\" />\n"
fi
if [ "${IS_BIOMETRIC:-false}" = "true" ]; then
    PERMISSIONS_RAW_LINES+="    <uses-permission android:name=\"android.permission.USE_BIOMETRIC\" />\n"
fi
if [ "${IS_MIC:-false}" = "true" ]; then
    PERMISSIONS_RAW_LINES+="    <uses-permission android:name=\"android.permission.RECORD_AUDIO\" />\n"
fi
if [ "${IS_CONTACT:-false}" = "true" ]; then
    PERMISSIONS_RAW_LINES+="    <uses-permission android:name=\"android.permission.READ_CONTACTS\" />\n"
    PERMISSIONS_RAW_LINES+="    <uses-permission android:name=\"android.permission.WRITE_CONTACTS\" />\n"
fi
if [ "${IS_CALENDAR:-false}" = "true" ]; then
    PERMISSIONS_RAW_LINES+="    <uses-permission android:name=\"android.permission.READ_CALENDAR\" />\n"
    PERMISSIONS_RAW_LINES+="    <uses-permission android:name=\"android.permission.WRITE_CALENDAR\" />\n"
fi
if [ "${IS_NOTIFICATION:-false}" = "true" ]; then
    PERMISSIONS_RAW_LINES+="    <uses-permission android:name=\"android.permission.POST_NOTIFICATIONS\" />\n"
fi
if [ "${IS_STORAGE:-false}" = "true" ]; then
    PERMISSIONS_RAW_LINES+="    <uses-permission android:name=\"android.permission.READ_EXTERNAL_STORAGE\" android:maxSdkVersion=\"32\" />\n"
    PERMISSIONS_RAW_LINES+="    <uses-permission android:name=\"android.permission.WRITE_EXTERNAL_STORAGE\" android:maxSdkVersion=\"29\" />\n"
fi

# --- Patch template to ensure V2 embedding ---
echo "🔧 Ensuring AndroidManifest_template.xml uses V2 embedding..."
sed -i '' 's@android:name=\"io.flutter.app.FlutterActivity\"@android:name=\".MainActivity\"@' "$TEMPLATE_FILE" || true
sed -i '' 's@android:name=\".*MainActivity\"@android:name=\".MainActivity\"@' "$TEMPLATE_FILE" || true

# Write the collected permissions to a temporary file
printf %s "$PERMISSIONS_RAW_LINES" > "$TEMP_PERMISSIONS_FILE"

# Inject permissions into the template
awk '
/<!--PERMISSIONS-->/{
    system("cat " insert_file);
    found_placeholder = 1;
    next;
}
{
    print $0;
}
END {
    if (found_placeholder == 0) {
        print "ERROR: Placeholder not found in template!" > "/dev/stderr";
        exit 1;
    }
}' insert_file="$TEMP_PERMISSIONS_FILE" "$TEMPLATE_FILE" > "$OUTPUT_FILE"

# Clean up temporary file
rm "$TEMP_PERMISSIONS_FILE"

# --- Update app label ---
APP_LABEL_FINAL="${APP_NAME:-My Flutter App}"
ESCAPED_APP_LABEL=$(echo "$APP_LABEL_FINAL" | sed 's/[\/&]/\\&/g')
sed -i '' "s@android:label=\"[^\"]*\"@android:label=\"${ESCAPED_APP_LABEL}\"@g" "$OUTPUT_FILE"

# --- Verify V2 embedding metadata is present ---
echo "🔍 Verifying V2 embedding metadata..."
if ! grep -q "flutterEmbedding" "$OUTPUT_FILE"; then
    echo "⚠️  V2 embedding metadata missing, adding it..."
    sed -i '' '/<\/application>/i\
        <!-- Flutter V2 Embedding Metadata -->\
        <meta-data\
            android:name="flutterEmbedding"\
            android:value="2" />\
' "$OUTPUT_FILE"
fi

if ! grep -q "io.flutter.embedding.android.NormalTheme" "$OUTPUT_FILE"; then
    echo "⚠️  NormalTheme metadata missing, adding it..."
    sed -i '' '/<intent-filter>/i\
            <meta-data\
                android:name="io.flutter.embedding.android.NormalTheme"\
                android:resource="@style/NormalTheme" />\
' "$OUTPUT_FILE"
fi

# --- Verify icon resources exist ---
echo "🔍 Verifying icon resources..."
if grep -q "android:roundIcon=\"@mipmap/ic_launcher_round\"" "$OUTPUT_FILE"; then
    echo "⚠️  ic_launcher_round not found, using ic_launcher instead..."
    sed -i '' 's@android:roundIcon="@mipmap/ic_launcher_round"@android:roundIcon="@mipmap/ic_launcher"@g' "$OUTPUT_FILE"
fi

echo "✅ Android Manifest generated at $OUTPUT_FILE with injected permissions, label, and V2 embedding metadata."
