import SwiftUI
import Photos
import PhotosUI

struct ContentView: View {
    /// Optionales Album – wenn vorhanden, werden ausschließlich dessen Bilder geladen.
    let album: PHAssetCollection?
    
    @State private var assets: [PHAsset] = []
    @State private var finalOffset: CGSize = .zero
    @GestureState private var dragTranslation: CGSize = .zero
    @State private var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @State private var debugMode: Bool = false
    /// Puffer für Assets, die zur Löschung vorgemerkt wurden
    @State private var pendingDeletion: [PHAsset] = []
    @StateObject private var imageCache = ImageCache()
    /// Hier speichern wir alle in der aktuellen Session als "Behalten" markierten Assets
    @State private var sessionKeptAssets: [PHAsset] = []
    
    /// Wird genutzt, um den Review-Screen anzuzeigen
    @State private var showReview: Bool = false
    /// Damit wir im ContentView wieder "zurück" navigieren können
    @Environment(\.presentationMode) var presentationMode

    @State private var dynamicBackground: Color = .clear
    @State private var showConfirmation = false
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
    
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                ZStack {
                    dynamicBackground
                        .edgesIgnoringSafeArea(.all)
                    
                    if let currentAsset = assets.first {
                        ZStack {
                            AssetImageView(asset: currentAsset, imageCache: imageCache)
                                .clipShape(RoundedRectangle(cornerRadius: min(abs(totalTranslation) / 5, 40)))
                        }
                        .accessibilityElement()
                        .accessibilityIdentifier("assetImageView")
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
                                .onChanged { _ in
                                    updateBackgroundColor() // Hintergrundfarbe aktualisieren
                                }
                                .onEnded { value in
                                    let finalValue = finalOffset.width + value.translation.width
                                    resetBackgroundColor()

                                    if finalValue > tiltThreshold {
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            finalOffset = .zero
                                        }
                                        keepCurrentImage()
                                    } else if finalValue < -tiltThreshold {
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            finalOffset = .zero
                                        }
                                        markCurrentImageForDeletion()
                                    } else {
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            finalOffset = .zero
                                        }
                                    }
                                }
                        )
                    } else {
                        VStack {
                            Spacer()
                            Text("Keine Bilder vorhanden")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .frame(width: geometry.size.width,
                               height: geometry.size.height)
                    }
                }
            }
            .frame(height: UIScreen.main.bounds.height * (0.7))
            
            
            if assets.isEmpty && PHAsset.fetchAssets(with: .image, options: nil).count > 0 {
                Button(action: {
                    // Zeige das Bestätigungs-Alert an, statt die Aktionen direkt auszuführen.
                    showConfirmation = true
                }) {
                    Text("Datenbank Zurücksetzen")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .alert(isPresented: $showConfirmation) {
                    Alert(
                        title: Text("Datenbank löschen"),
                        message: Text("Bist du dir sicher, dass du die Datenbank löschen möchtest?"),
                        primaryButton: .destructive(Text("Zurücksetzen"), action: {
                            // Führe hier alle gewünschten Aktionen aus:
                            DatabaseManager.shared.resetKeptImages(for: album)
                            loadAssets()
                            pendingDeletion.removeAll()
                            imageCache.cache.removeAll()
                            
                            // Optional: Zeige einen SlideOver-Animationseffekt an:
                            withAnimation {
                                showSlideOver = true
                            }
                            // Blende den SlideOver nach 3 Sekunden wieder aus
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    showSlideOver = false
                                }
                            }
                        }),
                        secondaryButton: .cancel(Text("Abbrechen"))
                    )
                }
                .padding(.horizontal)
                
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
        .onAppear {
            requestPhotoLibraryAccess()
        }
        .onChange(of: assets.count) {
            prefetchHighQualityImages()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    restoreKeptImage()
                }) {
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
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showReview, onDismiss: {
            presentationMode.wrappedValue.dismiss()
        }) {
            ReviewDeletionView(assets: pendingDeletion) { assetsToDelete in
                performBatchDeletion(for: assetsToDelete)
                pendingDeletion.removeAll()
                showReview = false
            }
        }
    }
    
    // MARK: - Hilfsfunktionen
    
    func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                self.authorizationStatus = status
                if status == .authorized || status == .limited {
                    loadAssets()
                } else {
                    // Optional: Hinweis anzeigen, falls Zugriff verweigert.
                }
            }
        }
    }
    
    /// Lädt entweder alle Bilder oder nur die Bilder aus dem übergebenen Album.
    func loadAssets() {
        var fetchedAssets: [PHAsset] = []
        let fetchOptions = PHFetchOptions()
        
        if let album = album {
            // Nur Bilder aus dem angegebenen Album laden
            let fetchResult = PHAsset.fetchAssets(in: album, options: fetchOptions)
            fetchResult.enumerateObjects { asset, _, _ in
                if !DatabaseManager.shared.isAssetKeptRecently(assetID: asset.localIdentifier) {
                    fetchedAssets.append(asset)
                }
            }
        } else {
            // Alle Bilder der Fotobibliothek laden
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            fetchResult.enumerateObjects { asset, _, _ in
                if !DatabaseManager.shared.isAssetKeptRecently(assetID: asset.localIdentifier) {
                    fetchedAssets.append(asset)
                }
            }
        }
        self.assets = fetchedAssets
    }
    
    func keepCurrentImage() {
        guard let currentAsset = assets.first else { return }
        // Speichere den "Behalten"-Status in der Datenbank
        DatabaseManager.shared.saveAsset(assetID: currentAsset.localIdentifier, date: Date())
        // Speichere das Asset zusätzlich in der aktuellen Session
        sessionKeptAssets.append(currentAsset)
        removeCurrentAsset()
    }
    
    func markCurrentImageForDeletion() {
        guard let currentAsset = assets.first else { return }
        
        // Ermittle die Dateigröße des Assets
        let fileSize = currentAsset.getFileSize()
        
        // Aktualisiere die Statistik und markiere das Asset als gelöscht
        DatabaseManager.shared.deleteAsset(assetID: currentAsset.localIdentifier, freedBytes: fileSize)
        
        pendingDeletion.append(currentAsset)
        removeCurrentAsset()
    }
    
    func removeCurrentAsset() {
        if let currentAsset = assets.first {
            imageCache.cache.removeValue(forKey: currentAsset.localIdentifier)
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
                    print("Batch-Löschung erfolgreich durchgeführt.")
                    assetsToDelete.forEach { asset in
                        self.imageCache.cache.removeValue(forKey: asset.localIdentifier)
                    }
                }
            } else {
                print("Fehler bei der Batch-Löschung: \(error?.localizedDescription ?? "Unbekannter Fehler")")
            }
        }
    }
    
    /// Stellt ein in der aktuellen Session als "Behalten" markiertes Bild wieder her.
    /// Es wird das zuletzt gespeicherte Bild (LIFO) verwendet.
    func restoreKeptImage() {
        guard let asset = sessionKeptAssets.popLast() else { return }
        // Entferne den "Behalten"-Status in der Datenbank für dieses Asset,
        // sodass es beim nächsten Laden nicht mehr herausgefiltert wird.
        DatabaseManager.shared.removeKeptAsset(assetID: asset.localIdentifier)
        // Füge das wiederhergestellte Asset an den Anfang des aktuellen Decks ein.
        assets.insert(asset, at: 0)
    }
}

extension PHAsset {
    /// Versucht die Dateigröße (in Bytes) des Assets zu ermitteln.
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
        ContentView(album: nil)
    }
}
