/*
 * Copyright (c) 2022 Skyflow
 */

import UIKit
import Skyflow

class CollectAndRevealViewController: UIViewController {
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


    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
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
            let requiredOption = Skyflow.CollectElementOptions(required: true, enableCopy: true)
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
        self.revealContainer?.reveal(callback: ExampleAPICallback())
    }
    @objc func submitForm() {
        let exampleAPICallback = ExampleAPICallback(updateSuccess: updateSuccess, updateFailure: updateFailure)
        container!.collect(callback: exampleAPICallback, options: Skyflow.CollectOptions(tokens: true))
    }
    internal func updateSuccess(_ response: SuccessResponse) {
        print(response)
        retryCount = 0
        updateRevealInputs(tokens: response.records[0].fields)
        print("Successfully got response:", response)
    }
    internal func updateFailure(error: Any) {
        if((error as AnyObject).contains("Invalid Bearer token") && retryCount <= 2){ // To do, it will be replaced with error code in the future
            retryCount += 1
            submitForm()
        }
        print("Failed Operation", error)
    }
    internal func updateRevealInputs(tokens: Fields) {
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
                token: tokens.card_number,
                inputStyles: revealStyles,
                label: "Card Number",
                redaction: .REDACTED
            )
            self.revealCardNumber = self.revealContainer?.create(
                input: revealCardNumberInput,
                options: Skyflow.RevealElementOptions()
            )
            let revealCVVtInput = Skyflow.RevealElementInput(
                token: tokens.cvv,
                inputStyles: revealStyles,
                label: "CVV",
                redaction: .MASKED
            )
            self.revealCVV = self.revealContainer?.create(input: revealCVVtInput)
            let revealNameInput = Skyflow.RevealElementInput(
                token: tokens.cardholder_name,
                inputStyles: revealStyles,
                label: "Card Holder Name",
                redaction: .DEFAULT

            )
            self.revealName = self.revealContainer?.create(input: revealNameInput)
            let revealExpirationMonthInput = Skyflow.RevealElementInput(
                token: tokens.expiry_month,
                inputStyles: revealStyles,
                label: "Expiration Month",
                redaction: .PLAIN_TEXT
            )
            self.revealExpirationMonth = self.revealContainer?.create(input: revealExpirationMonthInput)
            let revealExpirationYearInput = Skyflow.RevealElementInput(
                token: tokens.expiry_year,
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
