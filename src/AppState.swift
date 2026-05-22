import AppKit
import AVFoundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var isPlaying = false
    @Published var displayMode: WallpaperDisplayMode = .aspectFill {
        didSet {
            wallpaperController?.displayMode = displayMode
        }
    }

    private var selectedVideoURL: URL?
    private var wallpaperController: WallpaperWindowController?

    var hasVideo: Bool {
        selectedVideoURL != nil
    }

    func chooseVideo() {
        let panel = NSOpenPanel()
        panel.title = "Choose a Video"
        panel.prompt = "Choose"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie, .movie]

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return }

        loadAndPlay(url: url)
    }

    func togglePlayPause() {
        guard let controller = wallpaperController else {
            if let selectedVideoURL {
                loadAndPlay(url: selectedVideoURL)
            }
            return
        }

        if isPlaying {
            controller.pause()
            isPlaying = false
        } else {
            controller.play()
            isPlaying = true
        }
    }

    func stop() {
        wallpaperController?.stop()
        wallpaperController = nil
        isPlaying = false
    }

    private func loadAndPlay(url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            showError(title: "Video Not Found", message: "The selected video file no longer exists.")
            return
        }

        selectedVideoURL = url

        do {
            let controller = try WallpaperWindowController(videoURL: url, displayMode: displayMode)
            wallpaperController?.stop()
            wallpaperController = controller
            controller.showAndPlay()
            isPlaying = true
        } catch {
            showError(title: "Cannot Play Video", message: error.localizedDescription)
            isPlaying = false
        }
    }

    private func showError(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
