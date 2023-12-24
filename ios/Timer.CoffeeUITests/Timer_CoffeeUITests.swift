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

    @MainActor func testEN() throws {
        let app = XCUIApplication()
        app.launch()
        
                                            
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}
@MainActor func testDE() throws {
        let app = XCUIApplication()
        app.launch()
  
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

@MainActor func testES() throws {
            let app = XCUIApplication()
            app.launch()
      
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
}

