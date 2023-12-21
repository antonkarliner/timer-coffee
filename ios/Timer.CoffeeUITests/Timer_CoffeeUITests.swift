//
//  Timer_CoffeeUITests.swift
//  Timer.CoffeeUITests
//
//  Created by Anton Karliner on 18.12.2023.
//

import XCTest

final class Timer_CoffeeUITests: XCTestCase {

    @MainActor override func setUpWithError() throws {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor func testExample() throws {
        let app = XCUIApplication()
        app.launch()

        let aeropressStaticText = app.staticTexts["Aeropress"]
              aeropressStaticText.tap()

    // The remaining elements are still accessed by their text.
    let timWendelboeAeropressRecipeElement = app.otherElements["Tim Wendelboe Aeropress recipe"]
    timWendelboeAeropressRecipeElement.tap()
    
    let backButton = app.buttons["Back"]
    backButton.tap()
    backButton.tap()
    snapshot("01Home")
    
        aeropressStaticText.tap()  // Tapping the Aeropress list item again
    snapshot("02Recipelist")
    
    timWendelboeAeropressRecipeElement.tap()
    app.textFields["Coffee amount (g)"].tap()
    snapshot("03Recipedetail")
    
    let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 1)
    element.children(matching: .other).element(boundBy: 1).children(matching: .button).element.tap()
    snapshot("04Preparation")
    element.children(matching: .button).element(boundBy: 1).tap()
    snapshot("05Brewing")
    
    backButton.tap()
    backButton.tap()
    backButton.tap()
    backButton.tap()
    
    app.buttons["Settings"].tap()
    app.staticTexts["Theme\nSystem"].tap()
    app.staticTexts["Dark"].tap()
    snapshot("06Darktheme")
    app.staticTexts["Theme\nDark"].tap()
    app.staticTexts["Light"].tap()
    app.staticTexts["Language\nEnglish"].tap()
    snapshot("07Languages")
    app.staticTexts["Scrim"].tap()
    backButton.tap()
    
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}
@MainActor func testExample2() throws {
        let app = XCUIApplication()
        app.launch()
    
    let aeropressStaticText = app.staticTexts["Aeropress"]
    aeropressStaticText.tap()
    
    let timWendelboeAeropressRezeptElement = app.otherElements["Tim Wendelboe Aeropress Rezept"]
    timWendelboeAeropressRezeptElement.tap()
    
    let zurCkButton = app.buttons["Zurück"]
    zurCkButton.tap()
    zurCkButton.tap()
    snapshot("01Home")
    aeropressStaticText.tap()
    snapshot("02Recipelist")
    timWendelboeAeropressRezeptElement.tap()
    app.textFields["Kaffeemenge (g)"].tap()
    snapshot("03Recipedetail")
    
    let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 1)
    element.children(matching: .other).element(boundBy: 1).children(matching: .button).element.tap()
    snapshot("04Preparation")
    element.children(matching: .button).element(boundBy: 1).tap()
    snapshot("05Brewing")
    zurCkButton.tap()
    zurCkButton.tap()
    zurCkButton.tap()
    zurCkButton.tap()
    app.buttons["Settings"].tap()
    app.staticTexts["Thema\nSystem"].tap()
    app.staticTexts["Dunkel"].tap()
    snapshot("06Darktheme")
    app.staticTexts["Thema\nDunkel"].tap()
    app.staticTexts["Hell"].tap()
    app.staticTexts["Sprache\nDeutsch"].tap()
    snapshot("07Languages")
    app.staticTexts["Gitter"].tap()
    zurCkButton.tap()
            

    
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}
}

