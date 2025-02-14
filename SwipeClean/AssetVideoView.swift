//
//  AssetVideoView.swift
//  SwipeClean
//
//  Created by Jan Haider on 14.02.25.
//

import SwiftUI
import Photos
import AVKit

// Eine UIView-Klasse, die den AVPlayerLayer verwaltet und automatisch anpasst.
class VideoPlayerUIView: UIView {
    private var playerLayer: AVPlayerLayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }
    
    func setPlayer(_ player: AVPlayer) {
        if let playerLayer = self.playerLayer {
            playerLayer.player = player
        } else {
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = .resizeAspect
            playerLayer.backgroundColor = UIColor.clear.cgColor
            layer.addSublayer(playerLayer)
            self.playerLayer = playerLayer
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
}

// UIViewRepresentable, das den VideoPlayerUIView einbettet.
struct TransparentVideoPlayer: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> VideoPlayerUIView {
        let view = VideoPlayerUIView()
        view.setPlayer(player)
        return view
    }
    
    func updateUIView(_ uiView: VideoPlayerUIView, context: Context) {
        uiView.setPlayer(player)
    }
}

struct AssetVideoView: View {
    let asset: PHAsset
    @ObservedObject var imageCache: ImageCache
    @AppStorage("mediaMuted") var mediaMuted: Bool = false
    
    @State private var thumbnail: UIImage? = nil
    @State private var isLoadingVideo = false
    @State private var player: AVPlayer? = nil
    @State private var isPlaying = false
    
    var body: some View {
        ZStack {
            if isPlaying, let player = player {
                TransparentVideoPlayer(player: player)
                    .onDisappear {
                        player.pause()
                    }
            } else {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFit()
                } else {
                    Color.gray
                }
                Button(action: {
                    playVideo()
                }) {
                    Image(systemName: "play.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.white)
                        .opacity(0.8)
                }
            }
            
            if isLoadingVideo {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .onAppear(perform: fetchThumbnail)
        .onChange(of: mediaMuted) { newValue in
            player?.isMuted = newValue
        }
    }
    
    func togglePlayPause() {
        guard let player = player else { return }
        if player.timeControlStatus == .playing {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }
    
    func fetchThumbnail() {
        // Wenn bereits ein Thumbnail im Cache vorhanden ist, verwenden wir es.
        if let cached = imageCache.cache[asset.localIdentifier] {
            DispatchQueue.main.async {
                self.thumbnail = cached
            }
            return
        }
        
        let targetSize: CGSize = (asset.mediaType == .video)
        ? CGSize(width: 400, height: 300)
        : CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage(for: asset,
                                              targetSize: targetSize,
                                              contentMode: .aspectFit,
                                              options: options) { result, _ in
            if let result = result {
                DispatchQueue.main.async {
                    self.thumbnail = result
                    self.imageCache.cache[self.asset.localIdentifier] = result
                }
            } else if self.asset.mediaType == .video {
                // Fallback, falls kein Thumbnail geliefert wird.
                self.generateThumbnailFallback()
            }
        }
    }
    
    func generateThumbnailFallback() {
        let videoOptions = PHVideoRequestOptions()
        videoOptions.deliveryMode = .fastFormat
        videoOptions.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestAVAsset(forVideo: asset, options: videoOptions) { avAsset, audioMix, info in
            if let avAsset = avAsset {
                let generator = AVAssetImageGenerator(asset: avAsset)
                generator.appliesPreferredTrackTransform = true
                let time = CMTime(seconds: 1.0, preferredTimescale: 600)
                do {
                    let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                    let image = UIImage(cgImage: cgImage)
                    DispatchQueue.main.async {
                        self.thumbnail = image
                        self.imageCache.cache[self.asset.localIdentifier] = image
                    }
                } catch {
                    print("Fehler beim Generieren des Thumbnails: \(error)")
                }
            }
        }
    }
    
    func playVideo() {
        if let player = player {
            isPlaying = true
            player.isMuted = mediaMuted
            player.play()
            return
        }
        
        isLoadingVideo = true
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, audioMix, info in
            DispatchQueue.main.async {
                self.isLoadingVideo = false
                if let avAsset = avAsset {
                    let playerItem = AVPlayerItem(asset: avAsset)
                    self.player = AVPlayer(playerItem: playerItem)
                    self.player?.isMuted = self.mediaMuted
                    
                    // Konfiguriere die Audio-Session entsprechend des Stummmodus:
                    let audioSession = AVAudioSession.sharedInstance()
                    do {
                        if self.mediaMuted {
                            // Mit .ambient (oder alternativ .playback mit mixWithOthers) werden andere Medien nicht unterbrochen.
                            try audioSession.setCategory(.ambient, mode: .moviePlayback, options: [])
                        } else {
                            // Normale Wiedergabe – andere Medien werden ggf. pausiert.
                            try audioSession.setCategory(.ambient, mode: .moviePlayback, options: [])
                        }
                        try audioSession.setActive(true)
                    } catch {
                        print("Fehler beim Konfigurieren der Audio-Session: \(error)")
                    }
                    
                    self.isPlaying = true
                    self.player?.play()
                }
            }
        }
    }
    
    struct AssetVideoView_Previews: PreviewProvider {
        static var previews: some View {
            Text("AssetVideoView Preview")
        }
    }
}
