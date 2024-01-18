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
        
        let harioV60StaticText = app.staticTexts["Hario V60"]
        harioV60StaticText.tap()
        
        let jamesHoffmannV60RecipeElement = app.otherElements["James Hoffmann V60 recipe"]
        jamesHoffmannV60RecipeElement.tap()
        
        let backButton = app.buttons["Back"]
        backButton.tap()
        backButton.tap()
        snapshot("01Home")
        harioV60StaticText.tap()
        snapshot("02Recipelist")
        app.otherElements["Tetsu Kasuya 4:6 Method"].tap()
        snapshot("03Tetsu")
        backButton.tap()
        jamesHoffmannV60RecipeElement.tap()
        app.textFields["Coffee amount (g)"].tap()
        snapshot("04Recipedetail")
        let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 1)
        element.children(matching: .other).element(boundBy: 1).children(matching: .button).element.tap()
        snapshot("05Preparation")
        element.children(matching: .button).element(boundBy: 1).tap()
        snapshot("06Brewing")
        backButton.tap()
        backButton.tap()
        backButton.tap()
        backButton.tap()
        app.buttons["Settings"].tap()
        app.staticTexts["Theme\nSystem"].tap()
        app.staticTexts["Dark"].tap()
        snapshot("07Darktheme")
        app.staticTexts["Theme\nDark"].tap()
        app.staticTexts["System"].tap()
        app.staticTexts["Language\nEnglish"].tap()
        snapshot("08Languages")
        app.staticTexts["Scrim"].tap()
        
                                            
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}
@MainActor func testDE() throws {
    let app = XCUIApplication()
    app.launch()

    let harioV60StaticText = app.staticTexts["Hario V60"]
    harioV60StaticText.tap()
    
    let jamesHoffmannV60RezeptElement = app.otherElements["James Hoffmann V60 Rezept"]
    jamesHoffmannV60RezeptElement.tap()
    
    let zurCkButton = app.buttons["Zurück"]
    zurCkButton.tap()
    zurCkButton.tap()
    snapshot("01Home")
    harioV60StaticText.tap()
    snapshot("02Recipelist")
    app.otherElements["Tetsu Kasuya 4:6 Methode"].tap()
    snapshot("03Tetsu")
    zurCkButton.tap()
    jamesHoffmannV60RezeptElement.tap()
    app.textFields["Kaffeemenge (g)"].tap()
    snapshot("04Recipedetail")
    let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 1)
    element.children(matching: .other).element(boundBy: 1).children(matching: .button).element.tap()
    snapshot("05Preparation")
    element.children(matching: .button).element(boundBy: 1).tap()
    snapshot("06Brewing")
    zurCkButton.tap()
    zurCkButton.tap()
    zurCkButton.tap()
    zurCkButton.tap()
    app.buttons["Settings"].tap()
    app.staticTexts["Thema\nSystem"].tap()
    app.staticTexts["Dunkel"].tap()
    snapshot("07Darktheme")
    app.staticTexts["Thema\nDunkel"].tap()
    app.staticTexts["System"].tap()
    app.staticTexts["Sprache\nDeutsch"].tap()
    snapshot("08Languages")
    app.staticTexts["Gitter"].tap()
    zurCkButton.tap()
 
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

@MainActor func testES() throws {
            let app = XCUIApplication()
            app.launch()
    
    let harioV60StaticText = app.staticTexts["Hario V60"]
    harioV60StaticText.tap()
    
    let recetaJamesHoffmannV60Element = app.otherElements["Receta James Hoffmann V60"]
    recetaJamesHoffmannV60Element.tap()
    
    let atrSButton = app.buttons["Atrás"]
    atrSButton.tap()
    atrSButton.tap()
    snapshot("01Home")
    harioV60StaticText.tap()
    snapshot("02Recipelist")
    app.otherElements["Método Tetsu Kasuya 4:6"].tap()
    snapshot("03Tetsu")
    atrSButton.tap()
    recetaJamesHoffmannV60Element.tap()
    app.textFields["Cantidad de café (g)"].tap()
    snapshot("04Recipedetail")
    let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 1)
    element.children(matching: .other).element(boundBy: 1).children(matching: .button).element.tap()
    snapshot("05Preparation")
    element.children(matching: .button).element(boundBy: 1).tap()
    snapshot("06Brewing")
    atrSButton.tap()
    atrSButton.tap()
    atrSButton.tap()
    atrSButton.tap()
    app.buttons["Settings"].tap()
    app.staticTexts["Tema\nSistema"].tap()
    app.staticTexts["Oscuro"].tap()
    snapshot("07Darktheme")
    app.staticTexts["Tema\nOscuro"].tap()
    app.staticTexts["Sistema"].tap()
    app.staticTexts["Idioma\nEspañol"].tap()
    snapshot("08Languages")
    app.staticTexts["Sombreado"].tap()
      
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

