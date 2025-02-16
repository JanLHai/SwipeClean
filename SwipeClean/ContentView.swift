//
//  ContentView.swift
//  SwipeClean
//
//  Created by Jan Haider on [Datum].
//

import SwiftUI
import Photos
import PhotosUI
import AVKit

struct ContentView: View {
    /// Optionales Album – falls gesetzt, werden nur dessen Bilder/Videos geladen.
    let album: PHAssetCollection?
    /// Optionaler Datumsfilter – nur Bilder/Videos, die innerhalb dieses Bereichs erstellt wurden.
    let dateRange: DateRange?
    /// Neuer Parameter für den Medientyp-Filter (0: Bilder, 1: LivePhotos, 2: Videos)
    let mediaTypeFilter: [Int]?
    /// Optionaler Abschluss-Callback
    var onFinish: (() -> Void)? = nil
    
    @State private var assets: [PHAsset] = []
    @State private var finalOffset: CGSize = .zero
    @GestureState private var dragTranslation: CGSize = .zero
    @State private var authorizationStatus: PHAuthorizationStatus = .notDetermined
    /// Puffer für zur Löschung vorgemerkte Assets
    @State private var pendingDeletion: [PHAsset] = []
    @StateObject private var imageCache = ImageCache()
    /// In dieser Session als „Behalten“ markierte Assets
    @State private var sessionKeptAssets: [PHAsset] = []
    
    /// Anzeige des Review-Screens
    @State private var showReview: Bool = false
    
    @State private var dynamicBackground: Color = .clear
    @State private var showResetConfirmation = false
    @State private var showSlideOver = false
    
    let tiltThreshold: CGFloat = 75
    
    private var totalTranslation: CGFloat {
        finalOffset.width + dragTranslation.width
    }
    
    private func updateBackgroundColor() {
        if totalTranslation > tiltThreshold {
            dynamicBackground = Color.green.opacity(0.3)
        } else if totalTranslation < -tiltThreshold {
            dynamicBackground = Color.red.opacity(0.3)
        } else {
            dynamicBackground = Color.clear
        }
    }
    
    private func resetBackgroundColor() {
        dynamicBackground = Color.clear
    }
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                ZStack {
                    dynamicBackground
                        .edgesIgnoringSafeArea(.all)
                    
                    if let currentAsset = assets.first {
                        ZStack {
                            if currentAsset.mediaType == .video {
                                AssetVideoView(asset: currentAsset, imageCache: imageCache)
                                    .clipShape(RoundedRectangle(cornerRadius: min(abs(totalTranslation) / 5, 40)))
                            } else {
                                AssetImageView(asset: currentAsset, imageCache: imageCache)
                                    .clipShape(RoundedRectangle(cornerRadius: min(abs(totalTranslation) / 5, 40)))
                            }
                        }
                        .accessibilityElement()
                        .accessibilityIdentifier("assetMediaView")
                        .accessibilityLabel(currentAsset.localIdentifier)
                        .id(currentAsset.localIdentifier)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .offset(x: totalTranslation, y: 0)
                        .rotation3DEffect(
                            Angle.degrees(Double(totalTranslation) / 15),
                            axis: (x: 0, y: 0, z: 1),
                            anchor: .bottom,
                            perspective: 0.8
                        )
                        .gesture(
                            DragGesture()
                                .updating($dragTranslation) { value, state, _ in
                                    state = value.translation
                                }
                                .onChanged { _ in updateBackgroundColor() }
                                .onEnded { value in
                                    let finalValue = finalOffset.width + value.translation.width
                                    resetBackgroundColor()
                                    
                                    if finalValue > tiltThreshold {
                                        withAnimation(.easeOut(duration: 0.3)) { finalOffset = .zero }
                                        keepCurrentImage()
                                    } else if finalValue < -tiltThreshold {
                                        withAnimation(.easeOut(duration: 0.3)) { finalOffset = .zero }
                                        markCurrentImageForDeletion()
                                    } else {
                                        withAnimation(.easeOut(duration: 0.3)) { finalOffset = .zero }
                                    }
                                }
                        )
                    } else {
                        VStack {
                            Spacer()
                            Text("Keine Medien vorhanden")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .frame(width: geometry.size.width,
                               height: geometry.size.height)
                    }
                }
            }
            .frame(height: UIScreen.main.bounds.height * 0.7)
            
