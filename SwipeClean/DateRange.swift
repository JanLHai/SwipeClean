//
//  DateRangeSelectionView.swift
//  SwipeClean
//
//  Created by Jan Haider on [Datum].
//

import SwiftUI
import Photos

/// Typ zur Übergabe eines Datumsbereichs
struct DateRange: Equatable, Hashable {
    let start: Date
    let end: Date
}

struct DateRangeSelectionView: View {
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var isLoading: Bool = true
    @State private var navigateToContentView: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Zeitraum auswählen")
                .font(.title)
                .padding()
            
            if isLoading {
                ProgressView("Lade ältestes Datum...")
            } else {
                Form {
                    DatePicker("Von:", selection: $startDate, displayedComponents: .date)
                    DatePicker("Bis:", selection: $endDate, in: startDate...Date(), displayedComponents: .date)
                }
            }
            
            // Unsichtbarer NavigationLink, der beim Bestätigen aktiviert wird
            NavigationLink(
                destination: ContentView(album: nil, dateRange: DateRange(start: startDate, end: endDate))
                    .navigationBarBackButtonHidden(true)
                    .navigationBarHidden(false),
                isActive: $navigateToContentView
            ) {
                EmptyView()
            }
            
            Button(action: {
                if startDate <= endDate {
                    navigateToContentView = true
                }
            }) {
                Text("Bestätigen")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background((startDate <= endDate) ? Color.blue : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(startDate > endDate || isLoading)
            .padding()
            
            Spacer()
        }
        .onAppear(perform: fetchOldestDate)
        .navigationBarTitle("Zeitraum auswählen", displayMode: .inline)
    }
    
    private func fetchOldestDate() {
        let fetchResult = PHAsset.fetchAssets(with: .image, options: nil)
        var oldest: Date? = nil
        
        fetchResult.enumerateObjects { asset, _, _ in
            if let creationDate = asset.creationDate {
                if oldest == nil || creationDate < oldest! {
                    oldest = creationDate
                }
            }
        }
        
        DispatchQueue.main.async {
            if let oldestDate = oldest {
                startDate = oldestDate
            } else {
                startDate = Date()
            }
            endDate = Date()
            isLoading = false
        }
    }
}

struct DateRangeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DateRangeSelectionView()
        }
    }
}
