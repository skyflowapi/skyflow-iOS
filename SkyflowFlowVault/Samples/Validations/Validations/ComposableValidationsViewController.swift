/*
 * Copyright (c) 2022 Skyflow
 */

// Reset Password - the same custom-validations example as CollectValidationsViewController,
// rendered through a ComposableContainer so both password fields share a single merged view.

import UIKit
import SkyflowFlowVault

class ComposableValidationsViewController: UIViewController {
    private var skyflowClient: SkyflowFlowVault.Client?
    private var container: SkyflowFlowVault.Container<SkyflowFlowVault.ComposableContainer>?
    private var outerStackView: UIStackView!

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
            tokenProvider: tokenProvider
        )
        self.skyflowClient = SkyflowFlowVault.initialize(config)
        guard let skyflow = self.skyflowClient else { return }

        // Two elements, one per row.
        let container = skyflow.container(
            type: SkyflowFlowVault.ContainerType.COMPOSABLE,
            options: SkyflowFlowVault.ContainerOptions(layout: [1, 1])
        )
        self.container = container

        let baseStyle = SkyflowFlowVault.Style(
            cornerRadius: 2,
            padding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10),
            borderWidth: 1,
            textAlignment: .left,
            textColor: .blue
        )
        let focusStyle = SkyflowFlowVault.Style(borderColor: .blue)
        let completedStyle = SkyflowFlowVault.Style(
            borderColor: UIColor.green,
            textColor: UIColor.green
        )
        let invalidStyle = SkyflowFlowVault.Style(
            borderColor: UIColor.red,
            textColor: UIColor.red
        )
        let styles = SkyflowFlowVault.Styles(
            base: baseStyle,
            complete: completedStyle,
            focus: focusStyle,
            invalid: invalidStyle
        )

        var myRuleset = ValidationSet()
        // This rule enforces a strong password
        let strongPasswordRule = RegexMatchRule(
            regex: "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]*$",
            error: "At least one letter and one number"
        )
        // This rule allows input length between 8 and 16 characters
        let lengthRule = LengthMatchRule(
            minLength: 4,
            maxLength: 8,
            error: "Must be between 4 and 8 digits"
        )
        // For the Password element
        myRuleset.add(rule: strongPasswordRule)
        myRuleset.add(rule: lengthRule)
        let collectElementOptions = CollectElementOptions(required: true)
        let passwordInput = CollectElementInput(
            inputStyles: styles,
            label: "password",
            placeholder: "********",
            type: .INPUT_FIELD,
            validations: myRuleset
        )
        let password = container?.create(
            input: passwordInput,
            options: collectElementOptions
        )
        // For confirm password element - shows error when the passwords don't match
        let elementValueMatchRule = ElementValueMatchRule(
            element: password!,
            error: "passwords don't match"
        )
        let confirmPasswordInput = CollectElementInput(
            inputStyles: styles,
            label: "Confirm password",
            placeholder: "********",
            type: .INPUT_FIELD,
            validations: ValidationSet(rules: [strongPasswordRule, lengthRule, elementValueMatchRule])
        )
        _ = container?.create(input: confirmPasswordInput, options: collectElementOptions)

        do {
            guard let composableView = try container?.getComposableView() else { return }

            self.outerStackView = UIStackView()
            outerStackView.addArrangedSubview(composableView)
            outerStackView.axis = .vertical
            outerStackView.distribution = .fill
            outerStackView.spacing = 10
            outerStackView.alignment = .fill
            outerStackView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(outerStackView)
            outerStackView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
            outerStackView.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor, constant: 10).isActive = true
            outerStackView.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: -10).isActive = true
        } catch {
            print("Failed to build composable view:", error)
        }
    }

    @objc func closeTapped() {
        dismiss(animated: true)
    }
}
