/*
 * Copyright (c) 2022 Skyflow
 */

import UIKit
import SkyflowFlowVault

// Menu screen: choose which container type's custom-validations demo to open.
// Mirrors the InputFormatting sample menu pattern (button -> push a UINavigationController-wrapped VC).
class ViewController: UIViewController {
    private var stackView: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.stackView = UIStackView()

        let collectButton = UIButton()
        collectButton.setTitle("Collect Container", for: .normal)
        collectButton.backgroundColor = .black
        collectButton.setTitleColor(.white, for: .normal)
        collectButton.addTarget(self, action: #selector(openCollectValidations), for: .touchUpInside)
        collectButton.accessibilityIdentifier = "collectContainerView"

        let composableButton = UIButton()
        composableButton.setTitle("Composable Container", for: .normal)
        composableButton.backgroundColor = .black
        composableButton.setTitleColor(.white, for: .normal)
        composableButton.addTarget(self, action: #selector(openComposableValidations), for: .touchUpInside)
        composableButton.accessibilityIdentifier = "composableContainerView"

        stackView.addArrangedSubview(collectButton)
        stackView.addArrangedSubview(composableButton)
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 10
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        stackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        stackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
    }

    @objc private func openCollectValidations() {
        let rootVC = CollectValidationsViewController()
        rootVC.title = "Collect Container"
        let navVC = UINavigationController(rootViewController: rootVC)
        navVC.modalPresentationStyle = .fullScreen
        present(navVC, animated: true)
    }

    @objc private func openComposableValidations() {
        let rootVC = ComposableValidationsViewController()
        rootVC.title = "Composable Container"
        let navVC = UINavigationController(rootViewController: rootVC)
        navVC.modalPresentationStyle = .fullScreen
        present(navVC, animated: true)
    }
}
