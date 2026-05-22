import SwiftUI

@main
struct MacLiveWallpaperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("MacLiveWallpaper", systemImage: "play.rectangle.on.rectangle") {
            Button("Choose Video...") {
                appState.chooseVideo()
            }

            Button(appState.isPlaying ? "Pause" : "Play") {
                appState.togglePlayPause()
            }
            .disabled(!appState.hasVideo)

            Button("Stop") {
                appState.stop()
            }
            .disabled(!appState.hasVideo)

            Divider()

            Picker("Display Mode", selection: $appState.displayMode) {
                ForEach(WallpaperDisplayMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .disabled(!appState.hasVideo)

            Divider()

            Button("Quit") {
                appState.stop()
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .menuBarExtraStyle(.menu)
    }
}
