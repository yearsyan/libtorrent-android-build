#!/bin/bash

# Exit on error
set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT=$SCRIPT_DIR
echo "PROJECT_ROOT: $PROJECT_ROOT"

# Try to find Android NDK from various environment variables
if [ -z "$ANDROID_NDK_ROOT" ]; then
    if [ -n "$ANDROID_NDK" ]; then
        ANDROID_NDK_ROOT="$ANDROID_NDK"
    elif [ -n "$ANDROID_NDK_HOME" ]; then
        ANDROID_NDK_ROOT="$ANDROID_NDK_HOME"
    else
        echo "Error: ANDROID_NDK_ROOT, ANDROID_NDK, or ANDROID_NDK_HOME must be set"
        exit 1
    fi
fi

source "$SCRIPT_DIR/scripts/setup_cmake.sh"

echo "Building Boost..."
cd $PROJECT_ROOT
mkdir -p $PROJECT_ROOT/deps.install
./boost-build/build-android.sh --boost=1.85.0 --prefix=$PROJECT_ROOT/deps.install $ANDROID_NDK_ROOT
# Build OpenSSL
echo "Building OpenSSL..."
cd "$PROJECT_ROOT/scripts"
./build_openssl.sh >> build.log 2>&1

echo "Building libtorrent..."
$PROJECT_ROOT/scripts/build_libtorrent.sh >> build.log 2>&1
echo "Creating Prefab..."
$PROJECT_ROOT/scripts/create_prefab.sh >> build.log 2>&1
echo "Done"