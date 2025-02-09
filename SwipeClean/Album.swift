import SwiftUI
import Photos

// Modell für ein Album
struct Album: Identifiable {
    let id: String
    let title: String
    let coverImage: UIImage?
    let assetCollection: PHAssetCollection
}

// ViewModel, das die Alben aus der Fotobibliothek lädt
class GalleryFoldersViewModel: ObservableObject {
    @Published var albums: [Album] = []
    
    init() {
        // Fotobibliothek-Berechtigung anfordern
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized || status == .limited {
                self.fetchAlbums()
            } else {
                // Hier kannst du den Fall behandeln, wenn der Zugriff verweigert wurde.
                print("Zugriff auf die Fotobibliothek wurde verweigert.")
            }
        }
    }
    
    private func fetchAlbums() {
        var albumList: [Album] = []
        // Optionale Fetch-Optionen (hier z. B. keine spezielle Filterung)
        let fetchOptions = PHFetchOptions()
        // Alle Benutzer-Alben abrufen
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        collections.enumerateObjects { (collection, _, _) in
            // Für jedes Album versuchen wir, das erste Asset als Coverbild zu verwenden.
            let assets = PHAsset.fetchAssets(in: collection, options: nil)
            var coverImage: UIImage? = nil
            if let asset = assets.firstObject {
                let imageManager = PHImageManager.default()
                let options = PHImageRequestOptions()
                options.isSynchronous = true
                options.deliveryMode = .highQualityFormat
                // Hier wird synchron das Bild abgerufen (für den einfachen Code)
                imageManager.requestImage(
                    for: asset,
                    targetSize: CGSize(width: 150, height: 150),
                    contentMode: .aspectFill,
                    options: options
                ) { image, _ in
                    coverImage = image
                }
            }
            
            let album = Album(
                id: collection.localIdentifier,
                title: collection.localizedTitle ?? "Unbekannt",
                coverImage: coverImage,
                assetCollection: collection
            )
            albumList.append(album)
        }
        
        DispatchQueue.main.async {
            self.albums = albumList
        }
    }
}

// Hauptansicht, die alle Alben in einem Grid anzeigt
struct GalleryFoldersView: View {
    @StateObject private var viewModel = GalleryFoldersViewModel()
    
    // Zwei Spalten im Grid
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.albums) { album in
                    NavigationLink(destination: destinationView(for: album)) {
                        VStack {
                            // Coverbild anzeigen oder einen Platzhalter, falls kein Bild vorhanden ist
                            if let uiImage = album.coverImage {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 150, height: 150)
                                    .clipped()
                                    .cornerRadius(8)
                            } else {
                                Rectangle()
                                    .fill(Color.gray)
                                    .frame(width: 150, height: 150)
                                    .cornerRadius(8)
                                    .overlay(
                                        Text("Kein Bild")
                                            .foregroundColor(.white)
                                    )
                            }
                            
                            // Albumtitel
                            Text(album.title)
                                .font(.headline)
                                .lineLimit(1)
                                .padding(.top, 4)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Galerie Ordner")
    }
    
    /// Gibt die Ziel-View für ein Album zurück.
    @ViewBuilder
    private func destinationView(for album: Album) -> some View {
        // Hier wird die ContentView mit dem Album als Parameter aufgerufen.
        ContentView(album: album.assetCollection)
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(false)
    }
}

// Preview
struct GalleryFoldersView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GalleryFoldersView()
        }
    }
}