            if assets.isEmpty && PHAsset.fetchAssets(with: .image, options: nil).count > 0 {
                if dateRange != nil {
                    Text("Kein Foto in diesem Zeitraum gefunden")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    // Reset-Button, wenn keine Bilder mehr vorhanden sind – mit Bestätigungs-Alert
                    Button(action: {
                        showResetConfirmation = true
                    }) {
                        Text("Datenbank Zurücksetzen")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .alert(isPresented: $showResetConfirmation) {
                        Alert(
                            title: Text("Datenbank zurücksetzen"),
                            message: Text("Bist du dir sicher, dass du die lokale und Cloud-Datenbank zurücksetzen möchtest?"),
                            primaryButton: .destructive(Text("Zurücksetzen"), action: {
                                DatabaseManager.shared.resetKeptImages(for: album)
                                CloudKitSyncManager.shared.resetCloudDatabase { _ in }
                                loadAssets()
                                pendingDeletion.removeAll()
                                imageCache.cache.removeAll()
                                
                                withAnimation { showSlideOver = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    withAnimation { showSlideOver = false }
                                }
                            }),
                            secondaryButton: .cancel()
                        )
                    }
                    .padding(.horizontal)
                }
            }
            
            HStack {
                Button(action: { markCurrentImageForDeletion() }) {
                    Text("Löschen")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.red, lineWidth: 2)
                        )
                        .cornerRadius(10)
                }
                .disabled(assets.isEmpty)
                .opacity(assets.isEmpty ? 0.5 : 1.0)
                
