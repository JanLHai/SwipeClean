//
//  AppManager.swift
//  SwipeClean
//
//  Created by Jan Haider on 16.02.25.
//


import SwiftUI
import StoreKit 

final class AppManager: ObservableObject {
    static let shared = AppManager()
    
    @AppStorage("hasRated") var hasRated: Bool = false
    
    private init() { }
    
    /// Fordert den nativen Bewertungsdialog an, falls noch nicht bewertet wurde.
    func requestReviewIfAppropriate() {
        guard !hasRated else { return }
        // Versuche die aktuelle UIWindowScene zu ermitteln.
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
            // Setze den Flag, damit der Dialog nicht wiederholt angezeigt wird.
            hasRated = true
        }
    }
}
