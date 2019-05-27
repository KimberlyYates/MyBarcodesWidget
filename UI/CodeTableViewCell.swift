
import UIKit

class CodeTableViewCell: UITableViewCell {

	//MARK: Properties
	var code: Code! {
		didSet {
			updateContent()
		}
	}
	var defaultContentScale: CGFloat!
	
	//MARK: Outlets
	@IBOutlet weak var logoImageView: UIImageView!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var codeImageView: UIImageView!
	@IBOutlet weak var settingsButton: UIButton!
	@IBOutlet weak var valueLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		logoImageView.layer.cornerRadius = 10
		logoImageView.clipsToBounds = true
		settingsButton.layer.opacity = 0.0
	}

	private func updateContent() {
		nameLabel.text = code.name
		codeImageView.image = Utils.generateCode(
			value: code.value,
			codeType: code.type,
			targetSize: codeImageView.frame.size) ?? UIImage(named: "barcodeAddIcon")
		
		// scale factor will be correct after setting the image
		if defaultContentScale == nil {
			defaultContentScale = codeImageView.contentScaleFactor
		}
		updateDisplaySize()
		
		valueLabel.isHidden = !code.showValue
		valueLabel.text = code.value
		
		if code.logo != nil {
			logoImageView.image = code.logo!
		} else {
			if let image = Utils.generateCode(value: code.value, codeType: code.type, targetSize: logoImageView.frame.size) {
				logoImageView.image = image.imageWithInsets(insets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)) ?? UIImage(named: "barcodeAddIcon")
			}
		}
	}
	
	func updateDisplaySize() {
		codeImageView.contentScaleFactor = defaultContentScale! + defaultContentScale! * CGFloat(1.0 - code.displaySize)
	}
	
	@IBAction func openSettings(_ sender: UIButton) {
		guard let tableView = getTableView(),
			let codeTableVC = tableView.delegate as? CodeTableViewController,
			let viewController = codeTableVC.storyboard?.instantiateViewController(withIdentifier: "CodeSettingsViewController") as? CodeSettingsTableViewController else {
				return
		}
		viewController.preferredContentSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.7)
		viewController.modalPresentationStyle = UIModalPresentationStyle.popover
		viewController.code = code
		
		let popover = viewController.popoverPresentationController
		popover?.delegate = codeTableVC
		popover?.sourceView = codeTableVC.view
		popover?.sourceRect = CGRect(x: codeTableVC.view.center.x, y: codeTableVC.view.center.y, width: 0, height: 0)
		popover?.permittedArrowDirections = .init(rawValue: 0)
		
		DispatchQueue.main.async {
			codeTableVC.present(viewController, animated: true, completion: nil)
		}
	}
	
	private func getTableView() -> UITableView? {
		let tableView: UITableView?
		if #available(iOS 11.0, *) {
			tableView = superview as? UITableView
		} else {
			// In iOS 10, superview is scrollview
			tableView = superview?.superview as? UITableView
		}
		return tableView
	}
	
}
