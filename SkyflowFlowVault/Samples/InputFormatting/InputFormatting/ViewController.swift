/*
 * Copyright (c) 2022 Skyflow
 */
//  Created by Bharti Sagar on 26/04/23.
//

import UIKit
import SkyflowFlowVault

class ViewController: UIViewController {
    private var skyflow: SkyflowFlowVault.Client?
    private var container: SkyflowFlowVault.Container<SkyflowFlowVault.CollectContainer>?
    private var revealContainer: SkyflowFlowVault.Container<SkyflowFlowVault.RevealContainer>?
    private var b: UIButton?

    private var stackView: UIStackView!

    private var revealCVV: Label?
    private var revealCardNumber: Label?
    private var revealName: Label?
    private var revealExpirationMonth: Label?
    private var revealExpirationYear: Label?
    private var revealSSN: Label?
    private var revealPhoneNumber: Label?
    private var revealLicenseNumber: Label?
    private var revealButton: UIButton!

    private var revealed = false

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tokenProvider = ExampleTokenProvider()

        let config = SkyflowFlowVault.Configuration(
            vaultID: "<VAULT_ID>",
            vaultURL: "<VAULT_URL>",
            tokenProvider: tokenProvider,
            options: SkyflowFlowVault.Options(
                logLevel: SkyflowFlowVault.LogLevel.DEBUG
            )
        )

        self.skyflow = SkyflowFlowVault.initialize(config)

        if self.skyflow != nil {
            let container = self.skyflow?.container(type: SkyflowFlowVault.ContainerType.COLLECT, options: nil)
            self.container = container
            self.stackView = UIStackView()

            let baseStyle = SkyflowFlowVault.Style(
                cornerRadius: 2,
                padding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10),
                borderWidth: 1,
                textAlignment: .left,
                textColor: .blue
            )

            let focusStyle = SkyflowFlowVault.Style(borderColor: .blue)

            let completedStyle = SkyflowFlowVault.Style(textColor: UIColor.green)

            let invalidStyle = SkyflowFlowVault.Style(textColor: UIColor.red)

            let styles = SkyflowFlowVault.Styles(
                base: baseStyle,
                complete: completedStyle,
                focus: focusStyle,
                invalid: invalidStyle
            )

            let collectCardNumberInput = SkyflowFlowVault.CollectElementInput(
                table: "table",
                column: "card_number",
                inputStyles: styles,
                label: "Card Number",
                placeholder: "4111-1111-1111-1111",
                type: SkyflowFlowVault.ElementType.CARD_NUMBER
            )
            let collectNameInput = SkyflowFlowVault.CollectElementInput(
                table: "table",
                column: "cardholder_name",
                inputStyles: styles,
                label: "Card Holder Name",
                placeholder: "John Doe",
                type: SkyflowFlowVault.ElementType.CARDHOLDER_NAME
            )
            let collectCVVInput = SkyflowFlowVault.CollectElementInput(
                table: "table",
                column: "cvv",
                inputStyles: styles,
                label: "CVV",
                placeholder: "***",
                type: .CVV
            )
            let collectExpMonthInput = SkyflowFlowVault.CollectElementInput(
                table: "table",
                column: "expiry_month",
                inputStyles: styles,
                label: "Expiration Month",
                placeholder: "MM",
                type: .EXPIRATION_MONTH
            )
            let collectExpYearInput = SkyflowFlowVault.CollectElementInput(
                table: "table",
                column: "expiry_year",
                inputStyles: styles,
                label: "Expiration Year",
                placeholder: "YYYY",
                type: .EXPIRATION_YEAR
            )
            let collectSSNInput = SkyflowFlowVault.CollectElementInput(
                table: "table",
                column: "ssn",
                inputStyles: styles,
                label: "SSN",
                placeholder: "XXX-XX-XXXX",
                type: .INPUT_FIELD
            )
            let collectPhoneNumberInput = SkyflowFlowVault.CollectElementInput(
                table: "table",
                column: "phone_number",
                inputStyles: styles,
                label: "Phone Number",
                placeholder: "+91 XXXX-XX-XXXX",
                type: .INPUT_FIELD
            )
            let collectLicenseNumberInput = SkyflowFlowVault.CollectElementInput(
                table: "table",
                column: "license_number",
                inputStyles: styles,
                label: "License Number",
                placeholder: "X YYY YYY YY YY",
                type: .INPUT_FIELD
            )
            let collectCardNumber = container?.create(input: collectCardNumberInput, options: SkyflowFlowVault.CollectElementOptions(required: true, format: "XXXX-XXXX-XXXX-XXXX"))
            let collectName = container?.create(input: collectNameInput, options: SkyflowFlowVault.CollectElementOptions(required: true))
            let collectCVV = container?.create(input: collectCVVInput, options: SkyflowFlowVault.CollectElementOptions(required: true))
            let collectExpMonth = container?.create(input: collectExpMonthInput, options: SkyflowFlowVault.CollectElementOptions(required: true))
            let collectExpYear = container?.create(input: collectExpYearInput, options: SkyflowFlowVault.CollectElementOptions(required: true))
            let collectSSN = container?.create(input: collectSSNInput, options: SkyflowFlowVault.CollectElementOptions(required: true, format: "XXX-XX-XXXX", translation: ["X": "[0-9]"]))
            let collectPhoneNumber = container?.create(input: collectPhoneNumberInput, options: SkyflowFlowVault.CollectElementOptions(required: true, format: "+91 XXXX-XX-XXXX", translation: ["X": "[0-9]"]))
            let collectLicenseNumber = container?.create(input: collectLicenseNumberInput, options: SkyflowFlowVault.CollectElementOptions(required: true, format: "X YYY YYY YY YY", translation: ["X": "[A-Z]","Y": "[0-9]"]))

