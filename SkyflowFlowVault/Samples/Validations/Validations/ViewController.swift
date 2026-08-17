/*
 * Copyright (c) 2022 Skyflow
 */

// Reset Password - A simple example that illustrates custom validations.
// The below code shows two input fields with custom validations,
// one to enter a password and the second to confirm the same password.

import UIKit
import SkyflowFlowVault

class ViewController: UIViewController {
    private var skyflowClient: SkyflowFlowVault.Client?
    private var container: SkyflowFlowVault.Container<SkyflowFlowVault.CollectContainer>?
    private var stackView: UIStackView!

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
            tokenProvider: tokenProvider
        )
        self.skyflowClient = SkyflowFlowVault.initialize(config)
        if self.skyflowClient != nil {
            let container = self.skyflowClient?.container(type: SkyflowFlowVault.ContainerType.COLLECT, options: nil)
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
                minLength: 8,
                maxLength: 16,
                error: "Must be between 8 and 16 digits"
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
            let confirmPassword = container?.create(input: confirmPasswordInput, options: collectElementOptions)
            // mount elements on screen - errors will be shown if any of the validaitons fail
            stackView.addArrangedSubview(password!)
            stackView.addArrangedSubview(confirmPassword!)
            stackView.axis = .vertical
            stackView.distribution = .fill
            stackView.spacing = 10
            stackView.alignment = .fill
            stackView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(stackView)
            stackView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 50).isActive = true
            stackView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 10).isActive = true
            stackView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -10).isActive = true
        }
    }
}
