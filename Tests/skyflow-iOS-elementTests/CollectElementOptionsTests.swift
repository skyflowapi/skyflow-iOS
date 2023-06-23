//
//  CollectElementOptionsTests.swift
//  
//
//  Created by Bharti Sagar on 19/04/23.
//

import XCTest
@testable import Skyflow

class CollectElementOptionsTests: XCTestCase {

    func testCollectElementOptions(){ // default init
        let options = CollectElementOptions()
        XCTAssertEqual(options.format, "mm/yy")
        XCTAssertEqual(options.translation, nil)
    }
    func testCollectElementOptionsWithFormat(){ // format
        let options = CollectElementOptions(format: "XXXX")
        XCTAssertEqual(options.format, "XXXX")
        XCTAssertEqual(options.translation, nil)
    }
    func testCollectElementOptionsWithTranslation(){ // format
        let options = CollectElementOptions(translation: ["X": "[0-9]"])
        XCTAssertEqual(options.format, "mm/yy")
        XCTAssertEqual(options.translation, ["X": "[0-9]"])
    }
    func testCollectElementOptionsWithTranslationFormat(){ // format
        let options = CollectElementOptions(format: "XXX",translation: ["X": "[0-9]"])
        XCTAssertEqual(options.format, "XXX")
        XCTAssertEqual(options.translation, ["X": "[0-9]"])
    }
    func testCollectElementOptionsWithEmptyFormat(){ // format
        let options = CollectElementOptions(format: "",translation: ["X": "[0-9]"])
        XCTAssertEqual(options.format, "")
        XCTAssertEqual(options.translation, ["X": "[0-9]"])
    }
    func testCollectElementOptionsWithNilFormat(){ // format
        let options = CollectElementOptions(format: "XXX",translation: nil)
        XCTAssertEqual(options.format, "XXX")
        XCTAssertEqual(options.translation, nil)
    }


}
