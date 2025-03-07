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
    // Verwende den neuen lokalen Key für die Stummschaltung
    @AppStorage("mediaMutedLocal") var mediaMutedLocal: Bool = false
    
    @State private var thumbnail: UIImage? = nil
    @State private var isLoadingVideo = false
    @State private var player: AVPlayer? = nil
    @State private var isPlaying = false
    @State private var videoEnded = false // Neuer State für Video-Ende
    @State private var playerItemObserver: NSObjectProtocol? = nil // Observer für Videoende
    
    var body: some View {
        ZStack {
            if let player = player {
                ZStack {
                    TransparentVideoPlayer(player: player)
                        .onDisappear {
                            player.pause()
                            removeVideoEndObserver()
                        }
                    
                    Button(action: {
                        togglePlayPause()
                    }) {
                        ZStack {
                            // Transparenter Bereich über dem gesamten Video für bessere Tap-Erkennung
                            Color.clear
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                            // Play-Button nur anzeigen, wenn nicht abgespielt wird oder Video zu Ende ist
                            if !isPlaying || videoEnded {
                                Image(systemName: "play.circle.fill")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.white)
                                    .opacity(0.8)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle()) // Entfernt jegliche Button-Stile für eine nahtlose Darstellung
                }
            } else {
                ZStack {
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
            }
            
            if isLoadingVideo {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .onAppear(perform: fetchThumbnail)
        .onChange(of: mediaMutedLocal) { newValue in
            player?.isMuted = newValue
        }
    }
    
    func togglePlayPause() {
        guard let player = player else { return }
        
        if videoEnded {
            // Wenn das Video zu Ende ist, spulen wir zurück und starten neu
            player.seek(to: CMTime.zero)
            videoEnded = false
            player.play()
            isPlaying = true
        } else if player.timeControlStatus == .playing {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }
    
    func fetchThumbnail() {
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
    
    // Observer für Video-Ende hinzufügen
    func addVideoEndObserver() {
        removeVideoEndObserver() // Zuerst alten Observer entfernen, falls vorhanden
        
        guard let player = player else { return }
        
        // NotificationCenter-Observer für das Ende der Wiedergabe
        playerItemObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main) { _ in
                DispatchQueue.main.async {
                    // Video zurück zum Anfang setzen
                    player.seek(to: CMTime.zero)
                    self.videoEnded = true
                    self.isPlaying = false
                }
            }
    }
    
    // Observer für Video-Ende entfernen
    func removeVideoEndObserver() {
        if let observer = playerItemObserver {
            NotificationCenter.default.removeObserver(observer)
            playerItemObserver = nil
        }
    }
    
    func playVideo() {
        if let player = player {
            // Video neu starten, wenn es zu Ende ist
            if videoEnded {
                player.seek(to: CMTime.zero)
                videoEnded = false
            }
            
            isPlaying = true
            player.isMuted = mediaMutedLocal
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
                    self.player?.isMuted = self.mediaMutedLocal
                    
                    let audioSession = AVAudioSession.sharedInstance()
                    do {
                        try audioSession.setCategory(.ambient, mode: .moviePlayback, options: [])
                        try audioSession.setActive(true)
                    } catch {
                        print("Fehler beim Konfigurieren der Audio-Session: \(error)")
                    }
                    
                    // Observer für Video-Ende hinzufügen
                    self.addVideoEndObserver()
                    
                    self.isPlaying = true
                    self.videoEnded = false
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
