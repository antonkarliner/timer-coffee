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
    
    
    


    @MainActor func testRecipe() throws {
            let app = XCUIApplication()
            app.launch()
            
            Thread.sleep(forTimeInterval: 3)
            snapshot("01Home")
            app/*@START_MENU_TOKEN@*/.staticTexts["brewingMethod_v60"]/*[[".staticTexts[\"Hario V60\\nHario V60\"]",".staticTexts[\"brewingMethod_v60\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
            snapshot("02Recipelist")
            app.otherElements["recipeListItem_101"].tap()
            app.textFields["coffeeAmountField"].tap()
            snapshot("03Recipedetail")
            app/*@START_MENU_TOKEN@*/.staticTexts["recipeSummary"]/*[[".staticTexts[\"Recipe summary\\nNote: this is a basic recipe with default water and coffee amounts.\"]",".staticTexts[\"recipeSummary\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
            
            app.buttons["nextButton"].tap()
            snapshot("04Preparation")
            
            // Use XCTAssert and related functions to verify your tests produce the correct results.
        }

    
    @MainActor func testBeans() throws {
            let app = XCUIApplication()
        app.launch()
        Thread.sleep(forTimeInterval: 2)
        app/*@START_MENU_TOKEN@*/.staticTexts["tabItem_1"]/*[[".staticTexts[\"More\\nMore\"]",".staticTexts[\"tabItem_1\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        Thread.sleep(forTimeInterval: 1)
        app/*@START_MENU_TOKEN@*/.staticTexts["beansScreen"]/*[[".staticTexts[\"My Beans\"]",".staticTexts[\"beansScreen\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

            snapshot("05Beans")
            
            
            // Use XCTAssert and related functions to verify your tests produce the correct results.
        }
    
    @MainActor func testDiary() throws {
            let app = XCUIApplication()
            app.launch()
            Thread.sleep(forTimeInterval: 2)
            app/*@START_MENU_TOKEN@*/.staticTexts["tabItem_1"]/*[[".staticTexts[\"More\\nMore\"]",".staticTexts[\"tabItem_1\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
            Thread.sleep(forTimeInterval: 1)
            app/*@START_MENU_TOKEN@*/.staticTexts["brewDiary"]/*[[".staticTexts[\"Brew Diary\\nBrew Diary\"]",".staticTexts[\"brewDiary\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
            snapshot("06Diary")
            
            
            // Use XCTAssert and related functions to verify your tests produce the correct results.
        }
    
    @MainActor func testDark() throws {
            let app = XCUIApplication()
            app.launch()
      
            Thread.sleep(forTimeInterval: 2)
            app/*@START_MENU_TOKEN@*/.staticTexts["tabItem_1"]/*[[".staticTexts[\"More\\nMore\"]",".staticTexts[\"tabItem_1\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
            Thread.sleep(forTimeInterval: 1)
            app/*@START_MENU_TOKEN@*/.staticTexts["settings"]/*[[".staticTexts[\"Settings\\nSettings\"]",".staticTexts[\"settings\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
            app/*@START_MENU_TOKEN@*/.staticTexts["settingsThemeTile"]/*[[".staticTexts[\"Theme\\nSystem\"]",".staticTexts[\"settingsThemeTile\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
            app/*@START_MENU_TOKEN@*/.staticTexts["themeDarkListTile"]/*[[".staticTexts[\"Dark\"]",".staticTexts[\"themeDarkListTile\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
            snapshot("07DarkTheme")
            app/*@START_MENU_TOKEN@*/.staticTexts["settingsThemeTile"]/*[[".staticTexts[\"Theme\\nDark\"]",".staticTexts[\"settingsThemeTile\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
            app/*@START_MENU_TOKEN@*/.staticTexts["themeSystemListTile"]/*[[".staticTexts[\"System\"]",".staticTexts[\"themeSystemListTile\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
          
            
            
            // Use XCTAssert and related functions to verify your tests produce the correct results.
        }


}