@MainActor func testPT() throws {
                let app = XCUIApplication()
                app.launch()
    
    let harioV60StaticText = app.staticTexts["Hario V60"]
    harioV60StaticText.tap()
    
    let receitaJamesHoffmannV60Element = app.otherElements["Receita James Hoffmann V60"]
    receitaJamesHoffmannV60Element.tap()
    
    let voltarButton = app.buttons["Voltar"]
    voltarButton.tap()
    voltarButton.tap()
    snapshot("01Home")
    harioV60StaticText.tap()
    snapshot("02Recipelist")
    app.otherElements["Método Tetsu Kasuya 4:6"].tap()
    snapshot("03Tetsu")
    voltarButton.tap()
    receitaJamesHoffmannV60Element.tap()
    app.textFields["Quantidade de café (g)"].tap()
    snapshot("04Recipedetail")
    let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 1)
    element.children(matching: .other).element(boundBy: 1).children(matching: .button).element.tap()
    snapshot("05Preparation")
    element.children(matching: .button).element(boundBy: 1).tap()
    snapshot("06Brewing")
    voltarButton.tap()
    voltarButton.tap()
    voltarButton.tap()
    voltarButton.tap()
    app.buttons["Settings"].tap()
    app.staticTexts["Tema\nSistema"].tap()
    app.staticTexts["Escuro"].tap()
    snapshot("07Darktheme")
    app.staticTexts["Tema\nEscuro"].tap()
    app.staticTexts["Sistema"].tap()
    app.staticTexts["Idioma\nPortuguês"].tap()
    app.staticTexts["Scrim"].tap()
    snapshot("08Languages")
          
            // Use XCTAssert and related functions to verify your tests produce the correct results.
        }
    @MainActor func testFR() throws {
                    let app = XCUIApplication()
                    app.launch()
        
        let harioV60StaticText = app.staticTexts["Hario V60"]
        harioV60StaticText.tap()
        
        let recetteV60DeJamesHoffmannElement = app.otherElements["Recette V60 de James Hoffmann"]
        recetteV60DeJamesHoffmannElement.tap()
        
        let retourButton = app.buttons["Retour"]
        retourButton.tap()
        retourButton.tap()
        snapshot("01Home")
        harioV60StaticText.tap()
        snapshot("02Recipelist")
        app.otherElements["Méthode Tetsu Kasuya 4:6"].tap()
        snapshot("03Tetsu")
        retourButton.tap()
        recetteV60DeJamesHoffmannElement.tap()
        app.textFields["Quantité de café (g)"].tap()
        snapshot("04Recipedetail")
        let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 1)
        element.children(matching: .other).element(boundBy: 1).children(matching: .button).element.tap()
        snapshot("05Preparation")
        element.children(matching: .button).element(boundBy: 1).tap()
        snapshot("06Brewing")
        retourButton.tap()
        retourButton.tap()
        retourButton.tap()
        retourButton.tap()
        app.buttons["Settings"].tap()
        app.staticTexts["Thème\nSystème"].tap()
        app.staticTexts["Sombre"].tap()
        snapshot("07Darktheme")
        app.staticTexts["Thème\nSombre"].tap()
        app.staticTexts["Système"].tap()
        app.staticTexts["Langue\nFrançais"].tap()
        snapshot("08Languages")
        app.staticTexts["Fond"].tap()

             
                // Use XCTAssert and related functions to verify your tests produce the correct results.
            }
    @MainActor func testRU() throws {
                    let app = XCUIApplication()
                    app.launch()
        
        let harioV60StaticText = app.staticTexts["Hario V60"]
        harioV60StaticText.tap()
        
        let v60Element = app.otherElements["Рецепт для V60 от Джеймса Хоффмана"]
        v60Element.tap()
        
        let button = app.buttons["Назад"]
        button.tap()
        button.tap()
        snapshot("01Home")
        harioV60StaticText.tap()
        snapshot("02Recipelist")
        app.otherElements["Метод 4:6 от Тетсу Кацуи"].tap()
        snapshot("03Tetsu")
        button.tap()
        v60Element.tap()
        app.textFields["Кол-во кофе (г)"].tap()
        snapshot("04Recipedetail")
        let element2 = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element
        let element = element2.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 1)
        element.children(matching: .other).element(boundBy: 1).children(matching: .button).element.tap()
        snapshot("05Preparation")
        element.children(matching: .button).element(boundBy: 1).tap()
        snapshot("06Brewing")
        button.tap()
        button.tap()
        button.tap()
        button.tap()
      
        app.buttons["Settings"].tap()
        app.staticTexts["Тема\nСистемная"].tap()
        app.staticTexts["Тёмная"].tap()
        snapshot("07Darktheme")
        app.staticTexts["Тема\nТёмная"].tap()
        app.staticTexts["Системная"].tap()
        app.staticTexts["Язык\nРусский"].tap()
        snapshot("08Languages")
        app.staticTexts["Маска"].tap()
                
                // Use XCTAssert and related functions to verify your tests produce the correct results.
            }
    
    @MainActor func testPL() throws {
                    let app = XCUIApplication()
                    app.launch()
        
        
        let harioV60StaticText = app.staticTexts["Hario V60"]
        harioV60StaticText.tap()
        
        let przepisJamesaHoffmannaNaV60Element = app.otherElements["Przepis Jamesa Hoffmanna na V60"]
        przepisJamesaHoffmannaNaV60Element.tap()
        
        let wsteczButton = app.buttons["Wstecz"]
        wsteczButton.tap()
        wsteczButton.tap()
        snapshot("01Home")
        harioV60StaticText.tap()
        snapshot("02Recipelist")
        app.otherElements["Metoda Tetsu Kasuya 4:6"].tap()
        snapshot("03Tetsu")
        wsteczButton.tap()
        przepisJamesaHoffmannaNaV60Element.tap()
        app.textFields["Ilość kawy (g)"].tap()
        snapshot("04Recipedetail")
        let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 1)
        element.children(matching: .other).element(boundBy: 1).children(matching: .button).element.tap()
        snapshot("05Preparation")
        element.children(matching: .button).element(boundBy: 1).tap()
        snapshot("06Brewing")
        wsteczButton.tap()
        wsteczButton.tap()
        wsteczButton.tap()
        wsteczButton.tap()
        app.buttons["Settings"].tap()
        app.staticTexts["Motyw\nSystem"].tap()
        app.staticTexts["Ciemny"].tap()
        snapshot("07Darktheme")
        app.staticTexts["Motyw\nCiemny"].tap()
        app.staticTexts["System"].tap()
        app.staticTexts["Język\nPolski"].tap()
        snapshot("08Languages")
               
                
                // Use XCTAssert and related functions to verify your tests produce the correct results.
            }
    @MainActor func testAR() throws {
                    let app = XCUIApplication()
                    app.launch()
        
        let harioV60StaticText = app.staticTexts["Hario V60"]
        harioV60StaticText.tap()
        
        let harioV60Element = app.otherElements["وصفة جيمس هوفمان لـ Hario V60"]
        harioV60Element.tap()
        
        let button = app.buttons["رجوع"]
        button.tap()
        button.tap()
        snapshot("01Home")
        harioV60StaticText.tap()
        snapshot("02Recipelist")
        app.otherElements["طريقة تيتسو كاسويا 4:6"].tap()
        snapshot("03Tetsu")
        button.tap()
        harioV60Element.tap()
        app.textFields["كمية القهوة (غ)"].tap()
        snapshot("04Recipedetail")
        let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 1)
        element.children(matching: .other).element(boundBy: 1).children(matching: .button).element.tap()
        snapshot("05Preparation")
        element.children(matching: .button).element(boundBy: 1).tap()
        snapshot("06Brewing")
        button.tap()
        button.tap()
        button.tap()
        button.tap()
        app.buttons["Settings"].tap()
        app.staticTexts["الثيم\nالنظام"].tap()
        app.staticTexts["داكن"].tap()
        snapshot("07Darktheme")
        app.staticTexts["الثيم\nداكن"].tap()
        app.staticTexts["النظام"].tap()
        app.staticTexts["اللغة\nالعربية"].tap()
        snapshot("08Languages")
        app.staticTexts["تمويه"].tap()
                
                // Use XCTAssert and related functions to verify your tests produce the correct results.
            }
    
    @MainActor func testZH() throws {
                    let app = XCUIApplication()
                    app.launch()

        let harioV60StaticText = app.staticTexts["Hario V60"]
        harioV60StaticText.tap()
        
        let jamesHoffmannV60Element = app.otherElements["James Hoffmann V60 配方"]
        jamesHoffmannV60Element.tap()
        
        let button = app.buttons["返回"]
        button.tap()
        button.tap()
        snapshot("01Home")
        harioV60StaticText.tap()
        snapshot("02Recipelist")
        app.otherElements["Tetsu Kasuya 4:6 法"].tap()
        snapshot("03Tetsu")
        button.tap()
        jamesHoffmannV60Element.tap()
        app.textFields["咖啡量（克）"].tap()
        snapshot("04Recipedetail")
        let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 1)
        element.children(matching: .other).element(boundBy: 1).children(matching: .button).element.tap()
        snapshot("05Preparation")
        element.children(matching: .button).element(boundBy: 1).tap()
        snapshot("06Brewing")
        button.tap()
        button.tap()
        button.tap()
        button.tap()
        app.buttons["Settings"].tap()
        app.staticTexts["主题\n系统"].tap()
        app.staticTexts["深色"].tap()
        snapshot("07Darktheme")
        app.staticTexts["主题\n深色"].tap()
        app.staticTexts["系统"].tap()
        app.staticTexts["言語\n中文"].tap()
        snapshot("08Languages")
                // Use XCTAssert and related functions to verify your tests produce the correct results.
            }
    @MainActor func testJA() throws {
                    let app = XCUIApplication()
                    app.launch()

        let harioV60StaticText = app.staticTexts["Hario V60"]
        harioV60StaticText.tap()
        
        let v60Element = app.otherElements["ジェームズ・ホフマンのV60レシピ"]
        v60Element.tap()
        
        let button = app.buttons["戻る"]
        button.tap()
        button.tap()
        snapshot("01Home")
        harioV60StaticText.tap()
        snapshot("02Recipelist")
        app.otherElements["テツ・カスヤの4:6方法"].tap()
        snapshot("03Tetsu")
        button.tap()
        v60Element.tap()
        app.textFields["コーヒー量(g)"].tap()
        snapshot("04Recipedetail")
        let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 1)
        element.children(matching: .other).element(boundBy: 1).children(matching: .button).element.tap()
        snapshot("05Preparation")
        element.children(matching: .button).element(boundBy: 1).tap()
        snapshot("06Brewing")
        button.tap()
        button.tap()
        button.tap()
        button.tap()
        app.buttons["Settings"].tap()
        app.staticTexts["テーマ\nシステム"].tap()
        app.staticTexts["ダーク"].tap()
        snapshot("07Darktheme")
        app.staticTexts["テーマ\nダーク"].tap()
        app.staticTexts["システム"].tap()
        app.staticTexts["言語\n日本語"].tap()
        snapshot("08Languages")
                // Use XCTAssert and related functions to verify your tests produce the correct results.
            }
}

