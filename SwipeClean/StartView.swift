import SwiftUI

struct StartView: View {
    
    // Statistiken aus der Database
    @State private var keptCount: Int = DatabaseManager.shared.keptImagesCount
    @State private var deletedCount: Int = DatabaseManager.shared.deletedCount
    @State private var freedSpace: Int64 = DatabaseManager.shared.freedSpace
    
    var body: some View {
        NavigationView {
            ZStack {
                // Obere Inhalte bleiben oben
                VStack {
                    infoView
                    Spacer()
                }
                // Navigation-Buttons sind unten verankert.
                navigationButtons
                    .padding(.horizontal)
                    .padding(.bottom, 20) // Abstand zum unteren Rand (anpassbar)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .padding(.top, 20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Titel
                ToolbarItem(placement: .principal) {
                    Text("SwipeClean")
                        .font(.largeTitle.bold())
                }
                // Einstellungen
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                            .offset(y: 5)
                            .imageScale(.large)
                            .padding()
                            .accessibilityLabel(Text("settingsButton"))
                    }.navigationTitle("zurück")
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    deletedCount = DatabaseManager.shared.deletedCount
                    freedSpace = DatabaseManager.shared.freedSpace
                    keptCount = DatabaseManager.shared.keptImagesCount
                }
            }
        }
        .padding(.top, 10)
    }
    
    // Anzeige der Statistiken
    private var infoView: some View {
        VStack(spacing: 10) {
            Text("Behaltene Medien: \(keptCount)")
            Text("Gelöschte Medien: \(deletedCount)")
            Text("Freigeräumter Speicher: \(formattedFreedSpace(bytes: freedSpace))")
        }
        .padding([.top, .bottom], 120)
        .opacity(0.75)
    }
    
    // Navigation-Buttons
    private var navigationButtons: some View {
        VStack(spacing: 10) {
            // "Aufräumen" – ohne Filter (wie bisher)
            NavigationLink(
                destination: ContentView(album: nil, dateRange: nil)
                    .navigationBarBackButtonHidden(true)
                    .navigationBarHidden(false)
            ) {
                Text("Aufräumen")
                    .buttonStyle(background: .blue)
            }
            
            // "Ordner auswählen"
            NavigationLink(
                destination: GalleryFoldersView()
                    .navigationBarTitle("Ordner auswählen", displayMode: .inline)
            ) {
                Text("Ordner auswählen")
                    .buttonStyle(background: .gray.opacity(0.6))
            }
            
            // "Zeitraum auswählen" – führt zuerst zur Datumsauswahl
            NavigationLink(destination: DateRangeSelectionView()) {
                Text("Zeitraum auswählen")
                    .buttonStyle(background: .gray.opacity(0.6))
            }
        }
    }
}

// Custom Button Modifier
extension View {
    func buttonStyle(background: Color) -> some View {
        self
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(background)
            .cornerRadius(10)
    }
}

// Formatierung des freigehaltenen Speichers
func formattedFreedSpace(bytes: Int64) -> String {
    let mb = Double(bytes) / (1024 * 1024)
    let gb = mb / 1024
    if gb >= 1.0 {
        return String(format: "%.2f GB", gb)
    } else {
        return String(format: "%.2f MB", mb)
    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView()
    }
}
