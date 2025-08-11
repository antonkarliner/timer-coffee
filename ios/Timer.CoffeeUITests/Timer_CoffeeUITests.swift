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
            app/*@START_MENU_TOKEN@*/.buttons["brewingMethod_v60"]/*[[".buttons[\"Hario V60\\nHario V60\"]",".buttons[\"brewingMethod_v60\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
            snapshot("02Recipelist")
            app/*@START_MENU_TOKEN@*/.buttons["recipeListItem_106"]/*[[".buttons[\"Tetsu Kasuya 4:6 Method\"]",".buttons[\"recipeListItem_106\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
            snapshot("03Recipedetail")
        let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 1)
        element.children(matching: .other).element(boundBy: 1).children(matching: .button).element.tap()
        element.children(matching: .other).element(boundBy: 2).children(matching: .button).element(boundBy: 1).tap()

            snapshot("04Preparation")
                
                    
            // Use XCTAssert and related functions to verify your tests produce the correct results.
        }

    @MainActor func testCreate() throws {
        
        let app = XCUIApplication()
        app.launch()
        app/*@START_MENU_TOKEN@*/.buttons["createRecipe"]/*[[".buttons[\"Create Recipe\\nCreate Recipe\"]",".buttons[\"createRecipe\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
           
            snapshot("05CreateRecipe")
            
            
            // Use XCTAssert and related functions to verify your tests produce the correct results.
        }


   

    
    @MainActor func testBeans() throws {
            let app = XCUIApplication()
        app.launch()
        Thread.sleep(forTimeInterval: 2)
        app/*@START_MENU_TOKEN@*/.staticTexts["tabItem_1"]/*[[".staticTexts[\"More\\nMore\"]",".staticTexts[\"tabItem_1\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        Thread.sleep(forTimeInterval: 1)

            snapshot("06Beans")
            
        
            // Use XCTAssert and related functions to verify your tests produce the correct results.
        }
    
    @MainActor func testDiary() throws {
            let app = XCUIApplication()
            app.launch()
            Thread.sleep(forTimeInterval: 2)
        app.staticTexts["tabItem_2"].tap()
            Thread.sleep(forTimeInterval: 1)
            app.buttons["brewDiary"].tap()
            snapshot("07Diary")
            
            
            // Use XCTAssert and related functions to verify your tests produce the correct results.
        }
    
    @MainActor func testDark() throws {
            let app = XCUIApplication()
            app.launch()
      
            Thread.sleep(forTimeInterval: 2)
        app.staticTexts["tabItem_2"].tap()
            Thread.sleep(forTimeInterval: 1)
            app/*@START_MENU_TOKEN@*/.buttons["settings"]/*[[".buttons[\"Settings\\nSettings\"]",".buttons[\"settings\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
            app/*@START_MENU_TOKEN@*/.buttons["settingsThemeTile"]/*[[".buttons[\"Theme\\nSystem\"]",".buttons[\"settingsThemeTile\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
            app/*@START_MENU_TOKEN@*/.buttons["themeDarkListTile"]/*[[".buttons[\"Dark\"]",".buttons[\"themeDarkListTile\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
            snapshot("08DarkTheme")
            app/*@START_MENU_TOKEN@*/.buttons["settingsThemeTile"]/*[[".buttons[\"Theme\\nDark\"]",".buttons[\"settingsThemeTile\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
            app/*@START_MENU_TOKEN@*/.buttons["themeSystemListTile"]/*[[".buttons[\"System\"]",".buttons[\"themeSystemListTile\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
         
            // Use XCTAssert and related functions to verify your tests produce the correct results.
        }
    
    
   


}
