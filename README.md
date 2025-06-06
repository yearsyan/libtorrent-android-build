# LibTorrent Build System

This repository contains a build system for LibTorrent and its dependencies, including Boost and OpenSSL.

## Usage

1. Add dependency in your app's `build.gradle`:
```gradle
android {
    buildFeatures {
        prefab true
    }
}

dependencies {
    implementation 'io.github.yearsyan:libtorrent:0.1-alpha.5'
}
```

2. Add dependency in your `CMakeLists.txt`:
```cmake
find_package(libtorrent REQUIRED CONFIG)

add_library(mylib SHARED mylib.cpp)
target_link_libraries(mylib libtorrent::libtorrent)
```

## Build Yourself

To build the library yourself, simply run:

```bash
./build.sh
```

The built AAR file will be output to `build/libtorrent-${version}.aar`.

## Publish to Maven Central

To publish the library to Maven Central, you need to set up the following environment variables:

1. Export your GPG private key:
```bash
gpg --export-secret-keys --armor your-email@example.com > private.key
export GPG_PRIVATE_KEY=$(cat private.key)
```

2. Set your GPG password:
```bash
export GPG_PASSWORD="your-gpg-password"
```

3. Generate Sonatype authentication token:
   - Visit https://central.sonatype.org/publish/generate-portal-token/
   - Generate your username and password
   - Create the token using:
```bash
printf "your-username:your-password" | base64
export SONATYPE_AUTH_TOKEN="generated-base64-token"
```

After setting up these environment variables, you can publish the library to Maven Central.

## GitHub Actions Automation

The repository includes GitHub Actions workflow for automatic building and publishing. When you push a new tag, it will automatically:
1. Build the library
2. Publish to Maven Central

To set up the automation, add the following secrets in your GitHub repository settings:
- `GPG_PRIVATE_KEY`: Your GPG private key
- `GPG_PASSWORD`: Your GPG password
- `SONATYPE_AUTH_TOKEN`: Your Sonatype authentication token

To trigger a new release, simply create and push a new tag:
```bash
git tag v1.0.0
git push origin v1.0.0
```
