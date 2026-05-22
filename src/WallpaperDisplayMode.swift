import AVFoundation

enum WallpaperDisplayMode: String, CaseIterable, Identifiable {
    case aspectFill
    case aspectFit

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aspectFill:
            "Fill"
        case .aspectFit:
            "Fit"
        }
    }

    var videoGravity: AVLayerVideoGravity {
        switch self {
        case .aspectFill:
            .resizeAspectFill
        case .aspectFit:
            .resizeAspect
        }
    }
}
