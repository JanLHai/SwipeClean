//
//  UITestBilder.swift
//  SwipeClean
//
//  Created by Jan Haider on 09.02.25.
//

import XCTest

final class UITestsBilder: XCTestCase {
    
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
    func test01_SettingsResetDatabase() throws {
        let app = XCUIApplication()
        app.launch()
        
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Der 'settings'-Button sollte existieren")
        settingsButton.tap()
        
        let resetButton = app.buttons["Reset Datenbank"]
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
        XCTAssertTrue(assetImage.waitForExistence(timeout: 5), "Der butten zum bild zurückholen sollte erscheinen")
        
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
        XCTAssertTrue(assetImage.waitForExistence(timeout: 5), "Der butten zum bild zurückholen sollte erscheinen")
        
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
}
