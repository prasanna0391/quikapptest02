#!/usr/bin/env bash

set -euo pipefail # Exit immediately if a command exits with a non-zero status.
                  # Exit if a variable is used uninitialized.
                  # Exit if a command in a pipeline fails.

echo "--- Deleting Old Keystore Files ---"

# Define both possible keystore locations
KEYSTORE_LOCATIONS=(
    "android/keystore.jks"          # Main location
    "android/app/keystore.jks"      # Alternative location
)
KEYSTORE_PROPERTIES="android/key.properties"

# Function to safely delete a file
delete_file() {
    local file="$1"
    if [ -f "$file" ]; then
        echo "Found file: $file"
        rm -f "$file"
        if [ $? -eq 0 ]; then
            echo "Successfully deleted $file"
        else
            echo "Warning: Failed to delete $file"
            return 1
        fi
    else
        echo "No file found at $file. Skipping deletion."
    fi
}

# Delete all possible keystore locations
for keystore in "${KEYSTORE_LOCATIONS[@]}"; do
    delete_file "$keystore"
done

# Delete key.properties file
delete_file "$KEYSTORE_PROPERTIES"

echo "--- Old Keystore File Deletion Complete ---"
exit 0