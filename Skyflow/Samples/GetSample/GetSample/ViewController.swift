/*
 * Copyright (c) 2022 Skyflow
 */

import UIKit
import Skyflow

class ViewController: UIViewController {
    private var skyflow: Skyflow.Client?
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
        self.stackView = UIStackView()

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
            let getWithRedactionType = UIButton(frame: CGRect(x: 100, y: 400, width: 100, height: 70))
            getWithRedactionType.backgroundColor = .gray
            getWithRedactionType.setTitle("Get Records With Redaction Type", for: .normal)
            getWithRedactionType.addTarget(self, action: #selector(getRecordsWithRedactionType), for: .touchUpInside)
           
            let getWithGetOptionTokens = UIButton(frame: CGRect(x: 100, y: 400, width: 100, height: 70))
            getWithGetOptionTokens.backgroundColor = .gray
            getWithGetOptionTokens.setTitle("Get Records with tokens", for: .normal)
            getWithGetOptionTokens.addTarget(self, action: #selector(getRecordsWithGetOptionTokens), for: .touchUpInside)
            
            stackView.addArrangedSubview(getWithRedactionType)
            stackView.addArrangedSubview(getWithGetOptionTokens)

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
    @objc func getRecordsWithRedactionType() {
        let exampleAPICallback = ExampleAPICallback(updateSuccess: updateSuccess, updateFailure: updateFailure)
        let record = ["ids": ["<SKYFLOW_ID1>", "<SKYFLOW_ID2>"], "table": "<TABLE_NAME>", "redaction": RedactionType.PLAIN_TEXT] as [String : Any]
        let recordColumn = ["columnValues": ["<COLUMN_VALUE1>", "<COLUMN_VALUE2>"],"table": "<TABLE_NAME>", "columnName": "<UNIQUE_COLUMN_NAME>","redaction": RedactionType.PLAIN_TEXT] as [String : Any]

        let invalidID = ["invalid skyflow ID"]
        let badRecord = ["ids": invalidID, "table": "table", "redaction": RedactionType.PLAIN_TEXT] as [String : Any]

        let records = ["records": [record, recordColumn, badRecord]]
        self.skyflow?.get(records: records, callback: exampleAPICallback)
    }
    
    @objc func getRecordsWithGetOptionTokens() {
        let exampleAPICallback = ExampleAPICallback(updateSuccess: updateSuccess, updateFailure: updateFailure)
        let record = ["ids": ["<SKYFLOW_ID1>", "<SKYFLOW_ID2>"], "table": "<TABLE_NAME>"] as [String : Any]

        let invalidID = ["invalid skyflow ID"]
        let badRecord = ["ids": invalidID, "table": "table", "redaction": RedactionType.PLAIN_TEXT] as [String : Any]

        let records = ["records": [record, badRecord]]
        self.skyflow?.get(records: records, options: GetOptions(tokens: true), callback: exampleAPICallback)
    }
    internal func updateSuccess(_ response: SuccessResponse) {
        print(response)
        print("Successfully got response:", response)
    }
    internal func updateFailure(error: Any) {
        print("Failed Operation", error)
    }
}
