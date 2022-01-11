//
//  ViewController.swift
//  InvokeSoapConnection
//
//  Created by Akhil Anil Mangala on 10/01/22.
//


import UIKit
import Skyflow

class ViewController: UIViewController {
    
    
    private var skyflowClient: Skyflow.Client?
    private var collectContainer: Skyflow.Container<Skyflow.CollectContainer>?
    private var revealContainer: Skyflow.Container<Skyflow.RevealContainer>?
    private var stackView: UIStackView!

    private var button: UIButton!
    
    private var cardNumberElement: TextField?
    private var expiryDateElement: TextField?
    private var cvvElement: Label?

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tokenProvider = ExampleTokenProvider()
        
        let config = Skyflow.Configuration(tokenProvider: tokenProvider)
        
        self.skyflowClient = Skyflow.initialize(config)
        
        if self.skyflowClient != nil {
            
            self.stackView = UIStackView()
            
            self.collectContainer = self.skyflowClient?.container(type: Skyflow.ContainerType.COLLECT, options: nil)
            
            self.cardNumberElement = self.collectContainer?.create(input: CollectElementInput(label: "Card number", placeholder: "Enter card number", type: .CARD_NUMBER))
            
            self.expiryDateElement = self.collectContainer?.create(input: CollectElementInput(label: "Expiration date", placeholder: "Enter expiration date", type: .EXPIRATION_DATE))
            
            self.revealContainer = skyflowClient?.container(type: Skyflow.ContainerType.REVEAL, options: nil)
            
            self.cvvElement = self.revealContainer?.create(input: RevealElementInput(label: "CVV", altText: "CVV not yet generated"))
            
            self.button = UIButton(frame: CGRect(x: 100, y: 400, width: 100, height: 40))
            
            button.backgroundColor = .blue
            button.setTitle("Click to generate cvv", for: .normal)
            button.addTarget(self, action:#selector(generateCvv) , for: .touchUpInside)
            
            self.stackView.addArrangedSubview(self.cardNumberElement!)
            self.stackView.addArrangedSubview(self.expiryDateElement!)
            self.stackView.addArrangedSubview(self.cvvElement!)
            self.stackView.addArrangedSubview(button!)
            
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
            
        let cardNumberID = self.cardNumberElement!.getID()
        let expiryDateID = self.expiryDateElement!.getID()
        let cvvElementID = self.cvvElement!.getID()
        
        var responseXML = """
            <soapenv:Envelope>
                <soapenv:Body>
                    <GenerateCVV>
                        <CVV>
                            <Skyflow>\(cvvElementID)</Skyflow>
                        </CVV>
                    </GenerateCVV>
                </soapenv:Body>
            </soapenv:Envelope>
        """
        
        let requestXML = """
            <soapenv:Envelope>
                <soapenv:Header>
                    <ClientID>1234</ClientID>
                </soapenv:Header>
                <soapenv:Body>
                    <GenerateCVV>
                        <CardNumber>
                            <Skyflow>\(cardNumberID)</Skyflow>
                        </CardNumber>
                        <ExpiryDate>
                            <Skyflow>\(expiryDateID)</Skyflow>
                        </ExpiryDate>
                    </GenerateCVV>
                </soapenv:Body>
            </soapenv:Envelope>
        """
        
        let httpHeaders = ["SOAPAction": "<SOAP_ACTION>", "Content-Type": "text/xml; charset=utf-8"]
        
        let config = SoapConnectionConfig(connectionURL: "<CONNECTION_URL>", httpHeaders: httpHeaders, requestXML: requestXML, responseXML: responseXML)
        
        self.skyflowClient?.invokeSoapConnection(config: config, callback: SoapConnectionCallback())
        
    }
    
    class SoapConnectionCallback: Callback {
        func onSuccess(_ responseBody: Any) {
            print("Invoke soap connection success ", responseBody)
        }
        
        public func onFailure(_ error: Any) {
            print("Invoke soap connection failure ", error)
            let skyflowErrorObj = error as? SkyflowError
            let xml = skyflowErrorObj?.getXml()
            if(xml != nil && !xml.isEmpty) {
                print("error xml response from server", xml)
            }
          }
    }
}


