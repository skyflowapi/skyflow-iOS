/*
 * Copyright (c) 2022 Skyflow
 */

import UIKit
import Skyflow

class ViewController: UIViewController {
    private var stackView: UIStackView!

    override func viewDidLoad() {
        self.stackView = UIStackView()

        let button1 = UIButton()
        let button2 = UIButton()


        view.backgroundColor = .white
        
        button1.setTitle("Collect And Reveal View", for: .normal)
        button1.backgroundColor = .black
        button1.setTitleColor(.white, for: .normal)
        button1.frame = CGRect(x: 20, y: 70, width: 200, height: 15)
        button1.addTarget(self, action: #selector(openCollectAndRevealViewController), for: .touchUpInside)
        
        button2.setTitle("Open Card Brand Choice Sample", for: .normal)
        button2.backgroundColor = .black
        button2.setTitleColor(.white, for: .normal)
        button2.frame = CGRect(x: 20, y: 70, width: 200, height: 15)
        button2.addTarget(self, action: #selector(openCardBrandChoiceSampleViewController), for: .touchUpInside)

        button1.accessibilityIdentifier = "view1"
        button2.accessibilityIdentifier = "view2"

    
        stackView.addArrangedSubview(button1)
        stackView.addArrangedSubview(button2)
    
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
            rootVC.title = "Card Brand Choice Sample Vie"
            let navVC  = UINavigationController(rootViewController: rootVC)
            navVC.modalPresentationStyle = .fullScreen

            present(navVC, animated: true)

    }
    @objc private func openCardBrandChoiceSampleViewController(){
            let rootVC = CardBrandChoiceSampleViewController()
            rootVC.title = "Card Brand Choice Sample View"
            let navVC  = UINavigationController(rootViewController: rootVC)
            navVC.modalPresentationStyle = .fullScreen

            present(navVC, animated: true)

    }
 
}

