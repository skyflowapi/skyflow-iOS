/*
 * Copyright (c) 2022 Skyflow
 */

import UIKit
import SkyflowFlowVault

class ViewController: UIViewController {
    private var stackView: UIStackView!

    override func viewDidLoad() {
        self.stackView = UIStackView()

        let button1 = UIButton()

        view.backgroundColor = .white

        button1.setTitle("Collect And Reveal View", for: .normal)
        button1.backgroundColor = .black
        button1.setTitleColor(.white, for: .normal)
        button1.frame = CGRect(x: 20, y: 70, width: 200, height: 15)
        button1.addTarget(self, action: #selector(openCollectAndRevealViewController), for: .touchUpInside)

        button1.accessibilityIdentifier = "view1"

        stackView.addArrangedSubview(button1)

        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 2
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView(frame: .zero)
        scrollView.isScrollEnabled = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5).isActive = true
        scrollView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 10).isActive = true
        scrollView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        scrollView.addSubview(stackView)
        stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -10).isActive = true
        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        stackView.leftAnchor.constraint(equalTo: scrollView.leftAnchor).isActive = true
        stackView.rightAnchor.constraint(equalTo: scrollView.rightAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true

    }
    @objc private func openCollectAndRevealViewController(){
            let rootVC = CollectAndRevealViewController()
            rootVC.title = "Collect And Reveal View"
            let navVC  = UINavigationController(rootViewController: rootVC)
            navVC.modalPresentationStyle = .fullScreen

            present(navVC, animated: true)

    }

}

