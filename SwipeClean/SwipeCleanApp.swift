//
//  SwipeCleanApp.swift
//  SwipeClean
//
//  Created by Jan Haider on 15.01.25.
//

import SwiftUI
import WhatsNewKit

@main
struct SwipeCleanApp: App {
    var body: some Scene {
        WindowGroup {
            StartView()
                .environment(
                \.whatsNew,
                WhatsNewEnvironment(
                    // Specify in which way the presented WhatsNew Versions are stored.
                    // zum entwikeln kann man diesen Modus verwenden InMemoryWhatsNewVersionStore
                    // In default the `UserDefaultsWhatsNewVersionStore` is used.
                    versionStore: InMemoryWhatsNewVersionStore(),
                    // Pass a `WhatsNewCollectionProvider` or an array of WhatsNew instances
                    whatsNewCollection: self
                )
            )
        }
    }
}

// MARK: - App+WhatsNewCollectionProvider

extension SwipeCleanApp: WhatsNewCollectionProvider {

    /// Declare your WhatsNew instances per version
    var whatsNewCollection: WhatsNewCollection {
        WhatsNew(
            // The Version that relates to the features you want to showcase
            version: "1.1.0",
            // The title that is shown at the top
            title: "Was ist neu in Swipe Clean v. 1.1.0",
            // The features you want to showcase
            features: [
                WhatsNew.Feature(
                    image: .init(systemName: "icloud"),
                    title: "iCloud Synchronisation",
                    subtitle: "Es gibt nun die möglichkeit die Einstellungen und Daten über die Bilder mit iCloud zu synchronisieren"
                ),
                WhatsNew.Feature(
                    image: .init(systemName: "play.rectangle"),
                    title: "Video Support",
                    subtitle: "Sie könen nun auch Videos Ausmisten"
                ),
                WhatsNew.Feature(
                    image: .init(systemName: "speaker.slash"),
                    title: "Lautsärke Stummschalten",
                    subtitle: "Sie können nun in den Einstellungen entscheiden ob Sie Töne stummschalten möchten"
                ),
                WhatsNew.Feature(
                    image: .init(systemName: "character.bubble"),
                    title: "Zusätzliche Sprachen",
                    subtitle: "Wir unterstützen nun auch neben der Deutschen die Englische, Französch, Italienisch, Japanisch, Koreanisch, Portugiesisch, Hindi, Spanisch, Chinesisch (vereinfacht) und Russisch Sprache"
                ),
            ],
            
            // The primary action that is used to dismiss the WhatsNewView
            primaryAction: WhatsNew.PrimaryAction(
                title: "Weiter",
                backgroundColor: .blue,
                foregroundColor: .white,
                hapticFeedback: .notification(.success),
                onDismiss: {
                    print("WhatsNewView has been dismissed")
                }
                
            )
            
        )
    }

}
