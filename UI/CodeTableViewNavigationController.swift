
import UIKit

class CodeTableViewNavigationController: UINavigationController {

	//MARK: Properties
	var sideMenu: SideMenu!
	var addButton: SideMenuButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()

        setupSideMenu()
    }

	private func setupSideMenu() {
		sideMenu = SideMenu(superview: view)
		let frameTemp = CGRect(x: view.frame.maxX + 5, // +5 for shadow
			y: view.frame.height - (UIScreen.main.nativeBounds.height == 2436 ? 220 : 190),
			width: 150,
			height: 60)
		
		let addFrame = CGRect(x: frameTemp.minX, y: frameTemp.minY, width: frameTemp.width, height: frameTemp.height)
		addButton = SideMenuButton(frame: addFrame, title: getAddButtonTitle(), image: nil, color: Theme.buttonBackgroundColor) { (sender) in
			guard let navigationController = self.storyboard?.instantiateViewController(withIdentifier: "AddCodeNavigationController") else {
				return
			}
			self.present(navigationController, animated: true, completion: nil)
		}
		sideMenu.addButton(button: addButton, alwaysOn: true)
	}
	
	private func getAddButtonTitle() -> NSAttributedString {
		return NSAttributedString(string: "  +", attributes: [NSAttributedString.Key.font: UIFont(name: "Times", size: 45)!, NSAttributedString.Key.foregroundColor: Theme.buttonTextColor])
	}
	
}

extension CodeTableViewNavigationController: ThemeDelegate {
	
	func updateAppearance() {
		addButton.backgroundColor = Theme.buttonBackgroundColor
		addButton.setAttributedTitle(getAddButtonTitle(), for: .normal)
	}
	
}
