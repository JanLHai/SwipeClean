//
//  StartView.swift
//  SwipeClean
//
//  Created by Jan Haider on 01.02.25.
//

import SwiftUI

struct StartView: View {
    
    // State-Variablen für die Anzeige
    @State private var keptCount: Int = DatabaseManager.shared.keptImagesCount
    @State private var deletedCount: Int = DatabaseManager.shared.deletedCount
    @State private var freedSpace: Int64 = DatabaseManager.shared.freedSpace
    
    // Timer, der einmal pro Sekunde feuert
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                infoView
                Spacer()
                navigationButtons
                Spacer()
                
            }
            .padding(.top, 20)
            // Wir entfernen hier .navigationTitle, da wir einen eigenen Titel setzen
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Benutzerdefinierter Navigationstitel
                ToolbarItem(placement: .principal) {
                    Text("SwipeClean")
                        .font(.largeTitle.bold())
                    // Mit diesem Offset wird der Titel weiter oben angezeigt.
                }
                // Einstellungsbutton in der rechten oberen Ecke
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                            .offset(y: 5)
                            .imageScale(.large)
                            .padding()
                            .accessibilityLabel(Text("settingsButton"))
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // 1 Sekunde Verzögerung
                    deletedCount = DatabaseManager.shared.deletedCount
                    freedSpace = DatabaseManager.shared.freedSpace
                    keptCount = DatabaseManager.shared.keptImagesCount
                }
            }
        }.padding(.top, 10)
    }
    
    // Anzeige der Statistiken
    private var infoView: some View {
        VStack(spacing: 10) {
            Text("Behaltene Medien: \(keptCount)")
            Text("Gelöschte Medien: \(deletedCount)")
            Text("Freigeräumter Speicher: \(formattedFreedSpace(bytes: freedSpace))")
        }
        .padding([.top, .bottom])
    }
    
    // Navigation-Buttons als separate Gruppe
    private var navigationButtons: some View {
        VStack(spacing: 10) {
            NavigationLink(
                destination: ContentView(album: nil)
                    .navigationBarBackButtonHidden(true)
                    .navigationBarHidden(false)
            ) {
                Text("Aufräumen")
                    .buttonStyle(background: .blue)
            }
            
            NavigationLink(
                destination: GalleryFoldersView()
                    .navigationBarTitle("Ordner auswählen", displayMode: .inline)
            ) {
                Text("Ordner auswählen")
                    .buttonStyle(background: .green)
            }
        }
        .padding(.horizontal)
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

// Formatierungsfunktion für den freigeräumten Speicher
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
