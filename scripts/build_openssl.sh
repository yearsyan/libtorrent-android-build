#!/bin/bash

# Exit on error
set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"


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

# Set up PATH for cross-compilation
export PATH=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH

# Create build and install directories
mkdir -p "$PROJECT_ROOT/build/install"

# Function to build for a specific architecture
build_arch() {
    local arch=$1
    local abi_name=$2
    local api_level=24
    local install_dir="$PROJECT_ROOT/deps.install/$abi_name"
    
    echo "Building OpenSSL for $arch ($abi_name)..."
    
    # Navigate to OpenSSL directory
    cd "$PROJECT_ROOT/openssl"
    
    # Clean any previous build
    make clean || true
    
    # Configure for the specific architecture
    ./Configure android-$arch -D__ANDROID_API__=$api_level \
        --prefix="$install_dir" \
        --openssldir="$install_dir" \
        no-shared \
        no-weak-ssl-ciphers \
        no-unit-test \
        no-tests \
        no-external-tests \
        no-apps \
        -DOPENSSL_SMALL
    
    # Build and install with optimization flags
    export LDFLAGS="-Wl,--gc-sections -Wl,--strip-all -Wl,--exclude-libs,ALL -Wl,--whole-archive -Wl,--no-whole-archive"
    make -j$(nproc) CFLAGS="-Os -ffunction-sections -fdata-sections -fomit-frame-pointer -fvisibility=hidden"
    make install_sw
    
    # Strip the libraries to remove debug symbols
    find "$install_dir" -name "*.a" -exec $ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip --strip-unneeded {} \;
    
    echo "OpenSSL has been built and installed to $install_dir directory"
}

# Build for all architectures
build_arch "arm" "armeabi-v7a"
build_arch "arm64" "arm64-v8a"
build_arch "x86" "x86"
build_arch "x86_64" "x86_64"

echo "OpenSSL has been built for all architectures in $PROJECT_ROOT/build/deps.install directory"
