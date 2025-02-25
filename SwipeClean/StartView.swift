//
//  StartView.swift
//  SwipeClean
//
//  Created by Jan Haider on 15.01.25.
//

import SwiftUI
import WhatsNewKit

struct StartView: View {
    
    // Statistiken aus der Database
    @State private var keptCount: Int = DatabaseManager.shared.keptImagesCount
    @State private var deletedCount: Int = DatabaseManager.shared.deletedCount
    @State private var freedSpace: Int64 = DatabaseManager.shared.freedSpace
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    infoView
                    Spacer()
                }
                navigationButtons
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .whatsNewSheet()
            }
            .padding(.top, 20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Clean my Gallery")
                        .font(.largeTitle.bold())
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                            .offset(y: 5)
                            .imageScale(.large)
                            .padding()
                            .accessibilityLabel(Text("settingsButton"))
                    }
                    .navigationTitle("zurück")
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    deletedCount = DatabaseManager.shared.deletedCount
                    freedSpace = DatabaseManager.shared.freedSpace
                    keptCount = DatabaseManager.shared.keptImagesCount
                }
                // Starte den CloudKit Sync
                CloudKitSyncManager.shared.startSync()
                
                // Bewertungsaufforderung nach 5 Sekunden, falls noch nicht bewertet
                DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                    AppManager.shared.requestReviewIfAppropriate()
                }
            }
            .onDisappear {
                CloudKitSyncManager.shared.stopSync()
            }
        }
        .padding(.top, 10)
    }
    
    private var infoView: some View {
        VStack(spacing: 10) {
            Text("Behaltene Medien: \(keptCount)")
            Text("Gelöschte Medien: \(deletedCount)")
            Text("Freigeräumter Speicher: \(formattedFreedSpace(bytes: freedSpace))")
        }
        .padding([.top, .bottom], 120)
        .opacity(0.75)
    }
    
    private var navigationButtons: some View {
        VStack(spacing: 10) {
            NavigationLink(
                destination: ContentView(album: nil, dateRange: nil, mediaTypeFilter: nil)
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
                    .buttonStyle(background: .gray.opacity(0.6))
            }
            NavigationLink(destination: DateRangeSelectionView()) {
                Text("Zeitraum auswählen")
                    .buttonStyle(background: .gray.opacity(0.6))
            }
            // Neuer Button für Medientyp-Filter
            NavigationLink(destination: MediaTypeSelectionView()) {
                Text("Medientyp wählen")
                    .buttonStyle(background: .gray.opacity(0.6))
            }
        }
    }
}

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
