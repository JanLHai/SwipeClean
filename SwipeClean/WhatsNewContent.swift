//
//  WhatsNewContent.swift
//  SwipeClean
//
//  Created by Jan Haider on 16.02.25.
//


import Foundation
import WhatsNewKit

struct WhatsNewContent {
    static var version: WhatsNew.Version {
        .init(stringLiteral: "1.1.0")
    }
    
    static var title: WhatsNew.Title {
        .init(stringLiteral: NSLocalizedString("Was ist neu in Swipe Clean v. 1.1.0", comment: "Titel für WhatsNew"))
    }
    
    static var features: [WhatsNew.Feature] {
        [
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
                    ]
    }
    
    static var primaryAction: WhatsNew.PrimaryAction {
        .init(
            title: .init(stringLiteral: NSLocalizedString("whatsNew_primaryAction", comment: "Titel des Primary Action Buttons")),
            backgroundColor: .blue,
            foregroundColor: .white,
            hapticFeedback: .notification(.success),
            onDismiss: {
                print("WhatsNewView has been dismissed")
            }
        )
    }
}
