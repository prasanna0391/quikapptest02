#!/usr/bin/env bash

set -euo pipefail # Exit immediately if a command exits with a non-zero status.
                  # Exit if a variable is used uninitialized.
                  # Exit if a command in a pipeline fails.

echo "--- Deleting Old Keystore Files ---"

# Define the common locations for keystore files relative to your project root.
# These paths are now consistent with where 'inject_keystore.sh' will place them.
KEYSTORE_JKS="android/keystore.jks"          # The JKS file itself
KEYSTORE_PROPERTIES="android/key.properties" # The properties file for Gradle

# Check and delete .jks file
if [ -f "$KEYSTORE_JKS" ]; then
    echo "Found old .jks file: $KEYSTORE_JKS"
    rm -f "$KEYSTORE_JKS"
    if [ $? -eq 0 ]; then
        echo "Successfully deleted $KEYSTORE_JKS"
    else
        echo "Error: Failed to delete $KEYSTORE_JKS"
        exit 1
    fi
else
    echo "No old .jks file found at $KEYSTORE_JKS. Skipping deletion."
fi

# Check and delete key.properties file
if [ -f "$KEYSTORE_PROPERTIES" ]; then
    echo "Found old keystore properties file: $KEYSTORE_PROPERTIES"
    rm -f "$KEYSTORE_PROPERTIES"
    if [ $? -eq 0 ]; then
        echo "Successfully deleted $KEYSTORE_PROPERTIES"
    else
        echo "Error: Failed to delete $KEYSTORE_PROPERTIES"
        exit 1
    fi
else
    echo "No old keystore properties file found at $KEYSTORE_PROPERTIES. Skipping deletion."
fi

echo "--- Old Keystore File Deletion Complete ---"

exit 0 # Indicate success