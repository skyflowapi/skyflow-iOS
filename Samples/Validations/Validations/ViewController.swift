// Reset Password - A simple example that illustrates custom validations.
// The below code shows two input fields with custom validations,
// one to enter a password and the second to confirm the same password.

import UIKit
import Skyflow

class ViewController: UIViewController {
    
    private var skyflowClient: Skyflow.Client?
    private var container: Skyflow.Container<Skyflow.CollectContainer>?
    private var b: UIButton?
    private var confirmPasswordElement: Skyflow.TextField?
    
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
        
        let config = Skyflow.Configuration(vaultID: "<VAULT_ID>", vaultURL: "<VAULT_URL>", tokenProvider: tokenProvider)
        
        self.skyflowClient = Skyflow.initialize(config)
        
        if self.skyflowClient != nil {
            
            let container = self.skyflowClient?.container(type: Skyflow.ContainerType.COLLECT, options: nil)
            self.container = container
            self.stackView = UIStackView()
            
            let baseStyle = Skyflow.Style(cornerRadius: 2, padding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10), borderWidth: 1, textAlignment: .left, textColor: .blue)
            
            let focusStyle = Skyflow.Style(borderColor: .blue)
            
            let completedStyle = Skyflow.Style(borderColor: UIColor.green, textColor: UIColor.green)
            
            let invalidStyle = Skyflow.Style(borderColor: UIColor.red, textColor: UIColor.red)
            
            let styles = Skyflow.Styles(base: baseStyle,complete: completedStyle, focus: focusStyle, invalid: invalidStyle)
            
            var myRuleset = ValidationSet()
            let strongPasswordRule = RegexMatchRule(regex: "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]*$", error: "At least one letter and one number") // This rule enforces a strong password
            let lengthRule = LengthMatchRule(minLength: 8, maxLength: 16, error: "Must be between 8 and 16 digits") // this rule allows input length between 8 and 16 characters
            
            // for the Password element
            myRuleset.add(rule: strongPasswordRule)
            myRuleset.add(rule: lengthRule)
            
            let passwordInput = CollectElementInput(inputStyles: styles, label: "password", placeholder: "********",
                                                    type: .INPUT_FIELD, validations: myRuleset)
            let password = container?.create(input: passwordInput)
            
            
            // For confirm password element - shows error when the passwords don't match
            let elementValueMatchRule = ElementValueMatchRule(element: password!, error: "passwords don't match")
            let confirmPasswordInput = CollectElementInput(inputStyles: styles,
                                                           label: "Confirm password", placeholder: "********", type: .INPUT_FIELD,
                                                           validations: ValidationSet(rules: [strongPasswordRule, lengthRule, elementValueMatchRule]))
            let confirmPassword = container?.create(input: confirmPasswordInput)
            self.confirmPasswordElement = confirmPassword
            // mount elements on screen - errors will be shown if any of the validaitons fail
            stackView.addArrangedSubview(password!)
            stackView.addArrangedSubview(confirmPassword!)
            
            let resetButton:UIButton = UIButton(frame: CGRect(x: 100, y: 400, width: 100, height: 40))
            resetButton.backgroundColor = .blue
            resetButton.setTitle("Submit", for: .normal)
            resetButton.addTarget(self, action:#selector(resetPassword) , for: .touchUpInside)
            
            stackView.addArrangedSubview(resetButton)
            
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
    
    
    
    @objc func resetPassword() {
        print("reset password")
        let url = ""
        let requestHeaders = ["Content-Type": "application/json ", "Authorization": ""]
        let requestBody: [String: Any] = [
            //Other fields...
            "password": self.confirmPasswordElement!
        ]
        
        let responseBody: [String: Any] = [:]
        
        let connectionConfig = ConnectionConfig(connectionURL: url, method: .POST, requestBody: requestBody, requestHeader: requestHeaders, responseBody: responseBody)
        
        self.skyflowClient?.invokeConnection(config: connectionConfig, callback: ExampleAPICallback())
    }
    
}




