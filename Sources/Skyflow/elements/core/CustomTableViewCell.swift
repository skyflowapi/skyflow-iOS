import Foundation

#if os(iOS)
import UIKit
#endif

class CustomTableViewCell: UITableViewCell {

    let customImageView = UIImageView()
    let customTextLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // Configure custom image view (tick mark)
        customImageView.tintColor = .black
        contentView.addSubview(customImageView)
        
        // Configure custom text label
        
        customTextLabel.font = UIFont.systemFont(ofSize: 17)
        contentView.addSubview(customTextLabel)
        
        // Layout constraints for the custom image view
        customImageView.translatesAutoresizingMaskIntoConstraints = false
        customImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
        customImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        customImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        customImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        // Layout constraints for the custom text label
        customTextLabel.translatesAutoresizingMaskIntoConstraints = false
        customTextLabel.leadingAnchor.constraint(equalTo: customImageView.trailingAnchor, constant: 10).isActive = true
        customTextLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        customTextLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with text: String, isSelected: Bool) {
        customTextLabel.text = text
        #if SWIFT_PACKAGE
        let image = UIImage(named: "checkmark", in: Bundle.module, compatibleWith: nil)
        #else
        let frameworkBundle = Bundle(for: TextField.self)
        var bundleURL = frameworkBundle.resourceURL
        bundleURL!.appendPathComponent("Skyflow.bundle")
        let resourceBundle = Bundle(url: bundleURL!)
        var image = UIImage(named: "checkmark", in: resourceBundle, compatibleWith: nil)
        #endif
        customImageView.image = isSelected ? image : nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        separatorInset = UIEdgeInsets.zero
        layoutMargins = UIEdgeInsets.zero
        preservesSuperviewLayoutMargins = false
    }
}
