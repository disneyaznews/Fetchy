import SwiftUI
import AVFoundation

struct SplashVideoView: UIViewRepresentable {
    let videoName: String
    @Binding var isActive: Bool

    func makeUIView(context: Context) -> VideoContainerView {
        let view = VideoContainerView()
        view.backgroundColor = .clear

        guard let path = Bundle.main.path(forResource: videoName, ofType: nil) else {
            print("[Splash] Could not find video file: \(videoName)")
            DispatchQueue.main.async {
                isActive = false
            }
            return view
        }

        let url = URL(fileURLWithPath: path)
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        
        // Ensure transparency-friendly pixel format
        item.videoComposition = AVVideoComposition(asset: asset) { request in
            request.finish(with: request.sourceImage, context: nil)
        }
        
        let player = AVPlayer(playerItem: item)
        let playerLayer = AVPlayerLayer(player: player)

        playerLayer.videoGravity = .resizeAspect
        playerLayer.backgroundColor = UIColor.clear.cgColor
        playerLayer.isOpaque = false

        view.setPlayerLayer(playerLayer)
        context.coordinator.player = player
        context.coordinator.playerLayer = playerLayer

        // Listen for completion
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.playerDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )

        player.play()
        
        // Trigger isActive = false 0.5s before end for smooth early fade-out
        let duration = asset.duration.seconds
        if duration > 0.5 {
            let fadeStartTime = CMTime(seconds: max(0, duration - 0.5), preferredTimescale: 600)
            context.coordinator.timeObserver = player.addBoundaryTimeObserver(forTimes: [NSValue(time: fadeStartTime)], queue: .main) {
                print("[Splash] Early fade-out triggered")
                isActive = false
            }
        }
        
        // Add status observer for safety (silent failure handling)
        context.coordinator.statusObserver = player.currentItem?.observe(\.status, options: [.new]) { item, _ in
            if item.status == .failed {
                DispatchQueue.main.async {
                    isActive = false
                }
            }
        }
        
        return view
    }

    func updateUIView(_ uiView: VideoContainerView, context: Context) {
        // Layout is handled by VideoContainerView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: SplashVideoView
        var player: AVPlayer?
        var playerLayer: AVPlayerLayer?
        var statusObserver: NSKeyValueObservation?
        var timeObserver: Any?

        init(_ parent: SplashVideoView) {
            self.parent = parent
        }

        @objc func playerDidFinish() {
            DispatchQueue.main.async {
                self.parent.isActive = false
            }
        }
    }
}

class VideoContainerView: UIView {
    private var playerLayer: AVPlayerLayer?

    func setPlayerLayer(_ layer: AVPlayerLayer) {
        self.playerLayer?.removeFromSuperlayer()
        self.playerLayer = layer
        self.layer.addSublayer(layer)
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = self.bounds
    }
}
