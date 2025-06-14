#!/bin/bash
set -e

# Set environment variables
export PKG_NAME="com.garbcode.garbcodeapp"
export COMPILE_SDK_VERSION="35"
export MIN_SDK_VERSION="21"
export TARGET_SDK_VERSION="35"
export PUSH_NOTIFY="true"

# Run the configuration scripts
bash lib/scripts/android/configure_android_build_fixed.sh 