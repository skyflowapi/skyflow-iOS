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
    private var container: Skyflow.Container<Skyflow.CollectContainer>?
    private var revealContainer: Skyflow.Container<Skyflow.RevealContainer>?
    private var stackView: UIStackView!
    private var revealApprovalCode: Label?
    private var cardNumber: TextField?
    private var cvv: TextField?
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
            
            let container = self.skyflowClient?.container(type: Skyflow.ContainerType.COLLECT, options: nil)
            self.container = container
            
            let baseStyle = Skyflow.Style(cornerRadius: 2, padding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10), borderWidth: 1, textAlignment: .left, textColor: .blue)
            
            let focusStyle = Skyflow.Style(borderColor: .blue)
            
            let completedStyle = Skyflow.Style(borderColor: UIColor.green, textColor: UIColor.green)
            
            let invalidStyle = Skyflow.Style(borderColor: UIColor.red, textColor: UIColor.red)
            
            let styles = Skyflow.Styles(base: baseStyle,complete: completedStyle, focus: focusStyle, invalid: invalidStyle)
            
            let collectCardNumberInput = Skyflow.CollectElementInput(inputStyles: styles, label: "senderPrimaryAccountNumber", placeholder: "4111-1111-1111-1111", type: Skyflow.ElementType.CARD_NUMBER)
            let collectCVVInput = Skyflow.CollectElementInput(inputStyles: styles, label: "cvv", placeholder: "***", type: .CVV)
            
            self.cardNumber = container?.create(input: collectCardNumberInput)
            self.cvv = container?.create(input: collectCVVInput)
            
            self.revealContainer = skyflowClient?.container(type: Skyflow.ContainerType.REVEAL, options: nil)
            
            let revealBaseStyle = Skyflow.Style(borderColor: UIColor.black, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textAlignment: .left, textColor: UIColor.blue)
            
            let revealStyles = Skyflow.Styles(base: revealBaseStyle)
            
            let revealCVVInput = Skyflow.RevealElementInput(inputStyles: revealStyles, label: "Approval Code", redaction: Skyflow.RedactionType.PLAIN_TEXT, altText: "Cvv not yet generated")
            
            self.revealApprovalCode = self.revealContainer?.create(input: revealCVVInput)
            
            self.button = UIButton(frame: CGRect(x: 100, y: 400, width: 100, height: 40))
            
            button.backgroundColor = .blue
            button.setTitle("Click to pull funds", for: .normal)
            button.addTarget(self, action:#selector(pullFunds) , for: .touchUpInside)
            
            self.stackView.addArrangedSubview(self.cardNumber!)
            self.stackView.addArrangedSubview(self.cvv!)
            self.stackView.addArrangedSubview(self.revealApprovalCode!)
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
    
    
    @objc func pullFunds() {
        
        let url = ""
        
        let requestHeaders = ["Content-Type": "application/json", "Accept": "application/json","Authorization": ""]
        
        let requestBody: [String: Any] = [
            "surcharge": "11.99",
            "amount": "124.02",
            "localTransactionDateTime": "2021-10-04T23:33:06",
            "cpsAuthorizationCharacteristicsIndicator": "Y",
            "riskAssessmentData": [
                "traExemptionIndicator": true,
                "trustedMerchantExemptionIndicator": true,
                "scpExemptionIndicator": true,
                "delegatedAuthenticationIndicator": true,
                "lowValueExemptionIndicator": true
            ],
            "cardAcceptor": [
                "address": [
                    "country": "USA",
                    "zipCode": "94404",
                    "county": "081",
                    "state": "CA"
                ],
                "idCode": "ABCD1234ABCD123",
                "name": "Visa Inc. USA-Foster City",
                "terminalId": "ABCD1234"
            ],
            "acquirerCountryCode": "840",
            "acquiringBin": "408999",
            "senderCurrencyCode": "USD",
            "retrievalReferenceNumber": "330000550000",
            "addressVerificationData": [
                "street": "XYZ St",
                "postalCode": "12345"
            ],
            "cavv": "<YOUR_CAVV_TOKEN>",
            "systemsTraceAuditNumber": "451001",
            "businessApplicationId": "AA",
            "senderPrimaryAccountNumber": self.cardNumber as Any,
            "cardCvv2Value": self.cvv as Any,
            "settlementServiceIndicator": "9",
            "visaMerchantIdentifier": "73625198",
            "foreignExchangeFeeTransaction": "11.99",
            "senderCardExpiryDate": "2015-10",
            "nationalReimbursementFee": "11.22"]
        
        let responseBody: [String: Any] = [
            "approvalCode": self.revealApprovalCode as Any
        ]
        
        let connConfig = ConnectionConfig(connectionURL: url, method: .POST, requestBody: requestBody, requestHeader: requestHeaders, responseBody: responseBody)
        
        self.skyflowClient?.invokeConnection(config: connConfig, callback: ConnectionCallback())
    }
    
    class ConnectionCallback: Callback {
        func onSuccess(_ responseBody: Any) {
            print("Invoke connection success ", responseBody)
        }
        
        func onFailure(_ error: Any) {
            print("Invoke connection failure ", error)
        }
    }
}
