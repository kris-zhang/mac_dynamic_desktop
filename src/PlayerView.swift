import AppKit
import AVFoundation

final class PlayerView: NSView {
    override var wantsUpdateLayer: Bool { true }

    private var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    var videoGravity: AVLayerVideoGravity {
        get { playerLayer.videoGravity }
        set { playerLayer.videoGravity = newValue }
    }

    init(player: AVPlayer, videoGravity: AVLayerVideoGravity) {
        super.init(frame: .zero)
        wantsLayer = true
        playerLayer.player = player
        playerLayer.videoGravity = videoGravity
        playerLayer.backgroundColor = NSColor.black.cgColor
        autoresizingMask = [.width, .height]
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func makeBackingLayer() -> CALayer {
        AVPlayerLayer()
    }
}