                Button(action: { keepCurrentImage() }) {
                    Text("Behalten")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.green, lineWidth: 2)
                        )
                        .cornerRadius(10)
                }
                .disabled(assets.isEmpty)
                .opacity(assets.isEmpty ? 0.5 : 1.0)
            }
            .padding()
        }
        .onAppear { requestPhotoLibraryAccess() }
        .onChange(of: assets.count) { _ in prefetchHighQualityImages() }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { restoreKeptImage() }) {
                    Image(systemName: "arrowshape.turn.up.left")
                        .foregroundColor(sessionKeptAssets.isEmpty ? Color(UIColor.darkGray) : Color.white)
                        .padding(8)
                        .background(sessionKeptAssets.isEmpty ? Color(UIColor.lightGray) : Color.blue)
                        .clipShape(Circle())
                        .scaleEffect(0.7)
                        .accessibilityLabel("Bild wiederherstellen")
                }
                .disabled(sessionKeptAssets.isEmpty)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Fertig (\(pendingDeletion.count))") {
                    if !pendingDeletion.isEmpty {
                        showReview = true
                    } else {
                        popToRoot()
                    }
                }
            }
        }
        .sheet(isPresented: $showReview, onDismiss: {
            popToRoot()
        }) {
            ReviewDeletionView(assets: pendingDeletion) { assetsToDelete in
                // Lösche die Assets, die zur Löschung markiert wurden
                for asset in assetsToDelete {
                    let fileSize = asset.getFileSize()
                    DatabaseManager.shared.deleteAsset(assetID: asset.localIdentifier, freedBytes: fileSize)
                }
                // Für die Assets, die beibehalten werden:
                let keptAssets = pendingDeletion.filter { !assetsToDelete.contains($0) }
                for asset in keptAssets {
                    DatabaseManager.shared.saveAsset(assetID: asset.localIdentifier, date: Date())
                }
                // Führe die Batch-Löschung in der Fotobibliothek durch:
                performBatchDeletion(for: assetsToDelete)
                
                pendingDeletion.removeAll()
                showReview = false
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                self.authorizationStatus = status
                if status == .authorized || status == .limited {
                    loadAssets()
                }
            }
        }
    }
    
    func loadAssets() {
        var fetchedAssets: [PHAsset] = []
        let fetchOptions = PHFetchOptions()
        
        // Bei keinem speziellen Filter: Bilder und Videos laden
        if mediaTypeFilter == nil {
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d OR mediaType == %d",
                                                 PHAssetMediaType.image.rawValue,
                                                 PHAssetMediaType.video.rawValue)
        } else {
            if let type = mediaTypeFilter?.first {
                switch type {
                case 0:
                    // Normale Bilder (ohne LivePhotos): Abrufen aller Bilder und später filtern
                    fetchOptions.predicate = NSPredicate(format: "mediaType == %d",
                                                         PHAssetMediaType.image.rawValue)
                case 1:
                    // LivePhotos: Abrufen aller Bilder und später filtern
                    fetchOptions.predicate = NSPredicate(format: "mediaType == %d",
                                                         PHAssetMediaType.image.rawValue)
                case 2:
                    // Videos
                    fetchOptions.predicate = NSPredicate(format: "mediaType == %d",
                                                         PHAssetMediaType.video.rawValue)
                default:
                    break
                }
            }
        }
        
        let keptIDs = DatabaseManager.shared.getKeptImages().keys
        
        if let album = album {
            let fetchResult = PHAsset.fetchAssets(in: album, options: fetchOptions)
            fetchResult.enumerateObjects { asset, _, _ in
                if let type = mediaTypeFilter?.first {
                    switch type {
                    case 0:
                        // Filtere normale Bilder (keine LivePhotos)
                        if asset.mediaType != .image || asset.mediaSubtypes.contains(.photoLive) { return }
                    case 1:
                        // Filtere ausschließlich LivePhotos
                        if asset.mediaType != .image || !asset.mediaSubtypes.contains(.photoLive) { return }
                    case 2:
                        if asset.mediaType != .video { return }
                    default:
                        break
                    }
                }
                if !DatabaseManager.shared.isAssetKept(assetID: asset.localIdentifier) &&
                    !DatabaseManager.shared.isAssetDeleted(assetID: asset.localIdentifier) {
                    if let dateRange = dateRange {
                        if let creationDate = asset.creationDate,
                           creationDate >= dateRange.start && creationDate <= dateRange.end {
                            fetchedAssets.append(asset)
                        }
                    } else {
                        fetchedAssets.append(asset)
                    }
                }
            }
        } else {
            let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
            fetchResult.enumerateObjects { asset, _, _ in
                if !DatabaseManager.shared.isAssetKept(assetID: asset.localIdentifier) &&
                    !DatabaseManager.shared.isAssetDeleted(assetID: asset.localIdentifier) {
                    if let type = mediaTypeFilter?.first {
                        switch type {
                        case 0:
                            if asset.mediaType != .image || asset.mediaSubtypes.contains(.photoLive) { return }
                        case 1:
                            if asset.mediaType != .image || !asset.mediaSubtypes.contains(.photoLive) { return }
                        case 2:
                            if asset.mediaType != .video { return }
                        default:
                            break
                        }
                    }
                    if let dateRange = dateRange {
                        if let creationDate = asset.creationDate,
                           creationDate >= dateRange.start && creationDate <= dateRange.end {
                            fetchedAssets.append(asset)
                        }
                    } else {
                        fetchedAssets.append(asset)
                    }
                }
            }
        }
        
        // Sortiere die Assets aufsteigend nach Datum
        fetchedAssets.sort { (asset1, asset2) -> Bool in
            let date1 = asset1.creationDate ?? asset1.modificationDate ?? Date.distantPast
            let date2 = asset2.creationDate ?? asset2.modificationDate ?? Date.distantPast
            return date1 < date2
        }
        
        self.assets = fetchedAssets
    }
    
    func keepCurrentImage() {
        guard let currentAsset = assets.first else { return }
        DatabaseManager.shared.saveAsset(assetID: currentAsset.localIdentifier, date: Date())
        sessionKeptAssets.append(currentAsset)
        removeCurrentAsset()
    }
    
    func markCurrentImageForDeletion() {
        guard let currentAsset = assets.first else { return }
        pendingDeletion.append(currentAsset)
        removeCurrentAsset()
    }
    
    func removeCurrentAsset() {
        if let currentAsset = assets.first {
            if !DatabaseManager.shared.isAssetDeleted(assetID: currentAsset.localIdentifier) {
                imageCache.cache.removeValue(forKey: currentAsset.localIdentifier)
            }
        }
        if !assets.isEmpty {
            assets.removeFirst()
        }
        finalOffset = .zero
        if assets.isEmpty {
            loadAssets()
        }
    }
    
    func prefetchHighQualityImages() {
        guard assets.count > 0 else { return }
        let count = min(5, assets.count)
        for i in 0..<count {
            let asset = assets[i]
            if imageCache.cache[asset.localIdentifier] != nil { continue }
            let targetSize = UIScreen.main.bounds.size
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestImage(for: asset,
                                                  targetSize: targetSize,
                                                  contentMode: .aspectFit,
                                                  options: options) { result, _ in
                if let result = result {
                    DispatchQueue.main.async {
                        self.imageCache.cache[asset.localIdentifier] = result
                    }
                }
            }
        }
    }
    
    func performBatchDeletion(for assetsToDelete: [PHAsset]) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assetsToDelete as NSArray)
        }) { success, error in
            if success {
                DispatchQueue.main.async {
                    assetsToDelete.forEach { asset in
                        self.imageCache.cache.removeValue(forKey: asset.localIdentifier)
                    }
                }
            } else {
                print("Fehler bei der Batch-Löschung: \(error?.localizedDescription ?? "Unbekannter Fehler")")
            }
        }
    }
    
    func restoreKeptImage() {
        guard let asset = sessionKeptAssets.popLast() else { return }
        DatabaseManager.shared.removeKeptAsset(assetID: asset.localIdentifier)
        assets.insert(asset, at: 0)
    }
}

extension UIApplication {
    var keyNavigationController: UINavigationController? {
        guard let window = self.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.windows.first?.isKeyWindow == true })?
                .windows.first(where: { $0.isKeyWindow }) else { return nil }
        return window.rootViewController as? UINavigationController ?? window.rootViewController?.findNavigationController()
    }
}

extension UIViewController {
    func findNavigationController() -> UINavigationController? {
        if let nav = self as? UINavigationController {
            return nav
        }
        for child in children {
            if let nav = child.findNavigationController() {
                return nav
            }
        }
        return nil
    }
}

extension View {
    func popToRoot() {
        UIApplication.shared.keyNavigationController?.popToRootViewController(animated: true)
    }
}

extension PHAsset {
    func getFileSize() -> Int64 {
        let resources = PHAssetResource.assetResources(for: self)
        if let resource = resources.first,
           let fileSizeNumber = resource.value(forKey: "fileSize") as? NSNumber {
            return fileSizeNumber.int64Value
        }
        return 0
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // Vorschau ohne Filter
        ContentView(album: nil, dateRange: nil, mediaTypeFilter: nil)
    }
}
