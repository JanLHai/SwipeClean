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
        
        // Überprüfe, ob wir zurück in der StartView sind (z. B. durch das Vorhandensein des "Aufräumen"-Buttons)
        let aufraeumenButton = app.buttons["Aufräumen"]
        XCTAssertTrue(aufraeumenButton.waitForExistence(timeout: 5), "Nach 'Fertig' sollte man zur StartView zurückkehren")
    }
}
