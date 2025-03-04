//
//  ReviewDeletionView.swift
//  SwipeClean
//
//  Created by Jan Haider on 02.02.25.
//


import SwiftUI
import Photos

struct ReviewDeletionView: View {
    /// Die Assets, die ursprünglich zur Löschung vorgemerkt wurden.
    let assets: [PHAsset]
    /// Callback, der nach Bestätigung die tatsächlich zu löschenden Assets übergibt.
    let confirmAction: ([PHAsset]) -> Void
    
    /// Enthält die IDs der Assets, die aktuell als "löschen" markiert sind.
    @State private var selectedAssetIDs: Set<String> = []
    
    /// Zwei Spalten – passt sich aber ggf. an (z. B. durch Verwendung von .adaptive)
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(assets, id: \.localIdentifier) { asset in
                            AssetThumbnailView(asset: asset,
                                               isSelected: selectedAssetIDs.contains(asset.localIdentifier))
                                .onTapGesture {
                                    toggleSelection(for: asset)
                                }
                        }
                    }
                    .padding()
                }
                
                Button(action: {
                    // Übergebe nur die Assets, die weiterhin markiert sind.
                    let assetsToDelete = assets.filter { selectedAssetIDs.contains($0.localIdentifier) }
                    confirmAction(assetsToDelete)
                }) {
                    Text("Löschen bestätigen")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Löschbestätigung")
            .onAppear {
                // Standardmäßig werden alle Assets zur Löschung markiert.
                selectedAssetIDs = Set(assets.map { $0.localIdentifier })
            }
        }
    }
    
    private func toggleSelection(for asset: PHAsset) {
        if selectedAssetIDs.contains(asset.localIdentifier) {
            selectedAssetIDs.remove(asset.localIdentifier)
        } else {
            selectedAssetIDs.insert(asset.localIdentifier)
        }
    }
}

/// Ein kleiner Thumbnail-View für ein einzelnes Asset
struct AssetThumbnailView: View {
    let asset: PHAsset
    let isSelected: Bool
    @State private var image: UIImage? = nil
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .clipped()
            } else {
                Rectangle()
                    .foregroundColor(.gray)
                    .frame(height: 150)
            }
            
            // Ein Symbol, das den Auswahlstatus anzeigt
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .green : .white)
                .padding(6)
        }
        .cornerRadius(8)
        .shadow(radius: 2)
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        // Erstes, schnelles Laden des Thumbnails
        let optionsLow = PHImageRequestOptions()
        optionsLow.deliveryMode = .fastFormat
        optionsLow.resizeMode = .fast
        optionsLow.isSynchronous = false
        optionsLow.isNetworkAccessAllowed = true

        let targetSize = CGSize(width: 150, height: 150)

        PHImageManager.default().requestImage(for: asset,
                                              targetSize: targetSize,
                                              contentMode: .aspectFill,
                                              options: optionsLow) { imageLow, _ in
            if let imageLow = imageLow {
                // Setze das Low Quality-Bild auf dem Main-Thread
                DispatchQueue.main.async {
                    self.image = imageLow
                }
            }
            // Jetzt den High-Quality-Request starten
            let optionsHigh = PHImageRequestOptions()
            optionsHigh.deliveryMode = .highQualityFormat
            optionsHigh.resizeMode = .exact
            optionsHigh.isSynchronous = false
            optionsHigh.isNetworkAccessAllowed = true

            PHImageManager.default().requestImage(for: self.asset,
                                                  targetSize: targetSize,
                                                  contentMode: .aspectFill,
                                                  options: optionsHigh) { imageHigh, _ in
                if let imageHigh = imageHigh {
                    // Ersetze das Bild mit der hochqualitativen Version
                    DispatchQueue.main.async {
                        self.image = imageHigh
                    }
                }
            }
        }
    }
}