            let collectButton = UIButton(frame: CGRect(x: 100, y: 400, width: 100, height: 40))
            collectButton.backgroundColor = .blue
            collectButton.setTitle("Submit", for: .normal)
            collectButton.addTarget(self, action: #selector(submitForm), for: .touchUpInside)
            self.revealContainer = skyflow?.container(type: SkyflowFlowVault.ContainerType.REVEAL, options: nil)
            self.revealButton = UIButton(frame: CGRect(x: 100, y: 400, width: 100, height: 40))
            revealButton.backgroundColor = .blue
            revealButton.setTitle("Reveal", for: .normal)
            revealButton.addTarget(self, action: #selector(revealForm), for: .touchUpInside)
            stackView.addArrangedSubview(collectCardNumber!)
            stackView.addArrangedSubview(collectName!)
            stackView.addArrangedSubview(collectCVV!)
            stackView.addArrangedSubview(collectExpMonth!)
            stackView.addArrangedSubview(collectExpYear!)
            stackView.addArrangedSubview(collectSSN!)
            stackView.addArrangedSubview(collectPhoneNumber!)
            stackView.addArrangedSubview(collectLicenseNumber!)
            stackView.addArrangedSubview(collectButton)
            stackView.axis = .vertical
            stackView.distribution = .fill
            stackView.spacing = 10
            stackView.alignment = .fill
            stackView.translatesAutoresizingMaskIntoConstraints = false
            let scrollView = UIScrollView(frame: .zero)
            scrollView.isScrollEnabled = true
            scrollView.backgroundColor = .white
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(scrollView)
            scrollView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 20
            ).isActive = true
            scrollView.leftAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leftAnchor,
                constant: 10
            ).isActive = true
            scrollView.rightAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.rightAnchor,
                constant: -10
            ).isActive = true
            scrollView.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor
            ).isActive = true
            scrollView.addSubview(stackView)
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -10).isActive = true
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
            stackView.leftAnchor.constraint(equalTo: scrollView.leftAnchor).isActive = true
            stackView.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -10).isActive = true
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        }
    }
    @objc func revealForm() {
        self.revealContainer?.reveal(callback: ExampleAPICallback())
    }
    @objc func submitForm() {
        let exampleAPICallback = ExampleAPICallback(updateSuccess: updateSuccess, updateFailure: updateFailure)
        container!.collect(callback: exampleAPICallback, options: SkyflowFlowVault.CollectOptions(tokens: true))
    }
    internal func updateSuccess(_ response: SuccessResponse) {
        print(response)
        updateRevealInputs(tokens: response.records[0].fields)
        print("Successfully got response:", response)
    }
    internal func updateFailure(error: Any) {
        print("Failed Operation", error)
    }
    internal func updateRevealInputs(tokens: Fields) {
        let revealBaseStyle = SkyflowFlowVault.Style(
            borderColor: UIColor.black,
            cornerRadius: 20,
            padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5),
            borderWidth: 2,
            textAlignment: .left,
            textColor: UIColor.blue
        )
        let revealStyles = SkyflowFlowVault.Styles(base: revealBaseStyle)
        DispatchQueue.main.async {
            if self.revealed {
                self.removeRevealElements()
            } else {
                self.revealed = true
            }
            let revealCardNumberInput = SkyflowFlowVault.RevealElementInput(
                token: tokens.card_number,
                inputStyles: revealStyles,
                label: "Card Number"
            )
            self.revealCardNumber = self.revealContainer?.create(
                input: revealCardNumberInput,
                options: SkyflowFlowVault.RevealElementOptions(format: "XXXX-XXXX-XXXX-XXXX-XXX", translation: ["X": "[0-9]"])
            )
            let revealCVVtInput = SkyflowFlowVault.RevealElementInput(
                token: tokens.cvv,
                inputStyles: revealStyles,
                label: "CVV"
            )
            self.revealCVV = self.revealContainer?.create(input: revealCVVtInput)
            let revealNameInput = SkyflowFlowVault.RevealElementInput(
                token: tokens.cardholder_name,
                inputStyles: revealStyles,
                label: "Card Holder Name"
            )
            self.revealName = self.revealContainer?.create(input: revealNameInput)
            let revealExpirationMonthInput = SkyflowFlowVault.RevealElementInput(
                token: tokens.expiry_month,
                inputStyles: revealStyles,
                label: "Expiration Month"
            )
            self.revealExpirationMonth = self.revealContainer?.create(input: revealExpirationMonthInput)
            let revealExpirationYearInput = SkyflowFlowVault.RevealElementInput(
                token: tokens.expiry_year,
                inputStyles: revealStyles,
                label: "Expiration Year"
            )
            self.revealExpirationYear = self.revealContainer?.create(input: revealExpirationYearInput)
            let revealSSNInput = SkyflowFlowVault.RevealElementInput(
                token: tokens.ssn,
                inputStyles: revealStyles,
                label: "SSN"
            )
            self.revealSSN = self.revealContainer?.create(input: revealSSNInput, options: SkyflowFlowVault.RevealElementOptions(format: "XXX XX XXXX", translation: ["X": "[0-9]"]))
            let revealPhoneNumberInput = SkyflowFlowVault.RevealElementInput(
                token: tokens.phone_number,
                inputStyles: revealStyles,
                label: "Phone Number"
            )
            self.revealPhoneNumber = self.revealContainer?.create(input: revealPhoneNumberInput, options: SkyflowFlowVault.RevealElementOptions(format: "+91 XXXX-XX-XXXX", translation: ["X": "[0-9]"]))
            let revealLicenseNumberInput = SkyflowFlowVault.RevealElementInput(
                token: tokens.phone_number,
                inputStyles: revealStyles,
                label: "License Number"
            )
            self.revealLicenseNumber = self.revealContainer?.create(input: revealLicenseNumberInput, options: SkyflowFlowVault.RevealElementOptions(format: "X YYY YYY YY YY", translation: ["X": "[A-Z]","Y": "[0-9]"]))
            self.addRevealElements()
        }
    }

    internal func removeRevealElements() {
        self.stackView.removeArrangedSubview(self.revealCardNumber!)
        self.stackView.removeArrangedSubview(self.revealName!)
        self.stackView.removeArrangedSubview(self.revealCVV!)
        self.stackView.removeArrangedSubview(self.revealExpirationMonth!)
        self.stackView.removeArrangedSubview(self.revealExpirationYear!)
        self.stackView.removeArrangedSubview(self.revealSSN!)
        self.stackView.removeArrangedSubview(self.revealPhoneNumber!)
        self.stackView.removeArrangedSubview(self.revealLicenseNumber!)
        self.stackView.removeArrangedSubview(self.revealButton)
        self.revealCardNumber?.removeFromSuperview()
        self.revealName?.removeFromSuperview()
        self.revealCVV?.removeFromSuperview()
        self.revealExpirationMonth?.removeFromSuperview()
        self.revealExpirationYear?.removeFromSuperview()
        self.revealSSN?.removeFromSuperview()
        self.revealPhoneNumber?.removeFromSuperview()
        self.revealLicenseNumber?.removeFromSuperview()
        self.revealButton.removeFromSuperview()
        self.revealContainer = self.skyflow?.container(type: SkyflowFlowVault.ContainerType.REVEAL, options: nil)
    }

    internal func addRevealElements() {
        DispatchQueue.main.async {
            self.stackView.addArrangedSubview(self.revealCardNumber!)
            self.stackView.addArrangedSubview(self.revealName!)
            self.stackView.addArrangedSubview(self.revealCVV!)
            self.stackView.addArrangedSubview(self.revealExpirationMonth!)
            self.stackView.addArrangedSubview(self.revealExpirationYear!)
            self.stackView.addArrangedSubview(self.revealSSN!)
            self.stackView.addArrangedSubview(self.revealPhoneNumber!)
            self.stackView.addArrangedSubview(self.revealLicenseNumber!)
            self.stackView.addArrangedSubview(self.revealButton)
        }
    }
}
