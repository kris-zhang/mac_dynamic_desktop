import AppKit
import AVFoundation

@MainActor
final class WallpaperWindowController: NSWindowController {
    private let playerView: PlayerView
    private let queuePlayer: AVQueuePlayer
    private var playerLooper: AVPlayerLooper?
    private var screenObserver: NSObjectProtocol?

    var displayMode: WallpaperDisplayMode {
        didSet {
            playerView.videoGravity = displayMode.videoGravity
        }
    }

    init(videoURL: URL, displayMode: WallpaperDisplayMode) throws {
        self.displayMode = displayMode

        let asset = AVURLAsset(url: videoURL)
        let item = AVPlayerItem(asset: asset)
        self.queuePlayer = AVQueuePlayer()
        self.queuePlayer.actionAtItemEnd = .none
        self.playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        self.queuePlayer.isMuted = true

        self.playerView = PlayerView(player: queuePlayer, videoGravity: displayMode.videoGravity)

        let screenFrame = NSScreen.main?.frame ?? .zero
        let window = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        super.init(window: window)

        configureWindow(window, frame: screenFrame)
        observeScreenChanges()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showAndPlay() {
        guard let window else { return }
        window.orderFrontRegardless()
        play()
    }

    func play() {
        queuePlayer.play()
    }

    func pause() {
        queuePlayer.pause()
    }

    func stop() {
        queuePlayer.pause()
        playerLooper = nil
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
            self.screenObserver = nil
        }
        window?.orderOut(nil)
        close()
    }

    func relayoutToMainScreen() {
        guard let screen = NSScreen.main, let window else { return }
        window.setFrame(screen.frame, display: true)
        playerView.frame = window.contentView?.bounds ?? .zero
    }

    private func observeScreenChanges() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(200))
                self?.relayoutToMainScreen()
                self?.window?.orderFrontRegardless()
            }
        }
    }

    private func configureWindow(_ window: NSWindow, frame: NSRect) {
        window.contentView = playerView
        window.setFrame(frame, display: true)
        window.isReleasedWhenClosed = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovable = false
        window.canHide = false
        window.hidesOnDeactivate = false
        window.acceptsMouseMovedEvents = false
        window.ignoresMouseEvents = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
            .fullScreenAuxiliary
        ]

        let desktopLevel = Int(CGWindowLevelForKey(.desktopWindow))
        window.level = NSWindow.Level(rawValue: desktopLevel)
    }
}
