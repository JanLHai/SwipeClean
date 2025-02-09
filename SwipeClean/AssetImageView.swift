import SwiftUI
import Photos
import PhotosUI

struct AssetImageView: View {
    let asset: PHAsset
    @ObservedObject var imageCache: ImageCache

    @State private var uiImage: UIImage? = nil
    @State private var livePhoto: PHLivePhoto? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {
            if asset.mediaSubtypes.contains(.photoLive) {
                if let livePhoto = livePhoto {
                    LivePhotoViewWrapper(livePhoto: livePhoto)
                        .scaledToFit()
                } else {
                    Color.gray
                }
            } else {
                if let cached = imageCache.cache[asset.localIdentifier] {
                    Image(uiImage: cached)
                        .resizable()
                        .scaledToFit()
                } else if let image = uiImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    Color.gray
                }
            }
            
            
        }
        .onAppear { fetchAsset() }
    }

    


    func fetchAsset() {
        // Verwende die native Auflösung des Assets für beste Qualität
        let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        
        if asset.mediaSubtypes.contains(.photoLive) {
            // Zuerst schnelle LivePhoto-Anfrage
            let optionsLow = PHLivePhotoRequestOptions()
            optionsLow.deliveryMode = .fastFormat
            optionsLow.isNetworkAccessAllowed = true
            
            PHImageManager.default().requestLivePhoto(for: asset,
                                                      targetSize: targetSize,
                                                      contentMode: .aspectFit,
                                                      options: optionsLow) { (lp, info) in
                if let lp = lp {
                    self.livePhoto = lp
                }
                // Anschließend High-Quality-Anfrage
                let optionsHigh = PHLivePhotoRequestOptions()
                optionsHigh.deliveryMode = .highQualityFormat
                optionsHigh.isNetworkAccessAllowed = true
                
                PHImageManager.default().requestLivePhoto(for: asset,
                                                          targetSize: targetSize,
                                                          contentMode: .aspectFit,
                                                          options: optionsHigh) { (lp, info) in
                    if let lp = lp {
                        self.livePhoto = lp
                    }
                }
            }
        } else {
            // Zuerst schnelle Bild-Anfrage
            let optionsLow = PHImageRequestOptions()
            optionsLow.deliveryMode = .fastFormat
            optionsLow.resizeMode = .exact
            optionsLow.isNetworkAccessAllowed = true
            
            PHImageManager.default().requestImage(for: asset,
                                                  targetSize: targetSize,
                                                  contentMode: .aspectFit,
                                                  options: optionsLow) { (result, info) in
                if let result = result, self.imageCache.cache[asset.localIdentifier] == nil {
                    self.uiImage = result
                }
                // Anschließend High-Quality-Anfrage
                let optionsHigh = PHImageRequestOptions()
                optionsHigh.deliveryMode = .highQualityFormat
                optionsHigh.resizeMode = .exact
                optionsHigh.isNetworkAccessAllowed = true
                
                PHImageManager.default().requestImage(for: asset,
                                                      targetSize: targetSize,
                                                      contentMode: .aspectFit,
                                                      options: optionsHigh) { (result, info) in
                    if let result = result {
                        self.uiImage = result
                        // High-Quality-Bild im Cache speichern
                        self.imageCache.cache[asset.localIdentifier] = result
                    }
                }
            }
        }
    }
}

struct AssetImageView_Previews: PreviewProvider {
    static var previews: some View {
        // Dummy Asset-Vorschau: In der echten App wird ein PHAsset geladen.
        Text("AssetImageView Preview")
    }
}
