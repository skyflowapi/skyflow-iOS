/*
 * Copyright (c) 2022 Skyflow
 */
//  Created by Bharti Sagar on 26/04/23.
//

import UIKit
import Skyflow

class ViewController: UIViewController {
    private var skyflow: Skyflow.Client?
    private var container: Skyflow.Container<Skyflow.CollectContainer>?
    private var revealContainer: Skyflow.Container<Skyflow.RevealContainer>?
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

        let config = Skyflow.Configuration(
            vaultID: "<VAULT_ID>",
            vaultURL: "<VAULT_URL>",
            tokenProvider: tokenProvider,
            options: Skyflow.Options(
                logLevel: Skyflow.LogLevel.DEBUG
            )
        )

        self.skyflow = Skyflow.initialize(config)

        if self.skyflow != nil {
            let container = self.skyflow?.container(type: Skyflow.ContainerType.COLLECT, options: nil)
            self.container = container
            self.stackView = UIStackView()

            let baseStyle = Skyflow.Style(
                cornerRadius: 2,
                padding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10),
                borderWidth: 1,
                textAlignment: .left,
                textColor: .blue
            )

            let focusStyle = Skyflow.Style(borderColor: .blue)

            let completedStyle = Skyflow.Style(textColor: UIColor.green)

            let invalidStyle = Skyflow.Style(textColor: UIColor.red)

            let styles = Skyflow.Styles(
                base: baseStyle,
                complete: completedStyle,
                focus: focusStyle,
                invalid: invalidStyle
            )

            let collectCardNumberInput = Skyflow.CollectElementInput(
                tableName: "table",
                column: "card_number",
                inputStyles: styles,
                label: "Card Number",
                placeholder: "4111-1111-1111-1111",
                type: Skyflow.ElementType.CARD_NUMBER
            )
            let collectNameInput = Skyflow.CollectElementInput(
                tableName: "table",
                column: "cardholder_name",
                inputStyles: styles,
                label: "Card Holder Name",
                placeholder: "John Doe",
                type: Skyflow.ElementType.CARDHOLDER_NAME
            )
            let collectCVVInput = Skyflow.CollectElementInput(
                tableName: "table",
                column: "cvv",
                inputStyles: styles,
                label: "CVV",
                placeholder: "***",
                type: .CVV
            )
            let collectExpMonthInput = Skyflow.CollectElementInput(
                tableName: "table",
                column: "expiry_month",
                inputStyles: styles,
                label: "Expiration Month",
                placeholder: "MM",
                type: .EXPIRATION_MONTH
            )
            let collectExpYearInput = Skyflow.CollectElementInput(
                tableName: "table",
                column: "expiry_year",
                inputStyles: styles,
                label: "Expiration Year",
                placeholder: "YYYY",
                type: .EXPIRATION_YEAR
            )
            let collectSSNInput = Skyflow.CollectElementInput(
                tableName: "table",
                column: "ssn",
                inputStyles: styles,
                label: "SSN",
                placeholder: "XXX-XX-XXXX",
                type: .INPUT_FIELD
            )
            let collectPhoneNumberInput = Skyflow.CollectElementInput(
                tableName: "table",
                column: "phone_number",
                inputStyles: styles,
                label: "Phone Number",
                placeholder: "+91 XXXX-XX-XXXX",
                type: .INPUT_FIELD
            )
            let collectLicenseNumberInput = Skyflow.CollectElementInput(
                tableName: "table",
                column: "license_number",
                inputStyles: styles,
                label: "License Number",
                placeholder: "X YYY YYY YY YY",
                type: .INPUT_FIELD
            )
            let collectCardNumber = container?.create(input: collectCardNumberInput, options: Skyflow.CollectElementOptions(required: true, format: "XXXX-XXXX-XXXX-XXXX"))
            let collectName = container?.create(input: collectNameInput, options: Skyflow.CollectElementOptions(required: true))
            let collectCVV = container?.create(input: collectCVVInput, options: Skyflow.CollectElementOptions(required: true))
            let collectExpMonth = container?.create(input: collectExpMonthInput, options: Skyflow.CollectElementOptions(required: true))
            let collectExpYear = container?.create(input: collectExpYearInput, options: Skyflow.CollectElementOptions(required: true))
            let collectSSN = container?.create(input: collectSSNInput, options: Skyflow.CollectElementOptions(required: true, format: "XXX-XX-XXXX", translation: ["X": "[0-9]"]))
            let collectPhoneNumber = container?.create(input: collectPhoneNumberInput, options: Skyflow.CollectElementOptions(required: true, format: "+91 XXXX-XX-XXXX", translation: ["X": "[0-9]"]))
            let collectLicenseNumber = container?.create(input: collectLicenseNumberInput, options: Skyflow.CollectElementOptions(required: true, format: "X YYY YYY YY YY", translation: ["X": "[A-Z]","Y": "[0-9]"]))

