import AppKit
import AVFoundation

@MainActor
final class WallpaperWindowController {
    private let videoURL: URL
    private var displayControllers: [CGDirectDisplayID: DisplayWallpaperWindowController] = [:]
    private var screenObserver: NSObjectProtocol?
    private var isPlaying = false

    var displayMode: WallpaperDisplayMode {
        didSet {
            displayControllers.values.forEach { $0.displayMode = displayMode }
        }
    }

    init(videoURL: URL, displayMode: WallpaperDisplayMode) throws {
        self.videoURL = videoURL
        self.displayMode = displayMode
        try reloadScreens()
        observeScreenChanges()
    }

    func showAndPlay() {
        showAllWindows()
        play()
    }

    func play() {
        isPlaying = true
        displayControllers.values.forEach { $0.play() }
    }

    func pause() {
        isPlaying = false
        displayControllers.values.forEach { $0.pause() }
    }

    func stop() {
        isPlaying = false
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
            self.screenObserver = nil
        }
        displayControllers.values.forEach { $0.stop() }
        displayControllers.removeAll()
    }

    private func reloadScreens() throws {
        let screens = NSScreen.screens
        let activeDisplayIDs = Set(screens.map(\.displayID))

        for displayID in Array(displayControllers.keys) where !activeDisplayIDs.contains(displayID) {
            displayControllers.removeValue(forKey: displayID)?.stop()
        }

        for screen in screens {
            if let controller = displayControllers[screen.displayID] {
                controller.relayout(to: screen)
            } else {
                let controller = try DisplayWallpaperWindowController(
                    videoURL: videoURL,
                    displayMode: displayMode,
                    screen: screen
                )
                displayControllers[screen.displayID] = controller

                if isPlaying {
                    controller.showAndPlay()
                }
            }
        }
    }

    private func showAllWindows() {
        displayControllers.values.forEach { $0.showWindow() }
    }

    private func observeScreenChanges() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(200))
                try? self?.reloadScreens()
                self?.showAllWindows()
            }
        }
    }
}

@MainActor
private final class DisplayWallpaperWindowController: NSWindowController {
    private let playerView: PlayerView
    private let queuePlayer: AVQueuePlayer
    private var playerLooper: AVPlayerLooper?

    var displayMode: WallpaperDisplayMode {
        didSet {
            playerView.videoGravity = displayMode.videoGravity
        }
    }

    init(videoURL: URL, displayMode: WallpaperDisplayMode, screen: NSScreen) throws {
        self.displayMode = displayMode

        let asset = AVURLAsset(url: videoURL)
        let item = AVPlayerItem(asset: asset)
        self.queuePlayer = AVQueuePlayer()
        self.queuePlayer.actionAtItemEnd = .none
        self.playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        self.queuePlayer.isMuted = true

        self.playerView = PlayerView(player: queuePlayer, videoGravity: displayMode.videoGravity)

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        super.init(window: window)

        configureWindow(window, frame: screen.frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showAndPlay() {
        showWindow()
        play()
    }

    func showWindow() {
        window?.orderFrontRegardless()
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
        window?.orderOut(nil)
        close()
    }

    func relayout(to screen: NSScreen) {
        guard let window else { return }
        window.setFrame(screen.frame, display: true)
        playerView.frame = window.contentView?.bounds ?? .zero
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

private extension NSScreen {
    var displayID: CGDirectDisplayID {
        if let displayID = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID {
            return displayID
        }

        if let displayID = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            return CGDirectDisplayID(displayID.uint32Value)
        }

        return 0
    }
}
