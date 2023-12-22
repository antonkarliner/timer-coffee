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
        // UI tests must launch the application that they test.
        
        
        let app = XCUIApplication()
        app.launch()
        app.alerts["Sign in with Apple ID"].scrollViews.otherElements.buttons["Cancel"].tap()
        
        let aeropressStaticText = app.staticTexts["Aeropress"]
        aeropressStaticText.tap()
        
        let timWendelboeAeropressRecipeElement = app.otherElements["Tim Wendelboe Aeropress recipe"]
        timWendelboeAeropressRecipeElement.tap()
        
        let backButton = app.buttons["Back"]
        backButton.tap()
        backButton.tap()
        snapshot("01Home")
        aeropressStaticText.tap()
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

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
