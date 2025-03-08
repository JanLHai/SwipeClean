//
//  WhatsNewContent.swift
//  SwipeClean
//
//  Created by Jan Haider on 16.02.25.
//

import Foundation
import WhatsNewKit

struct WhatsNewContent {
    // Aktuelle Version
    static var version: WhatsNew.Version {
        .init(stringLiteral: "1.2.1")
    }
    
    // Titel mit dynamischer Version
    static var title: WhatsNew.Title {
        // Lade den Basis-Titel aus der Lokalisierung und hänge die Version an
        let baseTitle = NSLocalizedString("whatsNew_title", comment: "Basis-Titel für WhatsNew (ohne Version)")
        let fullTitle = "\(baseTitle) v. \(WhatsNewContent.version)"
        return .init(stringLiteral: fullTitle)
    }
    
    static var features: [WhatsNew.Feature] {
        [
            .init(
                image: .init(systemName: "plus.magnifyingglass"),
                title: .init(stringLiteral: NSLocalizedString("whatsNew_feature1_title", comment: "Zoom-Funktion")),
                subtitle: .init(stringLiteral: NSLocalizedString("whatsNew_feature1_subtitle", comment: "Mann kann nun bei Bildern mit der üblichen Geste zoomen"))
            ),
            .init(
                image: .init(systemName: "square.and.arrow.up"),
                title: .init(stringLiteral: NSLocalizedString("whatsNew_feature2_title", comment: "Share Media")),
                subtitle: .init(stringLiteral: NSLocalizedString("whatsNew_feature2_subtitle", comment: "Es ist nun möglich Medien direkt aus der App an Kontakte zu teilen"))
            ),
            .init(
                image: .init(systemName: "heart"),
                title: .init(stringLiteral: NSLocalizedString("whatsNew_feature3_title", comment: "Als Favorit markieren")),
                subtitle: .init(stringLiteral: NSLocalizedString("whatsNew_feature3_subtitle", comment: "Man kann nun auswählen ob ein Bild auch in der Gallery als Favorit angezeigt werden soll"))
            ),
            .init(
                image: .init(systemName: "character.bubble.ar"),
                title: .init(stringLiteral: NSLocalizedString("whatsNew_feature4_title", comment: "Zusätzliche Sprache Arabisch")),
                subtitle: .init(stringLiteral: NSLocalizedString("whatsNew_feature4_subtitle", comment: "Wir unterstützen nun auch neben den bisherigen Sprachen die Arabische Sprache"))
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
