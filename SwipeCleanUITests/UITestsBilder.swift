//
//  UITestBilder.swift
//  SwipeClean
//
//  Created by Jan Haider on 09.02.25.
//

import XCTest

final class UITestsBilder: XCTestCase {
    
    override func setUpWithError() throws {
        // Setup-Code, der vor jedem Test ausgeführt wird.
        continueAfterFailure = false
    }
    
    override func tearDownWithError() throws {
        // Teardown-Code, der nach jedem Test ausgeführt wird.
    }
    
    @MainActor
    func test01_SettingsResetDatabase() throws {
        let app = XCUIApplication()
        app.launch()
        
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Der 'settings'-Button sollte existieren")
        settingsButton.tap()
        
        let resetButton = app.buttons["Datenbank zurücksetzen"]
        XCTAssertTrue(resetButton.waitForExistence(timeout: 5), "Der 'Reset Datenbank'-Button sollte existieren")
        resetButton.tap()
        
        let deleteButton = app.buttons["Löschen"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "Der 'Löschen'-Button sollte existieren")
        deleteButton.tap()
        
        let slideOverMessage = app.staticTexts["slideOverMessage"]
        XCTAssertTrue(slideOverMessage.waitForExistence(timeout: 10), "Die SlideOverView sollte erscheinen")
        
        sleep(4) // Zeit für Animation + Verzögerung
        
        XCTAssertFalse(slideOverMessage.exists, "Die SlideOverView sollte nach 3 Sekunden wieder verschwinden")
        
        app.navigationBars.buttons.firstMatch.tap()
    }
    
    @MainActor
    func test02_AufraumenKeepImageBySwipingRightAndThenDeleting() throws {
        let app = XCUIApplication()
        app.launch()
        
        let nextButton = app.buttons["Aufräumen"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5), "Der 'Weiter'-Button sollte existieren")
        nextButton.tap()
        
        let assetImage = app.otherElements["assetImageView"]
        XCTAssertTrue(assetImage.waitForExistence(timeout: 5), "Das Asset-Image sollte erscheinen")
        
        let firstImageIdentifier = assetImage.label
        
        assetImage.swipeRight()
        
