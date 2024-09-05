//
//  CardBrandChoiceSampleViewController.swift
//  CollectAndRevealSample
//
//  Created by Bharti Sagar on 05/09/24.
//

import Foundation
import UIKit
import Skyflow

class CardBrandChoiceSampleViewController: UIViewController {
    
    private var skyflowClient: Skyflow.Client?
    private var container: Skyflow.Container<Skyflow.CollectContainer>?
    private var collectCardNumberElement: TextField!
    
    private var stackView: UIStackView!

    override func viewDidLoad(){
        super.viewDidLoad()
        var config = Skyflow.Configuration(vaultID: "<VAULT_ID>", vaultURL: "<VAULT_URL>", tokenProvider: ExampleTokenProvider(), options: Skyflow.Options(env: Skyflow.Env.PROD))
        skyflowClient = Skyflow.initialize(config)
        if self.skyflowClient != nil {
            container = self.skyflowClient?.container(type: ContainerType.COLLECT, options: nil)
            
            
            // styles for elements
            let uiFont = UIFont.systemFont(ofSize: 20, weight: .light)
            let baseStyle = Skyflow.Style(borderColor: .gray,cornerRadius: 5, padding: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5),borderWidth: 0.5, font: uiFont, textAlignment: .left, textColor: .black, backgroundColor: .white, maxWidth:  50, placeholderColor: .gray)
            let focusStyle = Skyflow.Style(borderColor: .black, cornerRadius: 5, padding:  UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5),borderWidth: 0.5, font: uiFont, textAlignment: .left, textColor: .black)//, backgroundColor: .yellow)
            let completeStyle = Skyflow.Style(borderColor: .black,cornerRadius: 5, padding:  UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5),borderWidth: 0.5, font: uiFont, textAlignment: .left, textColor: .black)
            let invalidStyle = Skyflow.Style(borderColor: .black,cornerRadius: 5, padding:  UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5),borderWidth: 0.5, font: uiFont, textAlignment: .left, textColor: .black)
            let emptyStyle = Skyflow.Style(borderColor: .black,cornerRadius: 5, padding:  UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5),borderWidth: 0.5, font: uiFont, textAlignment: .left, textColor: .black)

            let inputStyles = Skyflow.Styles(base: baseStyle, complete: completeStyle, empty: emptyStyle, focus: focusStyle, invalid: invalidStyle)
            let iconStyles = Skyflow.Styles(base: Style(cardIconAlignment: .right))
            
            // create card number element
            let collectCardNumberInput = Skyflow.CollectElementInput(table: "<TABLE_NAME>", column: "<COLUMN_NAME>", inputStyles: inputStyles, iconStyles: Styles(base: Style(cardIconAlignment: .right)),label: "Card Number", placeholder: "XXXXXXXXXXXXX", type: Skyflow.ElementType.CARD_NUMBER)
            let requiredOption = Skyflow.CollectElementOptions(required: true, enableCardIcon: true, enableCopy: false)
            
            collectCardNumberElement = container?.create(input: collectCardNumberInput, options: requiredOption)
            
            // Cardnumber element change listener
            var calledUpdate = false;
            self.collectCardNumberElement.on(eventName: Skyflow.EventName.CHANGE) { state in
                print("CHANGED", state)
                if((state["value"] as! String).count >= 8 && !calledUpdate){
                    calledUpdate = true
                    self.binLookup(bin: String((state["value"] as! String).prefix(8))) { result in
                        switch result {
                        case .success(let schemeList):
                            DispatchQueue.main.async {
                                // Update the card number element with the scheme list using update Method
                                self.collectCardNumberElement.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": schemeList]))
                            }
                        case .failure(let error):
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                } else if((state["value"] as! String).count < 8 && calledUpdate)  {
                    calledUpdate = false
                    self.collectCardNumberElement.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": []]))
                }
            }
            stackView.addArrangedSubview(collectCardNumberElement!)
            view.addSubview(stackView)

        }

    }
    // Sample Bin lookup api call.
    func binLookup(bin: String, completion: @escaping (Result<[Skyflow.CardType], Error>) -> Void) {
        // Set up the request headers
        var request = URLRequest(url: URL(string: "https://<VAULT_URL>/v1/card_lookup")!)
        request.httpMethod = "POST"
        request.addValue("<BEARER_TOKEN>", forHTTPHeaderField: "X-skyflow-authorization") // TODO: replace bearer token
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Set up the request body
        let requestBody: [String: Any] = ["BIN": bin]
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])

        // Perform the network request1
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data, let result = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let cardData = result["cards_data"] as? [[String: Any]] else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            // Extract card schemes
            let schemeList = self.getCardSchemes(from: cardData)
            completion(.success(schemeList))
        }
        task.resume()
    }
    //parse card scheme from the bin api response.
    func getCardSchemes(from cardData: [[String: Any]]) -> [Skyflow.CardType] {
        var schemeList: [Skyflow.CardType] = []

        for card in cardData {
            if let cardScheme = card["card_scheme"] as? String {
                switch cardScheme {
                case "VISA":
                    schemeList.append(Skyflow.CardType.VISA)
                case "MASTERCARD":
                    schemeList.append(Skyflow.CardType.MASTERCARD)
                case "CARTES BANCAIRES":
                    schemeList.append(Skyflow.CardType.CARTES_BANCAIRES)
                default:
                    break
                }
            }
        }
        
        return schemeList
    }
}
public class ExampleTokenProvider: TokenProvider {
    public func getBearerToken(_ apiCallback: Skyflow.Callback) {
        if let url = URL(string: "<YOUR_TOKEN_PROVIDER_ENDPOINT>") {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url) { data, _, error in
                if error != nil {
                    print(error!)
                    return
                }
                if let safeData = data {
                    do {
                        let x = try JSONSerialization.jsonObject(with: safeData, options: []) as? [String: String]
                        if let accessToken = x?["accessToken"] {
                            apiCallback.onSuccess(accessToken)
                        }
                    } catch {
                        print("access token wrong format")
                    }
                }
            }
            task.resume()
        }
    }
}
