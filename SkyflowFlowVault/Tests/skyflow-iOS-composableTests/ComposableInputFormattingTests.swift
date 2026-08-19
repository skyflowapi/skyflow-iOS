//
//  ComposableInputFormattingTests.swift
//

// Confirms format/translation (CollectElementOptions) behaves identically for an element
// created via a ComposableContainer as it does via a plain CollectContainer - the SDK never
// special-cases formatting logic on container/interface type, but this combination had no
// test anywhere before now (only CollectContainer-based formatting was covered, in
// skyflow-iOS-elementTests/TextFieldDelegateTests.swift, whose test bodies this mirrors).

import XCTest
@testable import SkyflowFlowVault
@testable import SkyflowCore

final class ComposableInputFormattingTests: XCTestCase {
    var skyflow: Client!

    override func setUp() {
        self.skyflow = SkyflowFlowVault.initialize(
            Configuration(vaultID: (ProcessInfo.processInfo.environment["VAULT_ID"] ?? "dummy_vault_id"),
                          vaultURL: (ProcessInfo.processInfo.environment["VAULT_URL"] ?? "https://dummy.vault.skyflowapis.dev/"),
                          tokenProvider: DemoTokenProvider())
        )
    }

    private func mountedComposableInputField(format: String, translation: [Character: String]? = nil) throws -> TextField {
        let container = skyflow.container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [1]))

        let collectOptions = translation != nil
            ? CollectElementOptions(required: false, format: format, translation: translation)
            : CollectElementOptions(required: false, format: format)

        let inputFieldInput = CollectElementInput(tableName: "persons", column: "input_field", placeholder: "input_field", type: .INPUT_FIELD)
        let inputField = container!.create(input: inputFieldInput, options: collectOptions)

        let view = try container!.getComposableView()
        let window = UIWindow()
        window.addSubview(view)

        return inputField
    }

    func testComposableFormatInputWithTranslation() throws {
        let inputField = try mountedComposableInputField(
            format: "+91 YYYY-YYYY-YYYY YYYY XXXX",
            translation: ["X": "[A-Z]", "Y": "[0-9]", "Z": "[A-Za-z0-9]"]
        )

        let result = inputField.textField.delegate?.textField?(
            inputField.textField,
            shouldChangeCharactersIn: NSRange(location: 0, length: 0),
            replacementString: "1")

        XCTAssertFalse(result!)
        XCTAssertEqual(inputField.actualValue, "+91 1")
        XCTAssertEqual(inputField.textField.secureText, "+91 1")
    }

    func testComposableFormatInputDefaultTranslation() throws {
        let inputField = try mountedComposableInputField(format: "+91 YYYY-YYYY-YYYY YYYY XXXX")

        let result = inputField.textField.delegate?.textField?(
            inputField.textField,
            shouldChangeCharactersIn: NSRange(location: 0, length: 0),
            replacementString: "1234")

        XCTAssertFalse(result!)
        XCTAssertEqual(inputField.actualValue, "+91 YYYY-YYYY-YYYY YYYY 1234")
        XCTAssertEqual(inputField.textField.secureText, "+91 YYYY-YYYY-YYYY YYYY 1234")
    }

    func testComposableFormatInputPhoneNumber() throws {
        let inputField = try mountedComposableInputField(
            format: "+91 XX XXXX XXXX",
            translation: ["X": "[0-9]"]
        )

        let result = inputField.textField.delegate?.textField?(
            inputField.textField,
            shouldChangeCharactersIn: NSRange(location: 0, length: 0),
            replacementString: "1234567890")

        XCTAssertFalse(result!)
        XCTAssertEqual(inputField.actualValue, "+91 12 3456 7890")
        XCTAssertEqual(inputField.textField.secureText, "+91 12 3456 7890")
    }

    // Confirms the one documented container-type-specific difference (the inline error
    // message label is omitted for composable elements, per TextField.swift's
    // `contextOptions.interface != .COMPOSABLE_CONTAINER` check) does not affect formatting,
    // and that the same element's actualValue still reflects the formatted, not raw, input.
    func testComposableFormattingUnaffectedByComposableErrorLayoutOmission() throws {
        let inputField = try mountedComposableInputField(
            format: "+91 YYYY-YYYY-YYYY YYYY XXXX",
            translation: ["X": "[A-Z]", "Y": "[0-9]", "Z": "[A-Za-z0-9]"]
        )

        XCTAssertFalse(inputField.stackView.arrangedSubviews.contains(inputField.errorMessage))
        _ = inputField.textField.delegate?.textField?(
            inputField.textField,
            shouldChangeCharactersIn: NSRange(location: 0, length: 0),
            replacementString: "1")
        XCTAssertEqual(inputField.actualValue, "+91 1")
    }
}
