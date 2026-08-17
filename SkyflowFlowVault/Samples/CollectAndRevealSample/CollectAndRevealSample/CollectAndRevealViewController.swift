/*
 * Copyright (c) 2022 Skyflow
 */

import UIKit
import SkyflowFlowVault

class CollectAndRevealViewController: UIViewController {
    var retryCount = 0
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
    private var revealButton: UIButton!

    private var revealed = false


    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
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
                table: "credit_cards",
                column: "card_number",
                inputStyles: styles,
                label: "Card Number",
                placeholder: "4111-1111-1111-1111",
                type: SkyflowFlowVault.ElementType.CARD_NUMBER
            )
            let collectNameInput = SkyflowFlowVault.CollectElementInput(
                table: "credit_cards",
                column: "cardholder_name",
                inputStyles: styles,
                label: "Card Holder Name",
                placeholder: "John Doe",
                type: SkyflowFlowVault.ElementType.CARDHOLDER_NAME
            )
            let collectCVVInput = SkyflowFlowVault.CollectElementInput(
                table: "credit_cards",
                column: "cvv",
                inputStyles: styles,
                label: "CVV",
                placeholder: "***",
                type: .CVV
            )
            let collectExpMonthInput = SkyflowFlowVault.CollectElementInput(
                table: "credit_cards",
                column: "expiry_month",
                inputStyles: styles,
                label: "Expiration Month",
                placeholder: "MM",
                type: .EXPIRATION_MONTH
            )
            let collectExpYearInput = SkyflowFlowVault.CollectElementInput(
                table: "credit_cards",
                column: "expiry_year",
                inputStyles: styles,
                label: "Expiration Year",
                placeholder: "YYYY",
                type: .EXPIRATION_YEAR
            )
            let requiredOption = SkyflowFlowVault.CollectElementOptions(required: true, enableCopy: true)
            let collectCardNumber = container?.create(input: collectCardNumberInput, options: requiredOption)
            let collectName = container?.create(input: collectNameInput, options: requiredOption)
            let collectCVV = container?.create(input: collectCVVInput, options: requiredOption)
            let collectExpMonth = container?.create(input: collectExpMonthInput, options: requiredOption)
            let collectExpYear = container?.create(input: collectExpYearInput, options: requiredOption)
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
            stackView.addArrangedSubview(collectButton)
  
            stackView.axis = .vertical
            stackView.distribution = .fill
            stackView.spacing = 5
            stackView.alignment = .fill
            stackView.translatesAutoresizingMaskIntoConstraints = false
            
            let scrollView = UIScrollView(frame: .zero)
            scrollView.isScrollEnabled = true
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(scrollView)
            
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 2).isActive = true
            scrollView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 2).isActive = true
            scrollView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10).isActive = true
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
            
            scrollView.addSubview(stackView)
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -10).isActive = true
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
            stackView.leftAnchor.constraint(equalTo: scrollView.leftAnchor).isActive = true
            stackView.rightAnchor.constraint(equalTo: scrollView.rightAnchor).isActive = true
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        }
    }
    @objc func revealForm() {
        self.revealContainer?.reveal(
            callback: RevealCallback(
                onSuccess: { (response: RevealResponse) in print("success:", response) },
                onFailure: { (error: SkyflowError) in print("failure:", error) }
            )
        )
    }
    @objc func submitForm() {
        container!.collect(
            callback: CollectCallback(
                onSuccess: { [weak self] (response: CollectResponse) in self?.updateSuccess(response) },
                onFailure: { [weak self] (error: SkyflowError) in self?.updateFailure(error: error) }
            ),
            options: SkyflowFlowVault.CollectOptions(tokens: true)
        )
    }
    internal func updateSuccess(_ response: CollectResponse) {
        print(response)
        retryCount = 0
        if let record = response.records.first {
            updateRevealInputs(record: record)
        }
        print("Successfully got response:", response)
    }
    internal func updateFailure(error: SkyflowError) {
        if error.message.contains("Invalid Bearer token") && retryCount <= 2 { // To do, it will be replaced with error code in the future
            retryCount += 1
            submitForm()
        }
        print("Failed Operation", error)
    }
    internal func updateRevealInputs(record: CollectRecord) {
        let revealBaseStyle = SkyflowFlowVault.Style(
            borderColor: UIColor.black,
            cornerRadius: 20,
            padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5),
            borderWidth: 2,
            textAlignment: .left,
            textColor: UIColor.blue
        )
        let revealStyles = SkyflowFlowVault.Styles(base: revealBaseStyle)
        // A column maps to a list of Token(token:tokenGroupName:) - there's just one token
        // group configured for these columns here, so take the first.
        func token(for column: String) -> String {
            record.tokens?[column]?.first?.token ?? ""
        }
        DispatchQueue.main.async {
            if self.revealed {
                self.removeRevealElements()
            } else {
                self.revealed = true
            }
            let revealCardNumberInput = SkyflowFlowVault.RevealElementInput(
                token: token(for: "card_number"),
                inputStyles: revealStyles,
                label: "Card Number",
                redaction: .REDACTED
            )
            self.revealCardNumber = self.revealContainer?.create(
                input: revealCardNumberInput,
                options: SkyflowFlowVault.RevealElementOptions()
            )
            let revealCVVtInput = SkyflowFlowVault.RevealElementInput(
                token: token(for: "cvv"),
                inputStyles: revealStyles,
                label: "CVV",
                redaction: .MASKED
            )
            self.revealCVV = self.revealContainer?.create(input: revealCVVtInput)
            let revealNameInput = SkyflowFlowVault.RevealElementInput(
                token: token(for: "cardholder_name"),
                inputStyles: revealStyles,
                label: "Card Holder Name",
                redaction: .DEFAULT

            )
            self.revealName = self.revealContainer?.create(input: revealNameInput)
            let revealExpirationMonthInput = SkyflowFlowVault.RevealElementInput(
                token: token(for: "expiry_month"),
                inputStyles: revealStyles,
                label: "Expiration Month",
                redaction: .PLAIN_TEXT
            )
            self.revealExpirationMonth = self.revealContainer?.create(input: revealExpirationMonthInput)
            let revealExpirationYearInput = SkyflowFlowVault.RevealElementInput(
                token: token(for: "expiry_year"),
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
        self.revealContainer = self.skyflow?.container(type: SkyflowFlowVault.ContainerType.REVEAL, options: nil)
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
