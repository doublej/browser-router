#!/bin/bash
set -e

APP_NAME="Browser Router"
BUNDLE_ID="com.browserrouter.app"
BUILD_DIR=".build/release"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
RESOURCES_DIR="Resources"
INFO_PLIST="$RESOURCES_DIR/Info.plist"

# Git-based versioning
get_version() {
    local tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "v1.0.0")
    echo "${tag#v}"
}

get_build_number() {
    git rev-list --count HEAD 2>/dev/null || echo "1"
}

get_commit_hash() {
    git rev-parse --short HEAD 2>/dev/null || echo "unknown"
}

VERSION=$(get_version)
BUILD_NUMBER=$(get_build_number)
COMMIT_HASH=$(get_commit_hash)

echo "Building $APP_NAME v$VERSION ($BUILD_NUMBER) [$COMMIT_HASH]"

echo "Building release..."
swift build -c release

echo "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/BrowserRouter" "$APP_BUNDLE/Contents/MacOS/"

# Inject version into Info.plist
sed -e "s|<string>1.0.0</string>|<string>$VERSION</string>|" \
    -e "s|<key>CFBundleVersion</key>|<key>CFBundleVersion</key>|" \
    -e "s|<string>1</string>|<string>$BUILD_NUMBER</string>|" \
    "$INFO_PLIST" > "$APP_BUNDLE/Contents/Info.plist"

cat > "$APP_BUNDLE/Contents/PkgInfo" << EOF
APPL????
EOF

echo "App bundle created at: $APP_BUNDLE"
echo "Version: $VERSION (build $BUILD_NUMBER)"
echo ""
echo "To install:"
echo "  cp -r \"$APP_BUNDLE\" /Applications/"
echo ""
echo "To run:"
echo "  open \"$APP_BUNDLE\""
