/*
 * Copyright (c) 2022 Skyflow
 */

import UIKit
import SkyflowFlowVault

class ViewController: UIViewController {
    private var skyflow: SkyflowFlowVault.Client?
    private var container: SkyflowFlowVault.Container<SkyflowFlowVault.CollectContainer>?
    private var revealContainer: SkyflowFlowVault.Container<SkyflowFlowVault.RevealContainer>?
    private var stackView: UIStackView!
    private var revealCardNumber: Label?
    private var revealCvv: Label?
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
        let config = SkyflowFlowVault.Configuration(vaultID: "VAULT_ID", vaultURL: "VAULT_URL", tokenProvider: tokenProvider)
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
            let completedStyle = SkyflowFlowVault.Style(borderColor: UIColor.green, textColor: UIColor.green)
            let invalidStyle = SkyflowFlowVault.Style(borderColor: UIColor.red, textColor: UIColor.red)
            let styles = SkyflowFlowVault.Styles(
                base: baseStyle,
                complete: completedStyle,
                focus: focusStyle,
                invalid: invalidStyle
            )
            let baseStyleL = SkyflowFlowVault.Style(
                cornerRadius: 2,
                padding: UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 10),
                borderWidth: 1,
                textAlignment: .left
            )
            let focusStyleL = SkyflowFlowVault.Style(borderColor: .yellow)
            let completedStyleL = SkyflowFlowVault.Style(borderColor: UIColor.green, textColor: UIColor.green)
            let invalidStyleL = SkyflowFlowVault.Style(borderColor: UIColor.red, textColor: UIColor.red)
            let labelStyles = SkyflowFlowVault.Styles(
                base: baseStyleL,
                complete: completedStyleL,
                focus: focusStyleL,
                invalid: invalidStyleL
            )
            let baseStyleE = SkyflowFlowVault.Style(
                cornerRadius: 2,
                padding: UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 10),
                borderWidth: 1,
                textAlignment: .left,
                textColor: .orange
            )

            let focusStyleE = SkyflowFlowVault.Style(borderColor: .yellow, textAlignment: .right, textColor: .yellow)

            let completedStyleE = SkyflowFlowVault.Style(borderColor: UIColor.green, textColor: UIColor.green)

            let invalidStyleE = SkyflowFlowVault.Style(borderColor: UIColor.red, textColor: UIColor.red)
            let errorStyles = SkyflowFlowVault.Styles(
                base: baseStyleE,
                complete: completedStyleL,
                focus: focusStyleE,
                invalid: invalidStyleE
            )
            // keep card number as unique column for testing upsert feature
            let collectCardNumberInput = SkyflowFlowVault.CollectElementInput(
                tableName: "persons",
                column: "cardnumber",
                inputStyles: styles,
                labelStyles: labelStyles,
                errorTextStyles: errorStyles,
                label: "Card Number",
                placeholder: "4111-1111-1111-1111",
                type: SkyflowFlowVault.ElementType.CARD_NUMBER
            )
            let requiredOption = SkyflowFlowVault.CollectElementOptions(required: true)
            let collectCardNumber = container?.create(input: collectCardNumberInput, options: requiredOption)
            let collectCvvInput = SkyflowFlowVault.CollectElementInput(
                tableName: "persons",
                column: "cvv",
                inputStyles: styles,
                label: "Cvv",
                placeholder: "123",
                type: SkyflowFlowVault.ElementType.CVV
            )
            let collectCvv = container?.create(input: collectCvvInput, options: requiredOption)
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
            stackView.addArrangedSubview(collectCvv!)
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
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
            scrollView.addSubview(stackView)
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -10).isActive = true
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
            stackView.leftAnchor.constraint(equalTo: scrollView.leftAnchor).isActive = true
            stackView.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -10).isActive = true
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        }
    }

    @objc func revealForm() {
        self.revealContainer?.reveal(
            callback: RevealCallback(
                onSuccess: { (response: RevealResponse) in print("success:", response) },
                onFailure: { (error: SkyflowError) in print("failure:", error) }
            ),
            options: SkyflowFlowVault.RevealOptions(tokenGroupRedactions: [
                SkyflowFlowVault.TokenGroupRedaction(tokenGroupName: "<TOKEN_GROUP_NAME>", redaction: "<REDACTION_TYPE>")
            ])
        )
    }

    @objc func submitForm() {
        container!.collect(
            callback: CollectCallback(
                onSuccess: { [weak self] (response: CollectResponse) in self?.updateSuccess(response) },
                onFailure: { [weak self] (_: SkyflowError) in self?.updateFailure() }
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

    internal func updateFailure() {
        print("Failed Operation")
    }

    internal func updateRevealInputs(record: CollectRecord) {
        // A column maps to a list of Token(token:tokenGroupName:) - there's just one token
        // group configured for these columns here, so take the first.
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
            let revealCardNumberInput = SkyflowFlowVault.RevealElementInput(
                token: token(for: "cardnumber"),
                inputStyles: revealStyles,
                label: "Card Number"
            )
            self.revealCardNumber = self.revealContainer?.create(
                input: revealCardNumberInput,
                options: SkyflowFlowVault.RevealElementOptions()
            )
            let revealCvvInput = SkyflowFlowVault.RevealElementInput(
                token: token(for: "cvv"),
                inputStyles: revealStyles,
                label: "Cvv"
            )
            self.revealCvv = self.revealContainer?.create(
                input: revealCvvInput,
                options: SkyflowFlowVault.RevealElementOptions()
            )
            self.addRevealElements()
        }
    }

    internal func removeRevealElements() {
        self.stackView.removeArrangedSubview(self.revealCardNumber!)
        self.stackView.removeArrangedSubview(self.revealCvv!)
        self.stackView.removeArrangedSubview(self.revealButton)
        self.revealCardNumber?.removeFromSuperview()
        self.revealButton.removeFromSuperview()
        self.revealContainer = self.skyflow?.container(type: SkyflowFlowVault.ContainerType.REVEAL, options: nil)
    }

    internal func addRevealElements() {
        DispatchQueue.main.async {
            self.stackView.addArrangedSubview(self.revealCardNumber!)
            self.stackView.addArrangedSubview(self.revealCvv!)
            self.stackView.addArrangedSubview(self.revealButton)
        }
    }
}