        var predicate = NSPredicate(format: "label != %@", firstImageIdentifier)
        expectation(for: predicate, evaluatedWith: assetImage, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        
        let getImageBackButton = app.buttons["Bild wiederherstellen"]
        XCTAssertTrue(assetImage.waitForExistence(timeout: 5), "Der Button zum Bild zurückholen sollte erscheinen")
        
        let secondImageIdentifier = assetImage.label
        
        getImageBackButton.tap()
        
        predicate = NSPredicate(format: "label = %@", firstImageIdentifier)
        expectation(for: predicate, evaluatedWith: assetImage, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        
        assetImage.swipeRight()
        
        predicate = NSPredicate(format: "label = %@", secondImageIdentifier)
        expectation(for: predicate, evaluatedWith: assetImage, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        
        let deleteButton = app.buttons["Löschen"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "Der Löschen-Button sollte vorhanden sein")
        deleteButton.tap()
        
        let predicateAfterDelete = NSPredicate(format: "label != %@", secondImageIdentifier)
        expectation(for: predicateAfterDelete, evaluatedWith: assetImage, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    @MainActor
    func test03_OrdnerKeepImageBySwipingRightAndThenDeleting() throws {
        let app = XCUIApplication()
        app.launch()
        
        let nextButton = app.buttons["Ordner auswählen"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5), "Der 'Ordner Auswählen'-Button sollte existieren")
        nextButton.tap()
        
        let galleryNavBar = app.navigationBars["Galerie Ordner"]
        XCTAssertTrue(galleryNavBar.waitForExistence(timeout: 5), "Die Galerie-Ansicht sollte geladen sein")
        
        let albumGrid = app.scrollViews.firstMatch
        XCTAssertTrue(albumGrid.waitForExistence(timeout: 5), "Der Album-Grid sollte existieren")
        
        let firstAlbumCell = albumGrid.buttons.firstMatch
        XCTAssertTrue(firstAlbumCell.waitForExistence(timeout: 5), "Der erste Ordner sollte existieren")
        firstAlbumCell.tap()
        
        let assetImage = app.otherElements["assetImageView"]
        XCTAssertTrue(assetImage.waitForExistence(timeout: 5), "Das Asset-Image sollte erscheinen")
        
        let firstImageIdentifier = assetImage.label
        
        assetImage.swipeRight()
        
        var predicate = NSPredicate(format: "label != %@", firstImageIdentifier)
        expectation(for: predicate, evaluatedWith: assetImage, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        
        let getImageBackButton = app.buttons["Bild wiederherstellen"]
        XCTAssertTrue(assetImage.waitForExistence(timeout: 5), "Der Button zum Bild zurückholen sollte erscheinen")
        
        let secondImageIdentifier = assetImage.label
        
        getImageBackButton.tap()
        
        predicate = NSPredicate(format: "label = %@", firstImageIdentifier)
        expectation(for: predicate, evaluatedWith: assetImage, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        
        assetImage.swipeRight()
        
        predicate = NSPredicate(format: "label = %@", secondImageIdentifier)
        expectation(for: predicate, evaluatedWith: assetImage, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        
        let deleteButton = app.buttons["Löschen"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "Der Löschen-Button sollte vorhanden sein")
        deleteButton.tap()
        
        let predicateAfterDelete = NSPredicate(format: "label != %@", secondImageIdentifier)
        expectation(for: predicateAfterDelete, evaluatedWith: assetImage, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    @MainActor
    func test04_DateRangeSelectionAndContentView() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Starte von der StartView und tippe auf "Zeitraum auswählen"
        let dateRangeButton = app.buttons["Zeitraum auswählen"]
        XCTAssertTrue(dateRangeButton.waitForExistence(timeout: 5), "Der 'Zeitraum auswählen'-Button sollte existieren")
        dateRangeButton.tap()
        
        // Überprüfe, ob die Datumsauswahl-Seite erscheint
        let dateRangeNavBar = app.navigationBars["Zeitraum auswählen"]
        XCTAssertTrue(dateRangeNavBar.waitForExistence(timeout: 5), "Die Datumsauswahl-Seite sollte geladen sein")
        
        // Prüfe, ob die Labels "Von:" und "Bis:" vorhanden sind
        let vonLabel = app.staticTexts["Von:"]
        let bisLabel = app.staticTexts["Bis:"]
        XCTAssertTrue(vonLabel.waitForExistence(timeout: 5), "Das 'Von:'-Label sollte existieren")
        XCTAssertTrue(bisLabel.waitForExistence(timeout: 5), "Das 'Bis:'-Label sollte existieren")
        
        // Bestätige die Auswahl
        let confirmButton = app.buttons["Bestätigen"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5), "Der 'Bestätigen'-Button sollte existieren")
        confirmButton.tap()
        
        // Nach Bestätigung sollte die ContentView erscheinen – überprüfe das Asset-Image
        let assetImage = app.otherElements["assetImageView"]
        XCTAssertTrue(assetImage.waitForExistence(timeout: 5), "Das Asset-Image sollte nach der Datumsauswahl erscheinen")
        
        // Tippe auf den "Fertig"-Button in der ContentView, um zur StartView zurückzukehren.
        let fertigButton = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Fertig'")).firstMatch
        XCTAssertTrue(fertigButton.waitForExistence(timeout: 5), "Der 'Fertig'-Button sollte existieren")
        fertigButton.tap()
        
        // Überprüfe, ob wir zurück in der StartView sind (z. B. durch das Vorhandensein des "Aufräumen"-Buttons)
        let aufraeumenButton = app.buttons["Aufräumen"]
        XCTAssertTrue(aufraeumenButton.waitForExistence(timeout: 5), "Nach 'Fertig' sollte man zur StartView zurückkehren")
    }
    
    @MainActor
    func test05_SharingFunctionality() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigiere zum Aufräumen-Screen, wo Bilder angezeigt werden
        let aufraumenButton = app.buttons["Aufräumen"]
        XCTAssertTrue(aufraumenButton.waitForExistence(timeout: 5), "Der 'Aufräumen'-Button sollte existieren")
        aufraumenButton.tap()
        
        // Warte, bis ein Asset angezeigt wird
        let assetView = app.otherElements["assetMediaView"]
        XCTAssertTrue(assetView.waitForExistence(timeout: 5), "Das Asset sollte angezeigt werden")
        
        // Überprüfe, ob der Teilen-Button in der Navigationsleiste existiert
        // Hinweis: Da der Button ein Bild ist, identifizieren wir ihn über das Accessibility-Label "Teilen"
        let shareButton = app.buttons["Teilen"]
        XCTAssertTrue(shareButton.waitForExistence(timeout: 5), "Der Teilen-Button sollte in der Navigationsleiste existieren")
        
        // Der Teilen-Button sollte aktiviert sein, da wir ein Asset haben
        XCTAssertTrue(shareButton.isEnabled, "Der Teilen-Button sollte aktiviert sein, wenn Assets vorhanden sind")
        
        // Speichere die aktuelle Asset-ID, um später zu prüfen, ob sich nichts geändert hat
        let currentAssetId = assetView.label
        
        // Tippe auf den Teilen-Button
        shareButton.tap()
        
        // Warte kurz, damit das Share-Sheet angezeigt werden kann
        sleep(1)
        
        // Auf iOS können wir das Share-Sheet auf verschiedene Weise identifizieren
        // Versuche zuerst mit ActivityListView
        let activitySheet = app.otherElements["ActivityListView"]
        if activitySheet.exists {
            // Wenn das Activity Sheet als Element verfügbar ist
            XCTAssertTrue(activitySheet.waitForExistence(timeout: 3.0), "Das Share-Sheet sollte angezeigt werden")
            
            // Finde den Abbrechen-Button und tippe darauf
            // Versuche zunächst mit der englischen Lokalisierung
            var cancelButton = app.buttons["Cancel"]
            if !cancelButton.exists {
                // Falls englische Lokalisierung nicht funktioniert, versuche deutsche
                cancelButton = app.buttons["Abbrechen"]
            }
            
            XCTAssertTrue(cancelButton.waitForExistence(timeout: 2.0), "Der Abbrechen-Button sollte im Share-Sheet sichtbar sein")
            cancelButton.tap()
        } else {
            // Alternative Überprüfung, falls die ActivityListView nicht direkt identifizierbar ist
            // Prüfe auf typische Share-Sheet-Elemente wie CollectionViews oder Sheets
            let shareOptions = app.sheets.firstMatch
            if shareOptions.exists {
                XCTAssertTrue(shareOptions.waitForExistence(timeout: 3.0), "Ein Sheet sollte angezeigt werden")
                
                // Versuche verschiedene Optionen für den Abbrechen-Button
                var cancelButton = app.buttons["Cancel"]
                if !cancelButton.exists {
                    cancelButton = app.buttons["Abbrechen"]
                }
                
                if cancelButton.exists {
                    cancelButton.tap()
                } else {
                    // Wenn kein spezifischer Abbrechen-Button gefunden wird, tippe außerhalb des Sheets
                    // oder verwende den ersten Button in der Navigation Bar
                    app.navigationBars.buttons.firstMatch.tap()
                }
            } else {
                // Wenn weder ActivityListView noch Sheet gefunden wird, nimm an, dass sich das Share-Sheet nicht richtig geöffnet hat
                XCTFail("Das Share-Sheet wurde nicht ordnungsgemäß angezeigt")
            }
        }
        
        // Warte kurz, bis das Share-Sheet geschlossen wurde
        sleep(1)
        
        // Stelle sicher, dass wir wieder zum Asset-View zurückkehren und das gleiche Asset angezeigt wird
        XCTAssertTrue(assetView.waitForExistence(timeout: 3.0), "Nach dem Schließen des Share-Sheets sollte der Asset-View wieder sichtbar sein")
        XCTAssertEqual(assetView.label, currentAssetId, "Nach dem Teilen sollte das gleiche Asset angezeigt werden")
    }
}
