

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
	
	//MARK: Properties
	var barcodeInstrumentsHidden: Bool!
	var currIndexPath: IndexPath! // current
	var selectedCode: Code? // Selected code object if collectionView cell is clicked
	var defaultContentScale: CGFloat?
	var saveCode: Bool! // Indicates whether the codemanager object should be saved when the instruments of a code will hide
	
	//MARK: Outlets
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var barcodeImageView: UIImageView!
	@IBOutlet weak var barcodeBackButton: UIButton!
	@IBOutlet weak var barcodeTitleLabel: UILabel!
	@IBOutlet weak var collectionViewBackButton: UIButton!
	@IBOutlet weak var collectionViewForwardButton: UIButton!
	@IBOutlet weak var pageControlStackView: UIStackView!
	@IBOutlet weak var instrumentsBackgroundView: UIView!
	
	@IBOutlet weak var barcodeSizeLabel: UILabel!
	@IBOutlet weak var incSizeButton: UIButton!
	@IBOutlet weak var decSizeButton: UIButton!
	
	@IBOutlet weak var valueLabel: UILabel!
	@IBOutlet weak var barcodeShrinkedAnchor: NSLayoutConstraint!
	@IBOutlet weak var barcodeExpandedAnchor: NSLayoutConstraint!
	
	//MARK: Init
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		// Load Code Manager if saved
		if let savedCodeManager = CodeManagerArchive.loadCodeManager() {
			CodeManager.shared = savedCodeManager
		}
		
//		#if SCREENSHOTS || true
//			CodeManager.shared.deleteAllCodes()
//			CodeManager.shared.addCode(code: Code(name: "Coupon", value: "10985328140279", type: .qr, logo: nil))
//			CodeManager.shared.addCode(code: Code(name: "Coffee Shop", value: "10985328140279", type: .code128, logo: nil))
//			CodeManager.shared.addCode(code: Code(name: "Flight Ticket", value: "10985328140279", type: .pdf417, logo: nil))
//		#endif
		
		collectionView.delegate = self
		collectionView.dataSource = self
		
		initInstruments()
		
		// Back button press leads back to collectionView
		barcodeBackButton.addTarget(self, action: #selector(didPressBarcodeBackButton(_:)), for: .touchUpInside)
		
		// Set index of cell that is currently visible on leftmost position
		currIndexPath = IndexPath(row: 0, section: 0)
		// Disable Back Button, since we start at the very left
		collectionViewBackButton.isEnabled = false
		collectionViewBackButton.setTitleColor(.gray, for: .normal)
    }
	
	// The instruments provide options for the currently shown barcode.
	// Toggled by long press on the barode.
	private func initInstruments() {
		// Hide instruments at first, so that user only sees barcode
		barcodeBackButton.layer.opacity = 0
		barcodeTitleLabel.layer.opacity = 0
		barcodeImageView.layer.opacity = 0
		instrumentsBackgroundView.layer.opacity = 0
		valueLabel.layer.opacity = 0
		barcodeInstrumentsHidden = true
		
//		barcodeTitleLabel.layer.shadowColor = UIColor.black.cgColor
//		barcodeTitleLabel.layer.shadowOpacity = 1.0
//		barcodeTitleLabel.layer.shadowRadius = 4.0
		barcodeBackButton.layer.shadowColor = UIColor.gray.cgColor
		barcodeBackButton.layer.shadowOpacity = 1.0
		barcodeBackButton.layer.shadowRadius = 4.0
		
		// A tap should hide the barcode
		let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didPressBarcodeImage(_:)))
		barcodeImageView.isUserInteractionEnabled = true
		barcodeImageView.addGestureRecognizer(tapRecognizer)
		
		// A long press should toggle the instruments
		let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressBarcodeImage(_:)))
		barcodeImageView.addGestureRecognizer(longPressRecognizer)
		
	}
        
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        completionHandler(NCUpdateResult.newData)
    }
	
	//MARK: Instrument Actions
	
	@objc private func didPressBarcodeBackButton(_ sender: UIButton) {
		// Hide only instruments, still show barcode
		toggleInstruments()
		if saveCode {
			CodeManagerArchive.saveCodeManager()
		}
	}
	
	@objc private func didPressBarcodeImage(_ sender: UITapGestureRecognizer) {
		UIView.animate(withDuration: 0.25) {
			self.barcodeImageView.layer.opacity = 0
			self.valueLabel.layer.opacity = 0
		}
		selectedCode = nil
	}
	
	@objc private func didLongPressBarcodeImage(_ sender: UILongPressGestureRecognizer) {
		if sender.state == .began {
			toggleInstruments()
		}
	}
	
	private func toggleInstruments() {
		barcodeInstrumentsHidden = !barcodeInstrumentsHidden
		let target: Float = barcodeInstrumentsHidden ? 0.0 : 0.9
		UIView.animate(withDuration: 0.25) {
			self.barcodeBackButton.layer.opacity = target
			self.barcodeTitleLabel.layer.opacity = target
			self.instrumentsBackgroundView.layer.opacity = target
		}
	}
	
	@IBAction func incBarcodeSize(_ sender: UIButton) {
		guard selectedCode != nil else {
			return
		}
		selectedCode!.displaySize = min(1.0, selectedCode!.displaySize + 0.1)
		updateDisplaySize()
		saveCode = true
	}
	
	@IBAction func decBarcodeSize(_ sender: UIButton) {
		guard selectedCode != nil else {
			return
		}
		selectedCode!.displaySize = max(0.1, selectedCode!.displaySize - 0.1)
		updateDisplaySize()
		saveCode = true
	}
	
	private func updateDisplaySize() {
		guard selectedCode != nil, defaultContentScale != nil else {
			return
		}
		barcodeSizeLabel.text = "\(Int(round(selectedCode!.displaySize * 100))) %"
		barcodeImageView.contentScaleFactor = defaultContentScale! + defaultContentScale! * CGFloat(1.0 - selectedCode!.displaySize)
	}
	
	private func updateValueLabel(animated: Bool) {
		guard self.selectedCode != nil else {
			return
		}
		UIView.animate(withDuration: animated ? 0.5 : 0.0) {
			self.barcodeExpandedAnchor.priority = self.selectedCode!.showValue ? .defaultLow : .defaultHigh
			self.barcodeShrinkedAnchor.priority = self.selectedCode!.showValue ? .defaultHigh : .defaultLow
			self.view.layoutIfNeeded()
		}
	}
	
	//MARK: Paging
	@IBAction func pageBack(_ sender: UIButton) {
		let newIndexPath = IndexPath(row: max(currIndexPath.row - 1, 0), section: 0)
		collectionView.scrollToItem(at: newIndexPath, at: .left, animated: true)
		currIndexPath = newIndexPath
		updatePagingButtonAppearance()
	}
	
	@IBAction func pageForward(_ sender: UIButton) {
		let newIndexPath = IndexPath(row: min(currIndexPath.row + 1, collectionView.numberOfItems(inSection: 0) - 1), section: 0)
		collectionView.scrollToItem(at: newIndexPath, at: .left, animated: true)
		currIndexPath = newIndexPath
		updatePagingButtonAppearance()
	}
	
	private func updatePagingButtonAppearance() {
		// Enable/Disable buttons, if end of the collectionView has been reached
		if currIndexPath.row == 0 {
			collectionViewBackButton.isEnabled = false
			collectionViewBackButton.setTitleColor(.gray, for: .normal)
		} else {
			collectionViewBackButton.isEnabled = true
			collectionViewBackButton.setTitleColor(.black, for: .normal)
		}
		if currIndexPath.row == collectionView.numberOfItems(inSection: 0) - 1 {
			collectionViewForwardButton.isEnabled = false
			collectionViewForwardButton.setTitleColor(.gray, for: .normal)
		} else {
			collectionViewForwardButton.isEnabled = true
			collectionViewForwardButton.setTitleColor(.black, for: .normal)
		}
	}
	
}

