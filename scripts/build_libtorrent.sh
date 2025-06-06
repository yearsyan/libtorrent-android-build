#!/bin/bash

# Exit on error
set -e
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LIBTORRENT_DIR=$PROJECT_ROOT/libtorrent

# Define all target architectures
ARCHS=("x86_64" "arm64-v8a")

# Function to build for a specific architecture
build_for_arch() {
    local ABI=$1
    echo "Building libtorrent for $ABI"
    
    cd $LIBTORRENT_DIR
    rm -rf build/$ABI
    mkdir -p build/$ABI
    mkdir -p $PROJECT_ROOT/install/$ABI
    cd build/$ABI

    export TOOLCHAIN_CMAKE=$ANDROID_NDK/build/cmake/android.toolchain.cmake

    # Set OpenSSL paths
    export OPENSSL_ROOT_DIR=$PROJECT_ROOT/deps.install/$ABI
    export OPENSSL_INCLUDE_DIR=$PROJECT_ROOT/deps.install/$ABI/include
    export OPENSSL_CRYPTO_LIBRARY=$PROJECT_ROOT/deps.install/$ABI/lib/libcrypto.a
    export OPENSSL_SSL_LIBRARY=$PROJECT_ROOT/deps.install/$ABI/lib/libssl.a

    # Set Boost paths
    export BOOST_ROOT=$PROJECT_ROOT/deps.install/$ABI
    export BOOST_INCLUDEDIR=$PROJECT_ROOT/deps.install/$ABI/include/boost-1_85
    export BOOST_LIBRARYDIR=$PROJECT_ROOT/deps.install/$ABI/lib
    export Boost_INCLUDE_DIR=$PROJECT_ROOT/deps.install/$ABI/include/boost-1_85
    export Boost_LIBRARY_DIR=$PROJECT_ROOT/deps.install/$ABI/lib

    # Optimization flags
    export CFLAGS="-Os -flto -ffunction-sections -fdata-sections"
    export CXXFLAGS="-Os -flto -ffunction-sections -fdata-sections"
    export LDFLAGS="-Wl,--gc-sections -Wl,--strip-all"

    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_STANDARD=14 \
        -DANDROID_PLATFORM=android-24 \
        -DCMAKE_PREFIX_PATH=$PROJECT_ROOT/install/$ABI \
        -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_CMAKE \
        -DANDROID_ABI=$ABI \
        -DOPENSSL_ROOT_DIR=$OPENSSL_ROOT_DIR \
        -DOPENSSL_INCLUDE_DIR=$OPENSSL_INCLUDE_DIR \
        -DOPENSSL_CRYPTO_LIBRARY=$OPENSSL_CRYPTO_LIBRARY \
        -DOPENSSL_SSL_LIBRARY=$OPENSSL_SSL_LIBRARY \
        -DBOOST_ROOT=$BOOST_ROOT \
        -DBOOST_INCLUDEDIR=$BOOST_INCLUDEDIR \
        -DBOOST_LIBRARYDIR=$BOOST_LIBRARYDIR \
        -DBoost_INCLUDE_DIR=$Boost_INCLUDE_DIR \
        -DBoost_LIBRARY_DIR=$Boost_LIBRARY_DIR \
        -DCMAKE_EXE_LINKER_FLAGS="-lc -lm -Wl,--gc-sections -Wl,--strip-all" \
        -DCMAKE_SHARED_LINKER_FLAGS="-lc -lm -Wl,--gc-sections -Wl,--strip-all" \
        -DCMAKE_INSTALL_PREFIX=$PROJECT_ROOT/install/$ABI \
        -DBUILD_SHARED_LIBS=ON \
        -Ddeprecated-functions=OFF \
        -Dlogging=OFF \
        -Dbuild_tests=OFF \
        -Dbuild_examples=OFF \
        -Dbuild_tools=OFF \
        -Dpython-bindings=OFF \
        -DCMAKE_C_FLAGS="$CFLAGS" \
        -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
        -DCMAKE_CXX_STANDARD_LIBRARIES="-lc++_shared" \
        -DCMAKE_CXX_FLAGS="$CXXFLAGS -fno-rtti" \
        -G Ninja \
        $LIBTORRENT_DIR
    cmake --build . --config Release --target install
    cp -r $PROJECT_ROOT/deps.install/$ABI/include/openssl $PROJECT_ROOT/install/$ABI/include
    cp -r $PROJECT_ROOT/deps.install/$ABI/include/boost-1_85/boost $PROJECT_ROOT/install/$ABI/include

    # Strip the shared library
    $ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip --strip-unneeded $PROJECT_ROOT/install/$ABI/lib/libtorrent-rasterbar.so
}

# Initialize and update git submodules
cd $LIBTORRENT_DIR
git submodule update --init --recursive

# Build for each architecture
for arch in "${ARCHS[@]}"; do
    build_for_arch $arch
done