            let collectButton = UIButton(frame: CGRect(x: 100, y: 400, width: 100, height: 40))
            collectButton.backgroundColor = .blue
            collectButton.setTitle("Submit", for: .normal)
            collectButton.addTarget(self, action: #selector(submitForm), for: .touchUpInside)
            self.revealContainer = skyflow?.container(type: Skyflow.ContainerType.REVEAL, options: nil)
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
        let revealCallback = Skyflow.RevealCallback(
            onSuccess: { response in print("reveal success:", response) },
            onFailure: { error in print("reveal failure:", error) }
        )
        self.revealContainer?.reveal(callback: revealCallback)
    }
    @objc func submitForm() {
        let collectCallback = Skyflow.CollectCallback(onSuccess: updateSuccess, onFailure: updateFailure)
        container!.collect(callback: collectCallback, options: Skyflow.CollectOptions())
    }
    internal func updateSuccess(_ response: Skyflow.CollectResponse) {
        print(response)
        for result in response.records {
            if let error = result.error {
                print("Record failed:", error, "httpCode:", result.httpCode)
            }
        }
        if let tokens = response.records.first?.tokens {
            updateRevealInputs(tokens: tokens)
        }
        print("Successfully got response:", response)
    }
    internal func updateFailure(error: Any) {
        print("Failed Operation", error)
    }
    // fields is [String: Any] - column name -> array of {"token","tokenGroupName"} dicts.
    internal func firstToken(_ fields: [String: Any], column: String) -> (token: String, tokenGroupName: String?) {
        guard let entries = fields[column] as? [[String: Any]], let first = entries.first else { return ("", nil) }
        return (first["token"] as? String ?? "", first["tokenGroupName"] as? String)
    }
    internal func updateRevealInputs(tokens: [String: Any]) {
        let revealBaseStyle = Skyflow.Style(
            borderColor: UIColor.black,
            cornerRadius: 20,
            padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5),
            borderWidth: 2,
            textAlignment: .left,
            textColor: UIColor.blue
        )
        let revealStyles = Skyflow.Styles(base: revealBaseStyle)
        DispatchQueue.main.async {
            if self.revealed {
                self.removeRevealElements()
            } else {
                self.revealed = true
            }
            let revealCardNumberInput = Skyflow.RevealElementInput(
                token: firstToken(tokens, column: "card_number").token ?? "",
                inputStyles: revealStyles,
                label: "Card Number"
            )
            self.revealCardNumber = self.revealContainer?.create(
                input: revealCardNumberInput,
                options: Skyflow.RevealElementOptions(format: "XXXX-XXXX-XXXX-XXXX-XXX", translation: ["X": "[0-9]"])
            )
            let revealCVVtInput = Skyflow.RevealElementInput(
                token: firstToken(tokens, column: "cvv").token ?? "",
                inputStyles: revealStyles,
                label: "CVV"
            )
            self.revealCVV = self.revealContainer?.create(input: revealCVVtInput)
            let revealNameInput = Skyflow.RevealElementInput(
                token: firstToken(tokens, column: "cardholder_name").token ?? "",
                inputStyles: revealStyles,
                label: "Card Holder Name"
            )
            self.revealName = self.revealContainer?.create(input: revealNameInput)
            let revealExpirationMonthInput = Skyflow.RevealElementInput(
                token: firstToken(tokens, column: "expiry_month").token ?? "",
                inputStyles: revealStyles,
                label: "Expiration Month"
            )
            self.revealExpirationMonth = self.revealContainer?.create(input: revealExpirationMonthInput)
            let revealExpirationYearInput = Skyflow.RevealElementInput(
                token: firstToken(tokens, column: "expiry_year").token ?? "",
                inputStyles: revealStyles,
                label: "Expiration Year"
            )
            self.revealExpirationYear = self.revealContainer?.create(input: revealExpirationYearInput)
            let revealSSNInput = Skyflow.RevealElementInput(
                token: firstToken(tokens, column: "ssn").token ?? "",
                inputStyles: revealStyles,
                label: "SSN"
            )
            self.revealSSN = self.revealContainer?.create(input: revealSSNInput, options: Skyflow.RevealElementOptions(format: "XXX XX XXXX", translation: ["X": "[0-9]"]))
            let revealPhoneNumberInput = Skyflow.RevealElementInput(
                token: firstToken(tokens, column: "phone_number").token ?? "",
                inputStyles: revealStyles,
                label: "Phone Number"
            )
            self.revealPhoneNumber = self.revealContainer?.create(input: revealPhoneNumberInput, options: Skyflow.RevealElementOptions(format: "+91 XXXX-XX-XXXX", translation: ["X": "[0-9]"]))
            let revealLicenseNumberInput = Skyflow.RevealElementInput(
                token: firstToken(tokens, column: "phone_number").token ?? "",
                inputStyles: revealStyles,
                label: "License Number"
            )
            self.revealLicenseNumber = self.revealContainer?.create(input: revealLicenseNumberInput, options: Skyflow.RevealElementOptions(format: "X YYY YYY YY YY", translation: ["X": "[A-Z]","Y": "[0-9]"]))
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
        self.revealContainer = self.skyflow?.container(type: Skyflow.ContainerType.REVEAL, options: nil)
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
