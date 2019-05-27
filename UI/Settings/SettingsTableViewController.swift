

import UIKit

class SettingsTableViewController: UITableViewController {

	//MARK: Outlets
	@IBOutlet weak var lightThemeIndicator: UIView!
	@IBOutlet weak var darkThemeIndicator: UIView!
	@IBOutlet weak var lightThemeCheckmark: UILabel!
	@IBOutlet weak var darkThemeCheckmark: UILabel!
	
    override func viewDidLoad() {
        super.viewDidLoad()

		darkThemeCheckmark.isHidden = !(Settings.shared.selectedTheme == .dark)
		lightThemeCheckmark.isHidden = !(Settings.shared.selectedTheme == .light)
		setupThemeIndicators()
		
		updateAppearance()
    }
	
	override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.selectionStyle = .none
		cell.backgroundColor = Theme.settingsTableViewCellBackgroundColor
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == 0 {
			// Themes
			if indexPath.row == 0 {
				// Light
				Settings.shared.selectedTheme = .light
			}
			if indexPath.row == 1 {
				// Dark
				Settings.shared.selectedTheme = .dark
			}
			SettingsArchive.save()
			
			darkThemeCheckmark.isHidden = !(Settings.shared.selectedTheme == .dark)
			lightThemeCheckmark.isHidden = !(Settings.shared.selectedTheme == .light)
			
			navigationController?.viewControllers.forEach({ (viewController) in
				guard let themeDelegate = viewController as? ThemeDelegate else {
					return
				}
				themeDelegate.updateAppearance()
			})
			(navigationController as? ThemeDelegate)?.updateAppearance()
		}
		if indexPath.section == 1 {
			// Reset
			if indexPath.row == 0 {
				// Complete Content Reset
				resetContent()
			}
		}
		if indexPath.section == 2 {
			// Replay tutorial
			if indexPath.row == 0 {
				guard self.storyboard != nil else {
					return
				}
				let viewController = self.storyboard!.instantiateViewController(withIdentifier: "TutorialPageViewController")
				DispatchQueue.main.async {
					self.present(viewController, animated: true, completion: nil)
				}
			}
			
			// Privacy Policy
			if indexPath.row == 1 {
				guard self.storyboard != nil else {
					return
				}
				let viewController = self.storyboard!.instantiateViewController(withIdentifier: "PrivacyPolicyViewController")
				navigationController?.pushViewController(viewController, animated: true)
			}
			
			// Rate App
			if indexPath.row == 2 {
				rateApp()
			}
			
		}
	}
	
	//MARK: Reset section
	private func resetContent() {
		let alertController = UIAlertController(title: NSLocalizedString("Warning", comment: ""), message: NSLocalizedString("ContentResetAlertMessage", comment: ""), preferredStyle: .alert)
		let reset = UIAlertAction(title: NSLocalizedString("Reset", comment: ""), style: .destructive) { (action) in
			guard let codeTable = self.navigationController?.viewControllers.first as? CodeTableViewController else {
				return
			}
			CodeManager.shared.deleteAllCodes()
			codeTable.tableView.reloadData()
			self.navigationController?.popToRootViewController(animated: true)
		}
		let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
		alertController.addAction(reset)
		alertController.addAction(cancel)
		DispatchQueue.main.async {
			self.present(alertController, animated: true, completion: nil)
		}
	}
	
	//MARK: Themes section
	
	private func setupThemeIndicators() {
		for view: UIView in [lightThemeIndicator, darkThemeIndicator] {
			view.layer.cornerRadius = view.frame.width / 2
			view.layer.borderColor = UIColor.lightGray.cgColor
			view.layer.borderWidth = 1.0
			view.clipsToBounds = true
		}
	}
	
	//MARK: Other section
	
	private func rateApp() {
		guard let url = URL(string: "itms-apps://itunes.apple.com/us/app/apple-store/id1465561316?mt=8"),
			UIApplication.shared.canOpenURL(url) else {
				return
		}
		UIApplication.shared.open(url, options: [:], completionHandler: nil)
	}

}

extension SettingsTableViewController: ThemeDelegate {
	
	func updateAppearance() {
		tableView.backgroundColor = Theme.settingsTableViewBackgroundColor
		tableView.separatorColor = Theme.tableViewSeperatorColor
		tableView.reloadData()
	}
	
}



