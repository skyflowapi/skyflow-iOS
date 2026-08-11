//
//  CollectElementOptionsTests.swift
//  
//
//  Created by Bharti Sagar on 19/04/23.
//

import XCTest
@testable import SkyflowFlowVaultIOS
@testable import SkyflowCore

class CollectElementOptionsTests: XCTestCase {

    func testCollectElementOptions(){ // default init
        let options = CollectElementOptions()
        XCTAssertEqual(options.data.format, "mm/yy")
        XCTAssertEqual(options.data.translation, nil)
    }
    func testCollectElementOptionsWithFormat(){ // format
        let options = CollectElementOptions(format: "XXXX")
        XCTAssertEqual(options.data.format, "XXXX")
        XCTAssertEqual(options.data.translation, nil)
    }
    func testCollectElementOptionsWithTranslation(){ // format
        let options = CollectElementOptions(translation: ["X": "[0-9]"])
        XCTAssertEqual(options.data.format, "mm/yy")
        XCTAssertEqual(options.data.translation, ["X": "[0-9]"])
    }
    func testCollectElementOptionsWithTranslationFormat(){ // format
        let options = CollectElementOptions(format: "XXX",translation: ["X": "[0-9]"])
        XCTAssertEqual(options.data.format, "XXX")
        XCTAssertEqual(options.data.translation, ["X": "[0-9]"])
    }
    func testCollectElementOptionsWithEmptyFormat(){ // format
        let options = CollectElementOptions(format: "",translation: ["X": "[0-9]"])
        XCTAssertEqual(options.data.format, "")
        XCTAssertEqual(options.data.translation, ["X": "[0-9]"])
    }
    func testCollectElementOptionsWithNilFormat(){ // format
        let options = CollectElementOptions(format: "XXX",translation: nil)
        XCTAssertEqual(options.data.format, "XXX")
        XCTAssertEqual(options.data.translation, nil)
    }
    func testCollectElementOptionsWithCardMetaData(){
        let options = CollectElementOptions(cardMetaData: ["scheme": [CardType.AMEX, CardType.CARTES_BANCAIRES]])
        XCTAssertEqual(options.data.cardMetaData as! [String : [CardType]], ["scheme": [CardType.AMEX, CardType.CARTES_BANCAIRES]])

    }
    


}
