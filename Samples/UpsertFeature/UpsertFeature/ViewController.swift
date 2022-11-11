/*
 * Copyright (c) 2022 Skyflow
*/

//
//  ViewController.swift
//  App
//
//  Created by Tejesh Reddy Allampati on 16/09/21.
//


import UIKit
import Skyflow



class ViewController: UIViewController {
    
    
    private var skyflow: Skyflow.Client?
    private var container: Skyflow.Container<Skyflow.CollectContainer>?
    private var revealContainer: Skyflow.Container<Skyflow.RevealContainer>?
    private var b: UIButton?
    
    private var stackView: UIStackView!
    
    private var revealCardNumber: Label?
    private var revealCvv: Label?
    private var revealButton: UIButton!
    
    private var revealed: Bool = false

    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tokenProvider = ExampleTokenProvider()
        
        
        let config = Skyflow.Configuration(vaultID: "VAULT_ID", vaultURL: "VAULT_URL", tokenProvider: tokenProvider)

        self.skyflow = Skyflow.initialize(config)

        if self.skyflow != nil {
            
            let container = self.skyflow?.container(type: Skyflow.ContainerType.COLLECT, options: nil)
            self.container = container
            self.stackView = UIStackView()

            let baseStyle = Skyflow.Style(cornerRadius: 2, padding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10), borderWidth: 1, textAlignment: .left, textColor: .blue)
            
            let focusStyle = Skyflow.Style(borderColor: .blue)
            
            let completedStyle = Skyflow.Style(borderColor: UIColor.green, textColor: UIColor.green)

            let invalidStyle = Skyflow.Style(borderColor: UIColor.red, textColor: UIColor.red)
            let styles = Skyflow.Styles(base: baseStyle,complete: completedStyle, focus: focusStyle, invalid: invalidStyle)
            
            
            
            let baseStyleL = Skyflow.Style(cornerRadius: 2, padding: UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 10), borderWidth: 1, textAlignment: .left)
            
            let focusStyleL = Skyflow.Style(borderColor: .yellow)
            
            let completedStyleL = Skyflow.Style(borderColor: UIColor.green, textColor: UIColor.green)

            let invalidStyleL = Skyflow.Style(borderColor: UIColor.red, textColor: UIColor.red)
            let labelStyles = Skyflow.Styles(base: baseStyleL,complete: completedStyleL, focus: focusStyleL, invalid: invalidStyleL)
                        
            let baseStyleE = Skyflow.Style(cornerRadius: 2, padding: UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 10), borderWidth: 1, textAlignment: .left, textColor: .orange)
            
            
            let focusStyleE = Skyflow.Style(borderColor: .yellow,  textAlignment: .right, textColor: .yellow)

            let completedStyleE = Skyflow.Style(borderColor: UIColor.green, textColor: UIColor.green)

            let invalidStyleE = Skyflow.Style(borderColor: UIColor.red, textColor: UIColor.red)
            let errorStyles = Skyflow.Styles(base: baseStyleE,complete: completedStyleL, focus: focusStyleE, invalid: invalidStyleE)
            //keep card number as unique column for testing upsert feature
            let collectCardNumberInput = Skyflow.CollectElementInput(table: "persons", column: "cardnumber", inputStyles: styles,  labelStyles: labelStyles, errorTextStyles: errorStyles, label: "Card Number", placeholder: "4111-1111-1111-1111", type: Skyflow.ElementType.CARD_NUMBER)

            let requiredOption = Skyflow.CollectElementOptions(required: true)
            let collectCardNumber = container?.create(input: collectCardNumberInput, options: requiredOption)
            let collectCvvInput = Skyflow.CollectElementInput(table: "persons", column: "cvv", inputStyles : styles,
                 label: "Cvv",
                 placeholder: "123",
                 type: Skyflow.ElementType.CVV)
            let collectCvv = container?.create(input: collectCvvInput, options: requiredOption)
            let collectButton:UIButton = UIButton(frame: CGRect(x: 100, y: 400, width: 100, height: 40))
            collectButton.backgroundColor = .blue
            collectButton.setTitle("Submit", for: .normal)
            collectButton.addTarget(self, action:#selector(submitForm) , for: .touchUpInside)
            
            
            self.revealContainer = skyflow?.container(type: Skyflow.ContainerType.REVEAL, options: nil)

            self.revealButton = UIButton(frame: CGRect(x: 100, y: 400, width: 100, height: 40))
            
            revealButton.backgroundColor = .blue
            revealButton.setTitle("Reveal", for: .normal)
            revealButton.addTarget(self, action:#selector(revealForm) , for: .touchUpInside)

            
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
            
            
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
            scrollView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor,
                                            constant: 10).isActive = true
            scrollView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10).isActive = true
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
        self.revealContainer?.reveal(callback: ExampleAPICallback())
        
    }
    
    
    @objc func submitForm() {
        let exampleAPICallback = ExampleAPICallback(updateSuccess: updateSuccess, updateFailure: updateFailure)
        let upsertOptions = [["table": "persons", "column": "cardnumber"]] as [[String : Any]]
        container!.collect(callback: exampleAPICallback, options: Skyflow.CollectOptions(tokens: true))
    }
    internal func updateSuccess(_ response: SuccessResponse) {
        updateRevealInputs(tokens: response.records[0].fields)
        
        print("Successfully got response:", response)
    }
    
    internal func updateFailure() {
        print("Failed Operation")
    }
    
    internal func updateRevealInputs(tokens: Fields) {
        let revealBaseStyle = Skyflow.Style(borderColor: UIColor.black, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textAlignment: .left, textColor: UIColor.blue)
        
        let revealStyles = Skyflow.Styles(base: revealBaseStyle)
        
        DispatchQueue.main.async {
            
            if self.revealed {
                self.removeRevealElements()
            }
            else {
                self.revealed = true
            }
            
            let revealCardNumberInput = Skyflow.RevealElementInput(token: tokens.cardnumber, inputStyles: revealStyles, label: "Card Number", redaction: .DEFAULT)
            self.revealCardNumber = self.revealContainer?.create(input: revealCardNumberInput, options: Skyflow.RevealElementOptions())
            let revealCvvInput = Skyflow.RevealElementInput(token: tokens.cvv, inputStyles: revealStyles, label: "Cvv", redaction: .DEFAULT)

            self.revealCvv = self.revealContainer?.create(input: revealCvvInput, options: Skyflow.RevealElementOptions())
        
            self.addRevealElements()
        }

    }
    
    internal func removeRevealElements() {
        self.stackView.removeArrangedSubview(self.revealCardNumber!)
        self.stackView.removeArrangedSubview(self.revealCvv!)
        self.stackView.removeArrangedSubview(self.revealButton)


        self.revealCardNumber?.removeFromSuperview()
        self.revealButton.removeFromSuperview()

        self.revealContainer = self.skyflow?.container(type: Skyflow.ContainerType.REVEAL, options: nil)

    }
    
    internal func addRevealElements() {
        DispatchQueue.main.async {
            self.stackView.addArrangedSubview(self.revealCardNumber!)
            self.stackView.addArrangedSubview(self.revealCvv!)
            self.stackView.addArrangedSubview(self.revealButton)

        }
    }
    
}



