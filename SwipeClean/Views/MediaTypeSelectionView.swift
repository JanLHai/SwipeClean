//
//  MediaTypeSelectionView.swift
//  SwipeClean
//
//  Created by Jan Haider on 16.02.25.
//


import SwiftUI

struct MediaTypeSelectionView: View {
    var body: some View {
        VStack {
            Spacer() // Obere Lücke
            
            VStack(spacing: 20) {
                // Button für normale Bilder (ohne LivePhotos)
                NavigationLink(
                    destination: ContentView(album: nil, dateRange: nil, mediaTypeFilter: [0])
                        .navigationBarBackButtonHidden(true)
                        .navigationBarHidden(false)
                ) {
                    Text("Bilder")
                        .buttonStyle(background: .blue)
                }
                
                // Button für LivePhotos
                NavigationLink(
                    destination: ContentView(album: nil, dateRange: nil, mediaTypeFilter: [1])
                        .navigationBarBackButtonHidden(true)
                        .navigationBarHidden(false)
                ) {
                    Text("LivePhotos")
                        .buttonStyle(background: .blue)
                }
                
                // Button für Videos
                NavigationLink(
                    destination: ContentView(album: nil, dateRange: nil, mediaTypeFilter: [2])
                        .navigationBarBackButtonHidden(true)
                        .navigationBarHidden(false)
                ) {
                    Text("Videos")
                        .buttonStyle(background: .blue)
                }
            }
            
            Spacer() // Untere Lücke
        }
        .padding()
        .navigationTitle("Medientyp wählen")
    }
}

struct MediaTypeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MediaTypeSelectionView()
        }
    }
}
