//
//  RevealElementOptions.swift
//  
//
//  Created by Bharti Sagar on 19/04/23.
//

import Foundation
import XCTest
import AEXML
@testable import Skyflow


class RevealElementOptionsTests: XCTestCase {

    func testRevealElementOptionsTestWithoutFormatTranslation(){
        let revealElementsOptions = RevealElementOptions()
        XCTAssertEqual(revealElementsOptions.format, nil)
        XCTAssertEqual(revealElementsOptions.translation, nil)
    }
    func testRevealElementOptionsTestWithFormat(){
        let revealElementsOptions = RevealElementOptions(format: "XXXX-XXXX-XXXX")
        XCTAssertEqual(revealElementsOptions.format, "XXXX-XXXX-XXXX")
        XCTAssertEqual(revealElementsOptions.translation, nil)
    }
    func testRevealElementOptionsTestWithTranslation(){
        let revealElementsOptions = RevealElementOptions(translation: ["X": "[0-9]"])
        XCTAssertEqual(revealElementsOptions.format, nil)
        XCTAssertEqual(revealElementsOptions.translation, ["X": "[0-9]"])
    }
    func testRevealElementOptionsTestWithBoth(){
        let revealElementsOptions = RevealElementOptions(format: "XXXX-XXXX-XXXX", translation: ["X": "[0-9]"])
        XCTAssertEqual(revealElementsOptions.format, "XXXX-XXXX-XXXX")
        XCTAssertEqual(revealElementsOptions.translation, ["X": "[0-9]"])
    }    
}
