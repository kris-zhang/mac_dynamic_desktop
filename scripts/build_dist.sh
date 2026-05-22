#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/MacLiveWallpaper.xcodeproj"
SCHEME="MacLiveWallpaper"
CONFIGURATION="Release"
BUILD_DIR="$ROOT_DIR/build"
DERIVED_DATA_DIR="$BUILD_DIR/DerivedData"
PACKAGE_DIR="$BUILD_DIR/package"
DMG_ROOT="$BUILD_DIR/dmgroot"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="MacLiveWallpaper"
APP_PATH="$DERIVED_DATA_DIR/Build/Products/$CONFIGURATION/$APP_NAME.app"
DIST_APP_PATH="$DIST_DIR/$APP_NAME.app"
ZIP_PATH="$DIST_DIR/$APP_NAME.zip"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"

echo "==> Cleaning package output"
rm -rf "$PACKAGE_DIR" "$DMG_ROOT" "$DIST_DIR"
mkdir -p "$PACKAGE_DIR" "$DMG_ROOT" "$DIST_DIR"

echo "==> Building $APP_NAME ($CONFIGURATION)"
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  -destination "platform=macOS" \
  build

if [[ ! -d "$APP_PATH" ]]; then
  echo "error: build succeeded but app was not found at $APP_PATH" >&2
  exit 1
fi

echo "==> Copying app to dist"
ditto "$APP_PATH" "$DIST_APP_PATH"

echo "==> Creating zip"
(
  cd "$DIST_DIR"
  ditto -c -k --sequesterRsrc --keepParent "$APP_NAME.app" "$ZIP_PATH"
)

echo "==> Creating dmg"
ditto "$APP_PATH" "$DMG_ROOT/$APP_NAME.app"
ln -s /Applications "$DMG_ROOT/Applications"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "==> Verifying artifacts"
test -d "$DIST_APP_PATH"
test -f "$ZIP_PATH"
test -f "$DMG_PATH"

echo
echo "Build artifacts:"
du -sh "$DIST_APP_PATH" "$ZIP_PATH" "$DMG_PATH"
