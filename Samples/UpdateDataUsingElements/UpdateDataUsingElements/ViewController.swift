/*
 * Copyright (c) 2022 Skyflow
 */

import UIKit
import Skyflow

class ViewController: UIViewController {
    var retryCount = 0
    private var skyflow: Skyflow.Client?
    private var container: Skyflow.Container<Skyflow.ComposableContainer>?
    private var b: UIButton?

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
                type: Skyflow.ElementType.CARD_NUMBER,
                skyflowID: "<SKYFLOW_ID>" // replace it with actual skyflowID if you want to test update with elements functionality, otherwise you can remove skyflowID field from input

            )
            let collectNameInput = Skyflow.CollectElementInput(
                table: "credit_cards",
                column: "cardholder_name",
                inputStyles: styles,
                label: "Card Holder Name",
                placeholder: "John Doe",
                type: Skyflow.ElementType.CARDHOLDER_NAME,
                skyflowID: "<SKYFLOW_ID>" // replace it with actual skyflowID if you want to test update with elements functionality, otherwise you can remove skyflowID field from input
            )
            let collectCVVInput = Skyflow.CollectElementInput(
                table: "credit_cards",
                column: "cvv",
                inputStyles: styles,
                label: "CVV",
                placeholder: "***",
                type: .CVV,
                skyflowID: "<SKYFLOW_ID>" // replace it with actual skyflowID if you want to test update with elements functionality, otherwise you can remove skyflowID field from input
            )
            let collectExpMonthInput = Skyflow.CollectElementInput(
                table: "credit_cards",
                column: "expiry_month",
                inputStyles: styles,
                label: "Expiration Month",
                placeholder: "MM",
                type: .EXPIRATION_MONTH,
                skyflowID: "<SKYFLOW_ID>" // replace it with actual skyflowID if you want to test update with elements functionality, otherwise you can remove skyflowID field from input

            )
            let collectExpYearInput = Skyflow.CollectElementInput(
                table: "credit_cards",
                column: "expiry_year",
                inputStyles: styles,
                label: "Expiration Year",
                placeholder: "YYYY",
                type: .EXPIRATION_YEAR,
                skyflowID: "<SKYFLOW_ID>" // replace it with actual skyflowID if you want to test update with elements functionality, otherwise you can remove skyflowID field from input

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

            do {
                let composableView = try container?.getComposableView()
                stackView.addArrangedSubview(composableView!)
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

    @objc func submitForm() {
        let exampleAPICallback = ExampleAPICallback(updateSuccess: updateSuccess, updateFailure: updateFailure)
        container!.collect(callback: exampleAPICallback, options: Skyflow.CollectOptions(tokens: true))
    }
    internal func updateSuccess(_ response: SuccessResponse) {
        print(response)
        retryCount = 0
        print("Successfully got response:", response)
    }
    internal func updateFailure(error: Any) {
        if((error as AnyObject).contains("Invalid Bearer token") && retryCount <= 2){ // To do, it will be replaced with error code in the future
            retryCount += 1
            submitForm()
        }
        print("Failed Operation", error)
    }
    
}
