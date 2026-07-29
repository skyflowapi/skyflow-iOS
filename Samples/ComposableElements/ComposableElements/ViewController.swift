/*
 * Copyright (c) 2022 Skyflow
 */

import UIKit
import Skyflow

class ViewController: UIViewController {
    var retryCount = 0
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
    private var revealButton: UIButton!

    private var revealed = false
    private var tokenGroupRedactions: [Skyflow.TokenGroupRedaction] = []

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
            let container = self.skyflow?.container(type: Skyflow.ContainerType.COMPOSABLE, options: ContainerOptions(layout: [1,2,2], styles: Styles(base: Style(borderColor: UIColor.gray) ), errorTextStyles: Styles(base: Style(textColor: UIColor.red) )))
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
                table: "credit_cards",
                column: "card_number",
                inputStyles: styles,
                label: "Card Number",
                placeholder: "4111-1111-1111-1111",
                type: Skyflow.ElementType.CARD_NUMBER
            )
            let collectNameInput = Skyflow.CollectElementInput(
                table: "credit_cards",
                column: "cardholder_name",
                inputStyles: styles,
                label: "Card Holder Name",
                placeholder: "John Doe",
                type: Skyflow.ElementType.CARDHOLDER_NAME
            )
            let collectCVVInput = Skyflow.CollectElementInput(
                table: "credit_cards",
                column: "cvv",
                inputStyles: styles,
                label: "CVV",
                placeholder: "***",
                type: .CVV
            )
            let collectExpMonthInput = Skyflow.CollectElementInput(
                table: "credit_cards",
                column: "expiry_month",
                inputStyles: styles,
                label: "Expiration Month",
                placeholder: "MM",
                type: .EXPIRATION_MONTH
            )
            let collectExpYearInput = Skyflow.CollectElementInput(
                table: "credit_cards",
                column: "expiry_year",
                inputStyles: styles,
                label: "Expiration Year",
                placeholder: "YYYY",
                type: .EXPIRATION_YEAR
            )
            let requiredOption = Skyflow.CollectElementOptions(required: true)
            let collectCardNumber = container?.create(input: collectCardNumberInput, options: requiredOption)
            let collectName = container?.create(input: collectNameInput, options: requiredOption)
            let collectCVV = container?.create(input: collectCVVInput, options: requiredOption)
            let collectExpMonth = container?.create(input: collectExpMonthInput, options: requiredOption)
            let collectExpYear = container?.create(input: collectExpYearInput, options: requiredOption)
            let collectButton = UIButton(frame: CGRect(x: 100, y: 400, width: 100, height: 40))
            collectButton.backgroundColor = .blue
            collectButton.setTitle("Submit", for: .normal)
            collectButton.addTarget(self, action: #selector(submitForm), for: .touchUpInside)
            self.revealContainer = skyflow?.container(type: Skyflow.ContainerType.REVEAL, options: nil)
            self.revealButton = UIButton(frame: CGRect(x: 100, y: 400, width: 100, height: 40))
            revealButton.backgroundColor = .blue
            revealButton.setTitle("Reveal", for: .normal)
            revealButton.addTarget(self, action: #selector(revealForm), for: .touchUpInside)

            do {
                let composableView = try container?.getComposableView()
                stackView.addArrangedSubview(composableView)
            } catch {
                print(error)
            }

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
        let revealOptions = Skyflow.RevealOptions(tokenGroupRedactions: self.tokenGroupRedactions.isEmpty ? nil : self.tokenGroupRedactions)
        self.revealContainer?.reveal(callback: revealCallback, options: revealOptions)
    }
    @objc func submitForm() {
        let collectCallback = Skyflow.CollectCallback(onSuccess: updateSuccess, onFailure: updateFailure)

        // Upsert example: insert-or-update credit_cards records, matching on card_number.
        // If a record with a matching card_number already exists, its fields are merged
        // in (updateType: .UPDATE) instead of creating a duplicate row.
        let upsertOptions = [
            Skyflow.UpsertOption(table: "credit_cards", uniqueColumns: ["card_number"], updateType: .UPDATE)
        ]

        // additionalFields: extra records submitted alongside whatever's collected from
        // the mounted elements, one entry per table.
        let additionalFields = Skyflow.AdditionalFields(records: [
            Skyflow.AdditionalFieldsRecord(table: "credit_cards", fields: ["billing_zip": "94105"])
        ])

        container!.collect(callback: collectCallback, options: Skyflow.CollectOptions(additionalFields: additionalFields, upsert: upsertOptions))
    }
    internal func updateSuccess(_ response: Skyflow.CollectResponse) {
        print(response)
        retryCount = 0
        for result in response.records {
            if let error = result.error {
                print("Record failed:", error, "httpCode:", result.httpCode)
            }
        }
        if let fields = response.records.first?.fields {
            updateRevealInputs(tokens: fields)
        }
        print("Successfully got response:", response)
    }
    internal func updateFailure(error: Any) {
        if((error as AnyObject).contains("Invalid Bearer token") && retryCount <= 2){ // To do, it will be replaced with error code in the future
            retryCount += 1
            submitForm()
        }
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
            // tokenGroupRedactions: request-level redaction per token group, applied when
            // reveal() is called (see revealForm()) - not per reveal element.
            self.tokenGroupRedactions = []
            func addTokenGroupRedaction(_ redaction: String, forColumn column: String) {
                if let tokenGroupName = self.firstToken(tokens, column: column).tokenGroupName {
                    self.tokenGroupRedactions.append(Skyflow.TokenGroupRedaction(tokenGroupName: tokenGroupName, redaction: redaction))
                }
            }
            addTokenGroupRedaction("REDACTED", forColumn: "card_number")
            addTokenGroupRedaction("MASKED", forColumn: "cvv")
            addTokenGroupRedaction("DEFAULT", forColumn: "cardholder_name")
            addTokenGroupRedaction("PLAIN_TEXT", forColumn: "expiry_month")

            let revealCardNumberInput = Skyflow.RevealElementInput(
                token: self.firstToken(tokens, column: "card_number").token ?? "",
                inputStyles: revealStyles,
                label: "Card Number"
            )
            self.revealCardNumber = self.revealContainer?.create(
                input: revealCardNumberInput,
                options: Skyflow.RevealElementOptions()
            )
            let revealCVVtInput = Skyflow.RevealElementInput(
                token: self.firstToken(tokens, column: "cvv").token ?? "",
                inputStyles: revealStyles,
                label: "CVV"
            )
            self.revealCVV = self.revealContainer?.create(input: revealCVVtInput)
            let revealNameInput = Skyflow.RevealElementInput(
                token: self.firstToken(tokens, column: "cardholder_name").token ?? "",
                inputStyles: revealStyles,
                label: "Card Holder Name"
            )
            self.revealName = self.revealContainer?.create(input: revealNameInput)
            let revealExpirationMonthInput = Skyflow.RevealElementInput(
                token: self.firstToken(tokens, column: "expiry_month").token ?? "",
                inputStyles: revealStyles,
                label: "Expiration Month"
            )
            self.revealExpirationMonth = self.revealContainer?.create(input: revealExpirationMonthInput)
            let revealExpirationYearInput = Skyflow.RevealElementInput(
                token: self.firstToken(tokens, column: "expiry_year").token ?? "",
                inputStyles: revealStyles,
                label: "Expiration Year"
            )
            self.revealExpirationYear = self.revealContainer?.create(input: revealExpirationYearInput)
            self.addRevealElements()
        }
    }

    internal func removeRevealElements() {
        self.stackView.removeArrangedSubview(self.revealCardNumber!)
        self.stackView.removeArrangedSubview(self.revealName!)
        self.stackView.removeArrangedSubview(self.revealCVV!)
        self.stackView.removeArrangedSubview(self.revealExpirationMonth!)
        self.stackView.removeArrangedSubview(self.revealExpirationYear!)
        self.stackView.removeArrangedSubview(self.revealButton)
        self.revealCardNumber?.removeFromSuperview()
        self.revealName?.removeFromSuperview()
        self.revealCVV?.removeFromSuperview()
        self.revealExpirationMonth?.removeFromSuperview()
        self.revealExpirationYear?.removeFromSuperview()
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
            self.stackView.addArrangedSubview(self.revealButton)
        }
    }
}
