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
        // Lade den Basis-Titel aus der Lokalisierung und hänge die Version an
        let baseTitle = NSLocalizedString("whatsNew_title", comment: "Basis-Titel für WhatsNew (ohne Version)")
        let fullTitle = "\(baseTitle) v. \(WhatsNewContent.version)"
        return .init(stringLiteral: fullTitle)
    }
    
    static var features: [WhatsNew.Feature] {
        [
            .init(
                image: .init(systemName: "icloud"),
                title: .init(stringLiteral: NSLocalizedString("whatsNew_feature1_title_v.1.1.0", comment: "iCloud Synchronisation")),
                subtitle: .init(stringLiteral: NSLocalizedString("whatsNew_feature1_subtitle_v.1.1.0", comment: "Es gibt nun die Möglichkeit, die Einstellungen und Daten über die Bilder mit iCloud zu synchronisieren"))
            ),
            .init(
                image: .init(systemName: "play.rectangle"),
                title: .init(stringLiteral: NSLocalizedString("whatsNew_feature2_title_v.1.1.0", comment: "Video Support")),
                subtitle: .init(stringLiteral: NSLocalizedString("whatsNew_feature2_subtitle_v.1.1.0", comment: "Sie können nun auch Videos ausmisten"))
            ),
            .init(
                image: .init(systemName: "speaker.slash"),
                title: .init(stringLiteral: NSLocalizedString("whatsNew_feature3_title_v.1.1.0", comment: "Lautstärke Stummschalten")),
                subtitle: .init(stringLiteral: NSLocalizedString("whatsNew_feature3_subtitle_v.1.1.0", comment: "Sie können nun in den Einstellungen entscheiden, ob Sie Töne stummschalten möchten"))
            ),
            .init(
                image: .init(systemName: "character.bubble"),
                title: .init(stringLiteral: NSLocalizedString("whatsNew_feature4_title_v.1.1.0", comment: "Zusätzliche Sprachen")),
                subtitle: .init(stringLiteral: NSLocalizedString("whatsNew_feature4_subtitle_v.1.1.0", comment: "Wir unterstützen nun auch neben der Deutschen die Englische, Französische, Italienische, Japanische, Koreanische, Portugiesische, Hindi, Spanisch, Chinesisch (vereinfacht) und Russische Sprache"))
            )
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
