//
//  ViewController.swift
//  App
//
//  Created by Tejesh Reddy Allampati on 16/09/21.
//


import UIKit
import Skyflow



class ViewController: UIViewController {
    
    
    private var skyflowClient: Skyflow.Client?
    private var revealContainer: Skyflow.Container<Skyflow.RevealContainer>?
    private var stackView: UIStackView!
    private var revealCVV: Label?
    private var revealCardNumber: Label?
    private var button: UIButton!
    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tokenProvider = ExampleTokenProvider()
        
        
        let config = Skyflow.Configuration(vaultID: "<VAULT_ID>", vaultURL: "<VAULT_URL>", tokenProvider: tokenProvider)
        
        self.skyflowClient = Skyflow.initialize(config)
        
        if self.skyflowClient != nil {
            
            self.stackView = UIStackView()
            
            self.revealContainer = skyflowClient?.container(type: Skyflow.ContainerType.REVEAL, options: nil)
            
            let revealBaseStyle = Skyflow.Style(borderColor: UIColor.black, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textAlignment: .left, textColor: UIColor.blue)
            
            let revealStyles = Skyflow.Styles(base: revealBaseStyle)
            
            let revealCardNumberInput = Skyflow.RevealElementInput(token: "<TOKEN>", inputStyles: revealStyles, label: "Card Number", redaction: .DEFAULT)
            
            self.revealCardNumber = self.revealContainer?.create(input: revealCardNumberInput, options: Skyflow.RevealElementOptions())
            
            let revealCVVInput = Skyflow.RevealElementInput(inputStyles: revealStyles, label: "cvv", redaction: Skyflow.RedactionType.PLAIN_TEXT, altText: "Cvv not yet generated")
            
            self.revealCVV = self.revealContainer?.create(input: revealCVVInput)
            
            self.button = UIButton(frame: CGRect(x: 100, y: 400, width: 100, height: 40))
            
            button.backgroundColor = .blue
            button.setTitle("Click to generate cvv", for: .normal)
            button.addTarget(self, action:#selector(generateCvv) , for: .touchUpInside)
            
            self.stackView.addArrangedSubview(self.revealCardNumber!)
            self.stackView.addArrangedSubview(self.revealCVV!)
            self.stackView.addArrangedSubview(self.button)
            
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
    
    
    @objc func generateCvv() {
        let url = ""
        let pathParams = ["card_id": revealCardNumber]
        let requestHeaders = ["Content-Type": "application/json ","Authorization": ""]
        let requestBody = [
            "expirationDate": [
                "mm": "12",
                "yy": "22"
            ]]
        
        let responseBody = [
            "resource": [
                "cvv2": self.revealCVV
            ]]
        
        let gatewayConfig = GatewayConfig(gatewayURL: url, method: .POST, pathParams: pathParams as [String : Any], requestBody: requestBody, requestHeader: requestHeaders, responseBody: responseBody)
        
        self.skyflowClient?.invokeGateway(config: gatewayConfig, callback: ExampleAPICallback())
    }
    
}
