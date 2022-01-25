import UIKit
import Skyflow

class ViewController: UIViewController {
    
    private var skyflow: Client? = nil
    private var collectContainer: Skyflow.Container<Skyflow.CollectContainer>?
    private var revealContainer: Skyflow.Container<Skyflow.RevealContainer>?
    private var stackView: UIStackView!
    
    
    private var expiryYearElement: Label? = nil
    private var expiryMonthElement: Label? = nil
    private var cvvElement: Label? = nil
    private var nameElement: Label? = nil
    private var cardNumberElement: TextField? = nil
    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tokenProvider = ExampleTokenProvider()
        
        // vaultID and vaultURL are mandatory if formatRegex option is used in any Reveal Element
        let config = Skyflow.Configuration(vaultID: "<VAULT_ID>", vaultURL: "<VAULT_URL>", tokenProvider: tokenProvider)

        self.skyflow = Skyflow.initialize(config)

        if self.skyflow != nil {
            let collectContainer = self.skyflow?.container(type: Skyflow.ContainerType.COLLECT, options: nil)
            let revealContainer = self.skyflow?.container(type: Skyflow.ContainerType.REVEAL, options: nil)

            self.collectContainer = collectContainer
            self.revealContainer = revealContainer
            self.stackView = UIStackView()
            
            let styles = getStyles()
            
            let cardNumberInput = CollectElementInput(inputStyles: styles, label: "Card Number", placeholder: "4111-1111-1111-1111", type: Skyflow.ElementType.CARD_NUMBER)
            self.cardNumberElement = collectContainer?.create(input: cardNumberInput)
            let expirymMonthInput = RevealElementInput(token: "<MONTH_TOKEN>", inputStyles: styles, label: "Expiry Month")
            self.expiryMonthElement = self.revealContainer?.create(input: expirymMonthInput, options: Skyflow.RevealElementOptions())
            
            let expiryYearInput = RevealElementInput(token: "<YEAR_TOKEN>", inputStyles: styles, label: "Expiry Year")
        
            // With formatRegex option to get only last to digits (e.g. 2022 -> 22)
            self.expiryYearElement = self.revealContainer?.create(input: expiryYearInput, options: Skyflow.RevealElementOptions(formatRegex: "..$"))
            
            
            let cvvElementInput = RevealElementInput(token: "", inputStyles: styles, label: "CVV")
            self.cvvElement = self.revealContainer?.create(input: cvvElementInput, options: Skyflow.RevealElementOptions())
            
            let nameElementInput = RevealElementInput(token: "<YEAR_TOKEN>", inputStyles: styles, label: "First Name")
        
            // With formatRegex option to get only first name
            self.nameElement = self.revealContainer?.create(input: nameElementInput, options: Skyflow.RevealElementOptions(formatRegex: "(?<=name : )(.+)(?= (.*))"))
            
            
            let invokeConnectionBtn:UIButton = UIButton(frame: CGRect(x: 100, y: 400, width: 100, height: 40))
            invokeConnectionBtn.backgroundColor = .blue
            invokeConnectionBtn.setTitle("Submit", for: .normal)
            invokeConnectionBtn.addTarget(self, action:#selector(formatRegexConnection) , for: .touchUpInside)
           
            
            stackView.addArrangedSubview(self.cardNumberElement!)
            stackView.addArrangedSubview(self.expiryMonthElement!)
            stackView.addArrangedSubview(self.expiryYearElement!)
            stackView.addArrangedSubview(invokeConnectionBtn)
            
            
            stackView.addArrangedSubview(self.nameElement!)
            stackView.addArrangedSubview(self.cvvElement!)
            
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
    
    func getStyles() -> Styles {
        let baseStyle = Skyflow.Style(cornerRadius: 2, padding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10), borderWidth: 1, textAlignment: .left, textColor: .blue)
        
        let focusStyle = Skyflow.Style(borderColor: .blue)
        
        let completedStyle = Skyflow.Style(borderColor: UIColor.green, textColor: UIColor.green)

        let invalidStyle = Skyflow.Style(borderColor: UIColor.red, textColor: UIColor.red)
        
        
        return Skyflow.Styles(base: baseStyle,complete: completedStyle, focus: focusStyle, invalid: invalidStyle)
    }
    
    @objc func formatRegexConnection() {


        let cardNumberID = self.cardNumberElement!.getID()  // to get element ID
        let expiryMonthID = self.expiryMonthElement!.getID()
        let expiryYearID = self.expiryYearElement!.getID()
        let cvvElementID = self.cvvElement!.getID()
        let holderNameID = self.nameElement!.getID()

        let requestXML = """
            <soapenv:Envelope>
                <soapenv:Header>
                    <ClientID>
                        1234
                    </ClientID>
                </soapenv:Header>
                <soapenv:Body>
                    <GenerateCVV>
                        <CardNumber>
                            <Skyflow>
                                \(cardNumberID)
                            </Skyflow>
                        </CardNumber>
                        <ExpiryMonth>
                            <Skyflow>
                                \(expiryMonthID)
                            </Skyflow>
                        </ExpiryMonth>
                        <ExpiryYear>
                            <Skyflow>
                                \(expiryYearID)
                            </Skyflow>
                        </ExpiryYear>
                    </GenerateCVV>
                </soapenv:Body>
            </soapenv:Envelope>
        """

        let httpHeaders = ["SOAPAction": ""]

        let responseXML = """
            <soapenv:Envelope>
                <soapenv:Body>
                    <GenerateCVV>
                        <CVV>
                            <Skyflow>
                                \(cvvElementID)
                            </Skyflow>
                        </CVV>
                        <CardHolderName>
                            <Skyflow>
                                \(holderNameID)
                            </Skyflow>
                        </CardHolderName>
                    </GenerateCVV>
                </soapenv:Body>
            </soapenv:Envelope>
        """
        
        let connectionUrl = "<YOUR_CONNECTION_URL>"
        let soapConfig = SoapConnectionConfig(connectionURL: connectionUrl, httpHeaders: httpHeaders, requestXML: requestXML, responseXML: responseXML)
        
        self.skyflow?.invokeSoapConnection(config: soapConfig, callback: ExampleAPICallback())
    }


}

public class ExampleTokenProvider : TokenProvider {
    
    
    public func getBearerToken(_ apiCallback: Skyflow.Callback) {
        if let url = URL(string: "<YOUR_TOKEN_PROVIDER_ENDPOINT>") {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url){ data, response, error in
                if(error != nil){
                    print(error!)
                    return
                }
                if let safeData = data {
                    do{
                        let x = try JSONSerialization.jsonObject(with: safeData, options:[]) as? [String: String]
                        if let accessToken = x?["accessToken"]{
                            apiCallback.onSuccess(accessToken)
                        }
                    }
                    catch{
                        print("access token wrong format")
                    }
                }
            }
            task.resume()
        }
    }
}

public class ExampleAPICallback: Skyflow.Callback {
    
    
    public func onSuccess(_ responseBody: Any) {
        print("Success:", responseBody)
    }
    
    public func onFailure(_ error: Any) {
        print("Failure:", error)
    }
    
}

