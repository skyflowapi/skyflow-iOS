//
//  ComposableInputFormattingViewController.swift
//  InputFormatting
//
//  Created by Bharti Sagar  on 19/08/26.
//


/*
 * Copyright (c) 2022 Skyflow
 */

import UIKit
import SkyflowFlowVault

class ComposableInputFormattingViewController: UIViewController {
    private var skyflow: SkyflowFlowVault.Client?
    private var container: SkyflowFlowVault.Container<SkyflowFlowVault.ComposableContainer>?
    private var revealContainer: SkyflowFlowVault.Container<SkyflowFlowVault.RevealContainer>?

    private var outerStackView: UIStackView!
    private var submitButton: UIButton!

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
        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

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

        guard let skyflow = self.skyflow else { return }

        // One element per row - 8 entries, matching the 8 columns created below.
        let container = skyflow.container(type: SkyflowFlowVault.ContainerType.COMPOSABLE, options: SkyflowFlowVault.ContainerOptions(layout: [1, 1, 1, 1, 1, 1, 1, 1]))
        self.container = container

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
            tableName: "table", column: "card_number", inputStyles: styles,
            label: "Card Number", placeholder: "4111-1111-1111-1111", type: .CARD_NUMBER
        )
        let collectNameInput = SkyflowFlowVault.CollectElementInput(
            tableName: "table", column: "cardholder_name", inputStyles: styles,
            label: "Card Holder Name", placeholder: "John Doe", type: .CARDHOLDER_NAME
        )
        let collectCVVInput = SkyflowFlowVault.CollectElementInput(
            tableName: "table", column: "cvv", inputStyles: styles,
            label: "CVV", placeholder: "***", type: .CVV
        )
        let collectExpMonthInput = SkyflowFlowVault.CollectElementInput(
            tableName: "table", column: "expiry_month", inputStyles: styles,
            label: "Expiration Month", placeholder: "MM", type: .EXPIRATION_MONTH
        )
        let collectExpYearInput = SkyflowFlowVault.CollectElementInput(
            tableName: "table", column: "expiry_year", inputStyles: styles,
            label: "Expiration Year", placeholder: "YYYY", type: .EXPIRATION_YEAR
        )
        let collectSSNInput = SkyflowFlowVault.CollectElementInput(
            tableName: "table", column: "ssn", inputStyles: styles,
            label: "SSN", placeholder: "XXX-XX-XXXX", type: .INPUT_FIELD
        )
        let collectPhoneNumberInput = SkyflowFlowVault.CollectElementInput(
            tableName: "table", column: "phone_number", inputStyles: styles,
            label: "Phone Number", placeholder: "+91 XXXX-XX-XXXX", type: .INPUT_FIELD
        )
        let collectLicenseNumberInput = SkyflowFlowVault.CollectElementInput(
            tableName: "table", column: "license_number", inputStyles: styles,
            label: "License Number", placeholder: "X YYY YYY YY YY", type: .INPUT_FIELD
        )

        _ = container?.create(input: collectCardNumberInput, options: SkyflowFlowVault.CollectElementOptions(required: true, format: "XXXX-XXXX-XXXX-XXXX"))
        _ = container?.create(input: collectNameInput, options: SkyflowFlowVault.CollectElementOptions(required: true))
        _ = container?.create(input: collectCVVInput, options: SkyflowFlowVault.CollectElementOptions(required: true))
        _ = container?.create(input: collectExpMonthInput, options: SkyflowFlowVault.CollectElementOptions(required: true))
        _ = container?.create(input: collectExpYearInput, options: SkyflowFlowVault.CollectElementOptions(required: true))
        _ = container?.create(input: collectSSNInput, options: SkyflowFlowVault.CollectElementOptions(required: true, format: "XXX-XX-XXXX", translation: ["X": "[0-9]"]))
        _ = container?.create(input: collectPhoneNumberInput, options: SkyflowFlowVault.CollectElementOptions(required: true, format: "+91 XXXX-XX-XXXX", translation: ["X": "[0-9]"]))
        _ = container?.create(input: collectLicenseNumberInput, options: SkyflowFlowVault.CollectElementOptions(required: true, format: "X YYY YYY YY YY", translation: ["X": "[A-Z]", "Y": "[0-9]"]))

        self.revealContainer = skyflow.container(type: SkyflowFlowVault.ContainerType.REVEAL, options: nil)

        self.submitButton = UIButton(frame: CGRect(x: 100, y: 400, width: 100, height: 40))
        submitButton.backgroundColor = .blue
        submitButton.setTitle("Submit", for: .normal)
        submitButton.addTarget(self, action: #selector(submitForm), for: .touchUpInside)

        self.revealButton = UIButton(frame: CGRect(x: 100, y: 400, width: 100, height: 40))
        revealButton.backgroundColor = .blue
        revealButton.setTitle("Reveal", for: .normal)
        revealButton.addTarget(self, action: #selector(revealForm), for: .touchUpInside)

        do {
            guard let composableView = try container?.getComposableView() else { return }

            self.outerStackView = UIStackView()
            outerStackView.addArrangedSubview(composableView)
            outerStackView.addArrangedSubview(submitButton)
            outerStackView.axis = .vertical
            outerStackView.distribution = .fill
            outerStackView.spacing = 10
            outerStackView.alignment = .fill
            outerStackView.translatesAutoresizingMaskIntoConstraints = false

            let scrollView = UIScrollView(frame: .zero)
            scrollView.isScrollEnabled = true
            scrollView.backgroundColor = .white
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(scrollView)
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
            scrollView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 10).isActive = true
            scrollView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10).isActive = true
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true

            scrollView.addSubview(outerStackView)
            outerStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -10).isActive = true
            outerStackView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
            outerStackView.leftAnchor.constraint(equalTo: scrollView.leftAnchor).isActive = true
            outerStackView.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -10).isActive = true
            outerStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        } catch {
            print("Failed to build composable view:", error)
        }
    }

    @objc func closeTapped() {
        dismiss(animated: true)
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
        container?.collect(
            callback: CollectCallback(
                onSuccess: { [weak self] (response: CollectResponse) in self?.updateSuccess(response) },
                onFailure: { [weak self] (error: SkyflowError) in self?.updateFailure(error: error) }
            ),
            options: SkyflowFlowVault.CollectOptions()
        )
    }

    internal func updateSuccess(_ response: CollectResponse) {
        if let record = response.records.first {
            updateRevealInputs(record: record)
        }
        print("Successfully got response:", response)
    }

    internal func updateFailure(error: SkyflowError) {
        print("Failed Operation", error)
    }

    internal func updateRevealInputs(record: CollectRecord) {
        func token(for column: String) -> String {
            record.tokens?[column]?.first?.token ?? ""
        }
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
            self.revealCardNumber = self.revealContainer?.create(
                input: SkyflowFlowVault.RevealElementInput(token: token(for: "card_number"), inputStyles: revealStyles, label: "Card Number"),
                options: SkyflowFlowVault.RevealElementOptions(format: "XXXX-XXXX-XXXX-XXXX-XXX", translation: ["X": "[0-9]"])
            )
            self.revealCVV = self.revealContainer?.create(
                input: SkyflowFlowVault.RevealElementInput(token: token(for: "cvv"), inputStyles: revealStyles, label: "CVV")
            )
            self.revealName = self.revealContainer?.create(
                input: SkyflowFlowVault.RevealElementInput(token: token(for: "cardholder_name"), inputStyles: revealStyles, label: "Card Holder Name")
            )
            self.revealExpirationMonth = self.revealContainer?.create(
                input: SkyflowFlowVault.RevealElementInput(token: token(for: "expiry_month"), inputStyles: revealStyles, label: "Expiration Month")
            )
            self.revealExpirationYear = self.revealContainer?.create(
                input: SkyflowFlowVault.RevealElementInput(token: token(for: "expiry_year"), inputStyles: revealStyles, label: "Expiration Year")
            )
            self.revealSSN = self.revealContainer?.create(
                input: SkyflowFlowVault.RevealElementInput(token: token(for: "ssn"), inputStyles: revealStyles, label: "SSN"),
                options: SkyflowFlowVault.RevealElementOptions(format: "XXX XX XXXX", translation: ["X": "[0-9]"])
            )
            self.revealPhoneNumber = self.revealContainer?.create(
                input: SkyflowFlowVault.RevealElementInput(token: token(for: "phone_number"), inputStyles: revealStyles, label: "Phone Number"),
                options: SkyflowFlowVault.RevealElementOptions(format: "+91 XXXX-XX-XXXX", translation: ["X": "[0-9]"])
            )
            self.revealLicenseNumber = self.revealContainer?.create(
                input: SkyflowFlowVault.RevealElementInput(token: token(for: "license_number"), inputStyles: revealStyles, label: "License Number"),
                options: SkyflowFlowVault.RevealElementOptions(format: "X YYY YYY YY YY", translation: ["X": "[A-Z]", "Y": "[0-9]"])
            )
            self.addRevealElements()
        }
    }

    internal func removeRevealElements() {
        self.outerStackView.removeArrangedSubview(self.revealCardNumber!)
        self.outerStackView.removeArrangedSubview(self.revealName!)
        self.outerStackView.removeArrangedSubview(self.revealCVV!)
        self.outerStackView.removeArrangedSubview(self.revealExpirationMonth!)
        self.outerStackView.removeArrangedSubview(self.revealExpirationYear!)
        self.outerStackView.removeArrangedSubview(self.revealSSN!)
        self.outerStackView.removeArrangedSubview(self.revealPhoneNumber!)
        self.outerStackView.removeArrangedSubview(self.revealLicenseNumber!)
        self.outerStackView.removeArrangedSubview(self.revealButton)
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
            self.outerStackView.addArrangedSubview(self.revealCardNumber!)
            self.outerStackView.addArrangedSubview(self.revealName!)
            self.outerStackView.addArrangedSubview(self.revealCVV!)
            self.outerStackView.addArrangedSubview(self.revealExpirationMonth!)
            self.outerStackView.addArrangedSubview(self.revealExpirationYear!)
            self.outerStackView.addArrangedSubview(self.revealSSN!)
            self.outerStackView.addArrangedSubview(self.revealPhoneNumber!)
            self.outerStackView.addArrangedSubview(self.revealLicenseNumber!)
            self.outerStackView.addArrangedSubview(self.revealButton)
        }
    }
}
