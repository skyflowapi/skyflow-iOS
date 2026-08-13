//
//  RevealElementOptions.swift
//  
//
//  Created by Bharti Sagar on 19/04/23.
//

import Foundation
import XCTest

@testable import SkyflowFlowVault
@testable import SkyflowCore


class RevealElementOptionsTests: XCTestCase {

    func testRevealElementOptionsTestWithoutFormatTranslation(){
        let revealElementsOptions = RevealElementOptions()
        XCTAssertEqual(revealElementsOptions.data.format, nil)
        XCTAssertEqual(revealElementsOptions.data.translation, nil)
    }
    func testRevealElementOptionsTestWithFormat(){
        let revealElementsOptions = RevealElementOptions(format: "XXXX-XXXX-XXXX")
        XCTAssertEqual(revealElementsOptions.data.format, "XXXX-XXXX-XXXX")
        XCTAssertEqual(revealElementsOptions.data.translation, nil)
    }
    func testRevealElementOptionsTestWithTranslation(){
        let revealElementsOptions = RevealElementOptions(translation: ["X": "[0-9]"])
        XCTAssertEqual(revealElementsOptions.data.format, nil)
        XCTAssertEqual(revealElementsOptions.data.translation, ["X": "[0-9]"])
    }
    func testRevealElementOptionsTestWithBoth(){
        let revealElementsOptions = RevealElementOptions(format: "XXXX-XXXX-XXXX", translation: ["X": "[0-9]"])
        XCTAssertEqual(revealElementsOptions.data.format, "XXXX-XXXX-XXXX")
        XCTAssertEqual(revealElementsOptions.data.translation, ["X": "[0-9]"])
    }
    func testRevealElementOptionsTestWithEnableTrue(){
        let revealElementsOptions = RevealElementOptions(format: "XXXX-XXXX-XXXX", translation: ["X": "[0-9]"], enableCopy: true)
        XCTAssertEqual(revealElementsOptions.data.format, "XXXX-XXXX-XXXX")
        XCTAssertEqual(revealElementsOptions.data.translation, ["X": "[0-9]"])
        XCTAssertEqual(revealElementsOptions.data.enableCopy, true)
    }
    func testRevealElementOptionsTestWithFalseEnable(){
        let revealElementsOptions = RevealElementOptions(format: "XXXX-XXXX-XXXX", translation: ["X": "[0-9]"])
        XCTAssertEqual(revealElementsOptions.data.format, "XXXX-XXXX-XXXX")
        XCTAssertEqual(revealElementsOptions.data.translation, ["X": "[0-9]"])
        XCTAssertEqual(revealElementsOptions.data.enableCopy, false)
    }
}
