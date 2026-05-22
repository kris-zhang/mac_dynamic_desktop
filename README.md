# MacLiveWallpaper

MacLiveWallpaper is a lightweight native macOS menu bar app that plays a local MP4/MOV video as a looping live wallpaper.

This repository contains the Xcode project, Swift source, app resources, and MIT license for the app.

## Preview

![MacLiveWallpaper live wallpaper demo](demo.webp)

## Project Structure

```text
MacLiveWallpaper/
├── MacLiveWallpaper.xcodeproj/
│   └── project.pbxproj
├── demo.webp
├── src/
│   ├── MacLiveWallpaperApp.swift
│   ├── AppDelegate.swift
│   ├── AppState.swift
│   ├── WallpaperDisplayMode.swift
│   ├── WallpaperWindowController.swift
│   ├── PlayerView.swift
│   ├── Info.plist
│   ├── MacLiveWallpaper.entitlements
│   └── Resources/
│       ├── AppIcon.icns
│       └── AppIcon-1024.png
├── scripts/
│   └── build_dist.sh
├── .gitignore
├── LICENSE
└── README.md
```

## Phase 1 Features

- SwiftUI `MenuBarExtra` menu bar app.
- AppKit borderless wallpaper window on the main display.
- `AVQueuePlayer` + `AVPlayerLooper` loop playback.
- MP4/MOV selection through `NSOpenPanel`.
- Play, pause, stop, and quit menu actions.
- Fill/Fit video gravity switch.
- Native app icon in `Resources/AppIcon.icns`.

## How To Create This In Xcode Manually

If you prefer recreating the project instead of opening this generated one:

1. Open Xcode and choose `File > New > Project`.
2. Select `macOS > App`.
3. Set `Product Name` to `MacLiveWallpaper`.
4. Set `Interface` to `SwiftUI`.
5. Set `Language` to `Swift`.
6. Disable tests for the first version if you want the smallest project.
7. Replace the generated files with the files in `src/`.

## Permissions

The first version keeps App Sandbox disabled and uses normal file paths returned by `NSOpenPanel`.

If you enable App Sandbox later:

1. Enable `App Sandbox` in `Signing & Capabilities`.
2. Enable `User Selected File` access with read-only or read/write access.
3. Store the selected video as a security-scoped bookmark.
4. Resolve and start accessing the bookmark before playback.

## Run

1. Open `MacLiveWallpaper.xcodeproj` in Xcode.
2. Select the `MacLiveWallpaper` scheme.
3. Run the app.
4. Click the menu bar icon.
5. Choose `Choose Video...` and select an MP4 or MOV file.

The app is configured as `LSUIElement`, so it lives in the menu bar and does not show a Dock icon.

## Build From Terminal

Use Xcode's command-line build when the local Xcode installation is healthy:

```sh
xcodebuild -project MacLiveWallpaper.xcodeproj -scheme MacLiveWallpaper -configuration Debug build
```

If `xcodebuild` is unavailable, a direct Swift compiler type check can still validate the source files:

```sh
xcrun swiftc -typecheck src/*.swift -target arm64-apple-macos14.0
```

To generate release-ready local artifacts in `dist/`, run:

```sh
./scripts/build_dist.sh
```

The script creates:

- `dist/MacLiveWallpaper.app`
- `dist/MacLiveWallpaper.zip`
- `dist/MacLiveWallpaper.dmg`

## Packaging

Local `.app`, `.dmg`, `.zip`, and build folders are intentionally ignored by git. Build release artifacts locally or attach them to GitHub Releases.

The generated icon source is stored at `src/Resources/AppIcon-1024.png`, and the app icon is stored at `src/Resources/AppIcon.icns`.

## Window Level Note

The wallpaper window uses `CGWindowLevelForKey(.desktopWindow)` and a borderless, mouse-ignoring `NSWindow`.
This keeps it below normal app windows and close to the desktop layer. macOS desktop icon behavior can vary by version and Finder state, so later versions may need a fallback strategy that recreates or reorders the window after Space/display changes.

## Verification

The source files pass direct Swift type checking with:

```sh
xcrun swiftc -typecheck src/*.swift -target arm64-apple-macos14.0
```
