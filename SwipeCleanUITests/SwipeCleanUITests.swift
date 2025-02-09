//
//  SwipeCleanUITests.swift
//  SwipeCleanUITests
//
//  Created by Jan Haider on 15.01.25.
//

import XCTest

final class SwipeCleanUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    @MainActor
    func testKeepImageBySwipingRightAndThenDeletingNewImage() throws {
            let app = XCUIApplication()
            app.launch()
        
            let nextButton = app.buttons["Aufräumen"]
            XCTAssertTrue(nextButton.waitForExistence(timeout: 5), "Der 'Weiter'-Button sollte existieren")
            nextButton.tap()
            
            // Warten, bis das Asset-Image erscheint.
            // Voraussetzung: Du hast in deinem AssetImageView z. B. folgendes gesetzt:
            // .accessibilityIdentifier("assetImageView")
            let assetImage = app.otherElements["assetImageView"]
            XCTAssertTrue(assetImage.waitForExistence(timeout: 5), "Das Asset-Image sollte erscheinen")
            
            // Speichern der aktuellen Bild-Identifikation.
            // Voraussetzung: In deiner App wird der currentAsset.localIdentifier
            // als Accessibility-Label oder -Identifier des AssetImageViews gesetzt.
            let firstImageIdentifier = assetImage.label
            
            // --- Schritt 1: Swipe-Geste zum Behalten des Bildes simulieren ---
            // (Da im Code keepCurrentImage() bei einem positiven (rechten) Swipe aufgerufen wird,
            // simulieren wir einen Rechts-Swipe.)
            assetImage.swipeRight()
            
            // --- Schritt 2: Überprüfen, dass ein neues Bild erscheint ---
            // Es wird erwartet, dass der Identifier des AssetImageViews sich ändert,
            // wenn das erste Bild entfernt wurde.
            let predicate = NSPredicate(format: "label != %@", firstImageIdentifier)
            expectation(for: predicate, evaluatedWith: assetImage, handler: nil)
            waitForExpectations(timeout: 5, handler: nil)
            
            // Optional: Den neuen Identifier zwischenspeichern
            let secondImageIdentifier = assetImage.label
            
            // --- Schritt 3: Neues Bild löschen ---
            // Wir simulieren das Tippen auf den "Löschen"-Button.
            let deleteButton = app.buttons["Löschen"]
            XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "Der Löschen-Button sollte vorhanden sein")
            deleteButton.tap()
            
            // Nach dem Löschen wird der neue Bild-Container (wieder) aktualisiert.
            // Es wird erwartet, dass sich der Identifier erneut ändert.
            let predicateAfterDelete = NSPredicate(format: "label != %@", secondImageIdentifier)
            expectation(for: predicateAfterDelete, evaluatedWith: assetImage, handler: nil)
            waitForExpectations(timeout: 5, handler: nil)
        }
}