extension TodayViewController: UICollectionViewDelegate, UICollectionViewDataSource {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		let count = CodeManager.shared.count()
		
		if count == 0 {
			collectionView.setEmptyMessage(NSLocalizedString("CollectionViewEmptyMessage", comment: ""))
			pageControlStackView.isHidden = true
		} else {
			collectionView.removeEmptyMessage()
			pageControlStackView.isHidden = false
		}
		
		return count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CodeCollectionViewCell", for: indexPath) as? CodeCollectionViewCell else {
			fatalError("Failed to dequeue collectionView cell!")
		}
		cell.code = CodeManager.shared.getCodes()[indexPath.row]
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let code = CodeManager.shared.getCodes()[indexPath.row]
		if let image = Utils.generateCode(value: code.value, codeType: code.type, targetSize: barcodeImageView.frame.size),
			let insetImage = image.imageWithInsets(insets: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)) {
			barcodeImageView.image = insetImage
			// scale factor will be correct after setting the image
			if defaultContentScale == nil {
				defaultContentScale = barcodeImageView.contentScaleFactor
			}
			
			saveCode = false
			selectedCode = code
			barcodeTitleLabel.text = code.name
			valueLabel.text = code.value
			
			updateDisplaySize()
			updateValueLabel(animated: false)
			
			UIView.animate(withDuration: 0.25) {
				self.barcodeImageView.layer.opacity = 1.0
				self.valueLabel.layer.opacity = 1.0
			}
			
//			// Adapt the background color of the tools to match the selected code's logo
//			let averageColor = code.logo?.averageColor ?? .white
			barcodeBackButton.backgroundColor = .white
			barcodeTitleLabel.backgroundColor = .white
		} else {
			//TODO: Error
		}
	}
	
}


