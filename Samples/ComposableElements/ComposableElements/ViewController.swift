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
    private var stackView1: UIStackView!
    private var stackView2: UIStackView!
    private var stackView3: UIStackView!


    private var revealCVV: Label?
    private var revealCardNumber: Label?
    private var revealName: Label?
    private var revealExpirationMonth: Label?
    private var revealExpirationYear: Label?
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
            self.stackView1 = UIStackView()
            self.stackView2 = UIStackView()
            self.stackView3 = UIStackView()
            let uiFont = UIFont.systemFont(ofSize: 15, weight: .light)

            let labelStyle = Skyflow.Style(borderColor: UIColor.black, padding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), font: uiFont ,textColor: UIColor.black)
            let labelStyles  = Skyflow.Styles(base: labelStyle, requiredAstrisk: labelStyle)


            let collectCardNumberInput = Skyflow.CollectElementInput(
                table: "credit_cards",
                column: "card_number",
                labelStyles: labelStyles,
                label: "Card Number",
                placeholder: "4111111111111111",
                type: Skyflow.ElementType.CARD_NUMBER
            )
            let collectNameInput = Skyflow.CollectElementInput(
                table: "credit_cards",
                column: "cardholder_name",
                labelStyles: labelStyles,
                label: "Card Holder Name",
                placeholder: "John Doe",
                type: Skyflow.ElementType.CARDHOLDER_NAME
            )
            let collectCVVInput = Skyflow.CollectElementInput(
                table: "credit_cards",
                column: "cvv",
                labelStyles: labelStyles,
                label: "CVV",
                placeholder: "***",
                type: .CVV
            )
            let collectExpDateInput = Skyflow.CollectElementInput(
                table: "credit_cards",
                column: "expiry_month",
                labelStyles: labelStyles,
                label: "Expiry Date",
                placeholder: "MM/YY",
                type: .EXPIRATION_DATE
            )
            let requiredOption = Skyflow.CollectElementOptions(required: true)
            let collectCardNumber = container?.create(input: collectCardNumberInput, options: requiredOption)
            let collectName = (container?.create(input: collectNameInput, options: requiredOption))!
            let collectCVV = container?.create(input: collectCVVInput, options: requiredOption)
            let collectExpDate = container?.create(input: collectExpDateInput, options: requiredOption)
            
            collectCardNumber!.on(eventName: Skyflow.EventName.CHANGE){ [self] state in
                if( state["isValid"] as! Bool == true && state["isEmpty"] as! Bool != true) {
                    collectExpDate!.becomeFirstResponder()
                }

            }
            collectExpDate!.on(eventName: Skyflow.EventName.CHANGE ){ [self] state in
                if( state["isValid"] as! Bool == true && state["isEmpty"] as! Bool != true) {
                    collectCVV!.becomeFirstResponder()
                }
                if(state["isEmpty"] as! Bool == true && state["isFocused"] as! Bool == true) {
                    collectCardNumber!.becomeFirstResponder()
                }
            }
            collectCVV!.on(eventName: Skyflow.EventName.CHANGE){ [self] state in
                if(state["isEmpty"] as! Bool == true && state["isFocused"] as! Bool == true) {
                    collectExpDate!.becomeFirstResponder()
                }

            }
            
            let collectButton = UIButton(frame: CGRect(x: 100, y: 400, width: 100, height: 40))
            collectButton.backgroundColor = .blue
            collectButton.setTitle("Submit", for: .normal)
            collectButton.addTarget(self, action: #selector(submitForm), for: .touchUpInside)
            self.revealContainer = skyflow?.container(type: Skyflow.ContainerType.REVEAL, options: nil)
            self.revealButton = UIButton(frame: CGRect(x: 100, y: 400, width: 100, height: 40))
            revealButton.backgroundColor = .blue
            revealButton.setTitle("Reveal", for: .normal)
            revealButton.addTarget(self, action: #selector(revealForm), for: .touchUpInside)
            stackView1.addArrangedSubview(collectCardNumber!)
            stackView1.addArrangedSubview(collectExpDate!)
            stackView1.addArrangedSubview(collectCVV!)
            
            stackView3.addArrangedSubview(collectButton)
            
            stackView1.axis = .horizontal
            stackView1.distribution = .fill
            stackView1.spacing = 0.5
            stackView1.alignment = .fill
            stackView1.translatesAutoresizingMaskIntoConstraints = false
            
            stackView2.addArrangedSubview(collectName)

            stackView2.axis = .vertical
            stackView2.distribution = .fill
            stackView2.spacing = 0.5
            stackView2.alignment = .fill
            stackView2.translatesAutoresizingMaskIntoConstraints = false
            
            stackView3.axis = .vertical
            stackView3.distribution = .fill
            stackView3.spacing = 0.5
            stackView3.alignment = .fill
            stackView3.translatesAutoresizingMaskIntoConstraints = false
  
            
            // Add the horizontal stack view to the stack view
            stackView.addArrangedSubview(stackView2)

            // Add the vertical stack view to the stack view
            stackView.addArrangedSubview(stackView1)
            
            let scrollView = UIScrollView(frame: .zero)
            scrollView.isScrollEnabled = true
            scrollView.backgroundColor = .white
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(stackView2)
            scrollView.addSubview(stackView1)
            scrollView.addSubview(stackView3)

            view.addSubview(scrollView)

            scrollView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 20
            ).isActive = true
            scrollView.leftAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leftAnchor,
                constant: 2
            ).isActive = true
            scrollView.rightAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.rightAnchor,
                constant: -10
            ).isActive = true
            scrollView.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor
            ).isActive = true
                        
            stackView2.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -10).isActive = true
            stackView2.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 10).isActive = true
            stackView2.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 3).isActive = true
            
//             Set constraints for stackView2
            stackView1.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -10).isActive = true
            stackView1.topAnchor.constraint(equalTo: stackView2.bottomAnchor, constant: 10).isActive = true
            stackView1.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 3).isActive = true
            stackView1.rightAnchor.constraint(equalTo: scrollView.rightAnchor).isActive = true
            
            stackView3.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -10).isActive = true
            stackView3.topAnchor.constraint(equalTo: stackView1.bottomAnchor, constant: 10).isActive = true
            stackView3.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 3).isActive = true



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
