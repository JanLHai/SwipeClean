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
                        versionStore: InMemoryWhatsNewVersionStore(),
                        whatsNewCollection: self
                    )
                )
        }
    }
}

// MARK: - App+WhatsNewCollectionProvider

extension SwipeCleanApp: WhatsNewCollectionProvider {
    var whatsNewCollection: WhatsNewCollection {
        WhatsNew(
            version: WhatsNewContent.version,
            title: WhatsNewContent.title,
            features: WhatsNewContent.features,
            primaryAction: WhatsNewContent.primaryAction
        )
    }
}
