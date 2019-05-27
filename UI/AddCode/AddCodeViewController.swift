
import UIKit
import AVFoundation
import MapKit

class AddCodeViewController: UIViewController, CLLocationManagerDelegate {
	
	//MARK: Properties
	var barcodeValue: String?
	var barcodeType: AVMetadataObject.ObjectType?
	var barcodeLogo: UIImage?
	var imagePicked: Int? // Is set to keep track of which component opened the imagePicker
	var logoSearchResult: [[String: Any]]? // Array of dictionaries
	var logoImages: [UIImage]?
	var selectedLogoSuggestion: IndexPath?
	
	var selectedOverlay: MKCircle?
	var selectedLocation: CLLocation?
	var selectedRadius: CLLocationDistance?
	
	var layedOutSeperator: Bool = false
	let defaultZoomLevel: Double = 0.005
	
	var initialCodeData: Code?
	
	//MARK: Outlets
	@IBOutlet weak var logoImageResultButton: UIButton!
	@IBOutlet weak var nameTextField: UITextField!
	@IBOutlet weak var barcodeButton: UIButton!
	@IBOutlet weak var codeSelectionLabel: UILabel!
	@IBOutlet weak var logoOptionalLabel: UILabel!
	@IBOutlet weak var seperator: UIView!
	
	@IBOutlet weak var mapToolbar: UIToolbar!
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var setLocationButton: UIButton!
	@IBOutlet weak var radiusSlider: UISlider!
	@IBOutlet weak var mapViewLongPressRecognizer: UILongPressGestureRecognizer!
	@IBOutlet weak var mapViewTapRecognizer: UITapGestureRecognizer!
	@IBOutlet weak var clearButton: UIButton!
	@IBOutlet weak var searchBar: UISearchBar!
	@IBOutlet weak var locationDescriptionLabel: UILabel!
	
	@IBOutlet weak var mapShrinkedAnchor: NSLayoutConstraint!
	@IBOutlet weak var mapExpandedAnchor: NSLayoutConstraint!
	
	@IBOutlet weak var doneButton: UIBarButtonItem!
	var saveButton: UIBarButtonItem?
	
	var logoAreaHighlightView: UIView? // A view that covers the logo area, that is used to show a red border when a logo selection is missing
	var gradientBackgroundView: UIView?
	var suggestionsLoadingIndicator: UIActivityIndicatorView?
	
	var nameEditDismissView: UIView! // Transparent view that is layed above all content when user is editing name; tapping it will dismiss the keyboard
	
    override func viewDidLoad() {
        super.viewDidLoad()

		/* TEST */
//		var a = BarcodeInfoPanel(frame: CGRect(x: 10, y: view.frame.height - 70, width: view.frame.width - 20, height: 50))
////		a.layer.masksToBounds = false
////		a.layer.shadowColor = UIColor.black.cgColor
////		a.layer.shadowOpacity = 1
////		a.layer.shadowOffset = CGSize(width: 0, height: 0)
////		a.layer.shadowRadius = 5
//		a.layer.borderColor = UIColor.lightGray.cgColor
//		a.layer.borderWidth = 1
//		view.addSubview(a)
//		view.bringSubviewToFront(a)
		/* TEST */
		
		// to highlight when user wants to create code, but barcode info is missing
		barcodeButton.layer.borderWidth = 2.0
		nameTextField.layer.borderWidth = 2.0
		barcodeButton.layer.borderColor = UIColor.clear.cgColor
		nameTextField.layer.borderColor = UIColor.clear.cgColor
		
		nameTextField.delegate = self
		nameTextField.backgroundColor = Theme.textFieldBackgroundColor
		
		logoOptionalLabel.textColor = Theme.logoDescriptionTextColor
		
		searchBar.layer.opacity = 0.0
		mapToolbar.layer.opacity = 0.0
		clearButton.layer.opacity = 0.0
		mapView.delegate = self
		searchBar.delegate = self
		
		layoutBarcodeScanButton()
		layoutNameTextField()
		
		// Logo ImageView that shows an image when selected from local library
		logoImageResultButton.layer.cornerRadius = 10
		logoImageResultButton.layer.borderWidth = 1.0
		logoImageResultButton.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
		logoImageResultButton.clipsToBounds = true
		
		radiusSlider.isEnabled = false
		
		setupGradientBackground()
		
		if initialCodeData != nil {
			setupForCodeModification(code: initialCodeData!)
		}
    }
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		if !layedOutSeperator {
			layoutSeperator()
			layedOutSeperator = true
		}
	}

	@IBAction func cancel(_ sender: UIBarButtonItem) {
		dismiss(animated: true, completion: nil)
	}
	
	//MARK: Layout Methods
	
	private func layoutNameTextField() {
		nameEditDismissView = UIView(frame: view.frame)
		nameEditDismissView.isHidden = true
		view.addSubview(nameEditDismissView)
		// Dismiss Keyboard, when user taps somewhere else
		let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapOnView(_:)))
		nameEditDismissView.addGestureRecognizer(gestureRecognizer)
	}
	
	private func layoutSeperator() {
		let space = (mapView.frame.minY - nameTextField.frame.maxY) / 2
		seperator.center.y = nameTextField.frame.maxY + space
	}
	
	private func setupGradientBackground() {
		let colours:[CGColor] = Theme.addCodeBackgroundGradientColors
		let locations:[NSNumber] = [0, 0.6]
		
		let gradientLayer = CAGradientLayer()
		gradientLayer.colors = colours
		gradientLayer.locations = locations
		gradientLayer.startPoint = CGPoint(x: 0, y: 0)
		gradientLayer.endPoint = CGPoint(x: 1, y: 1)
		gradientLayer.frame = UIScreen.main.bounds
		
		// Depending on whether the gradient layer was set before, either create a new one or edit the existing
		if gradientBackgroundView == nil {
			gradientBackgroundView = UIView(frame: UIScreen.main.bounds)
			self.view.insertSubview(gradientBackgroundView!, at: 0)
		} else {
			gradientBackgroundView!.layer.sublayers?.removeAll()
		}
		gradientBackgroundView!.layer.addSublayer(gradientLayer)
	}
	
	private func layoutBarcodeScanButton() {
		barcodeButton.layer.shadowOpacity = 1.0
		barcodeButton.layer.shadowColor = UIColor.lightGray.cgColor
		barcodeButton.layer.shadowRadius = 3.0
		barcodeButton.layer.borderWidth = 2
		barcodeButton.backgroundColor = Theme.barcodeSelectionButtonBackgroundColor
		
		codeSelectionLabel.backgroundColor = Theme.buttonBackgroundColor
		codeSelectionLabel.textColor = Theme.buttonTextColor
	}
	
	func setupForCodeModification(code: Code) {
		nameTextField.text = code.name
		logoImageResultButton.setImage(code.logo, for: .normal)
		setBarcode(value: code.value, type: code.type)
		if code.notification != nil {
			setNewLocation(location: code.notification!.location, distance: code.notification!.radius)
			showLocationOnMap(location: code.notification!.location, zoomLevel: calcZoomLevelForRadius(radius: code.notification!.radius))
			
			setLocationButton.layer.opacity = 0.0
			clearButton.layer.opacity = 1.0
			
			allowMapInteraction(allow: false)
		}
		
		saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save(_:)))
		navigationItem.rightBarButtonItem = saveButton
	}
	
	//MARK: Done & Save
	
	// Save an existing code that was modified in this session
	@IBAction func save(_ sender: UIBarButtonItem) {
		guard initialCodeData != nil,
			barcodeType != nil,
			barcodeValue != nil,
			nameTextField.text != nil else {
			return
		}
		initialCodeData?.type = barcodeType!
		initialCodeData?.value = barcodeValue!
		initialCodeData?.logo = barcodeLogo
		initialCodeData?.name = nameTextField.text!
		if initialCodeData?.notification != nil {
			LocationService.shared.unregisterLocalNotification(notification: initialCodeData!.notification!)
		}
		if selectedLocation != nil && selectedRadius != nil {
			let notification = LocationNotification(codeID: initialCodeData!.id, location: selectedLocation!, radius: selectedRadius!, alertType: .onEntry, isEnabled: true)
			initialCodeData?.notification = notification
			LocationService.shared.registerLocalNotification(notification: notification)
		}
		CodeManagerArchive.saveCodeManager()
		performSegue(withIdentifier: "unwindToCodeTableViewController", sender: sender)
	}
	
	// Called when the user wants to add a new code from the currently entered information
	@IBAction func done(_ sender: UIBarButtonItem) {
		var failed = false
		if barcodeValue == nil || barcodeType == nil {
			barcodeButton.layer.borderColor = UIColor.red.cgColor
			failed = true
		} else {
			barcodeButton.layer.borderColor = UIColor.clear.cgColor
		}
		if nameTextField.text == nil || nameTextField.text!.count == 0 {
			nameTextField.layer.borderColor = UIColor.red.cgColor
			failed = true
		} else {
			nameTextField.layer.borderColor = UIColor.clear.cgColor
		}
		if failed {
			return
		}
		
		let code = Code(name: nameTextField.text!, value: barcodeValue!, type: barcodeType!, logo: barcodeLogo)
		if selectedLocation != nil && selectedRadius != nil {
			let notification = LocationNotification(codeID: code.id, location: selectedLocation!, radius: selectedRadius!, alertType: .onEntry, isEnabled: true)
			code.notification = notification
		}
		CodeManager.shared.addCode(code: code)
		CodeManagerArchive.saveCodeManager()
		
		self.dismiss(animated: true, completion: nil)
	}
	
	//MARK: Barcode
	
	// Called when user clicks on the button that holds the barcode (if selected)
	@IBAction func selectBarcode(_ sender: UIButton) {
		//TODO: For now, directly go to scanning VC
		// in future, user should be able to select a picture from local library to scan it
		guard let scanViewController = self.storyboard!.instantiateViewController(withIdentifier: "ScanCodeViewController") as? ScanCodeViewController else {
			return
		}
		self.navigationController?.pushViewController(scanViewController, animated: true)
	}
	
	func setBarcode(value: String, type: AVMetadataObject.ObjectType) {
		barcodeValue = value
		barcodeType = type
		codeSelectionLabel.isHidden = true
		barcodeButton.setImage(Utils.generateCode(value: value, codeType: type, targetSize: barcodeButton.frame.size), for: .normal)
	}
	
	//MARK: Logo
	@IBAction func pickLocalLogo(_ sender: UIButton) {
		// First hide the "missing logo" highlighter
		logoAreaHighlightView?.layer.borderColor = UIColor.clear.cgColor
		
		// Create imagepicker to select logo from library
		let imagePickerController = UIImagePickerController()
		imagePickerController.delegate = self
		imagePicked = 1 // identifies this imagePicker in the delegate method
		
		if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
			imagePickerController.sourceType = .photoLibrary
			imagePickerController.allowsEditing = true
			self.present(imagePickerController, animated: true, completion: nil)
		} else {
			let failController = UIAlertController(title: NSLocalizedString("Oops", comment: ""), message: NSLocalizedString("LibraryFailAlertControllerText", comment: ""), preferredStyle: .alert)
			failController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
			DispatchQueue.main.async {
				self.present(failController, animated: true, completion: nil)
			}
		}
	}
	
	@objc private func logoButtonTouchDown(_ sender: UIButton) {
		sender.layer.shadowColor = UIColor.clear.cgColor
	}
	
	@objc private func logoButtonDragExit(_ sender: UIButton) {
		sender.layer.shadowColor = UIColor.lightGray.cgColor
	}
	
	@objc private func logoButtonTouchUpInside(_ sender: UIButton) {
		sender.layer.shadowColor = UIColor.lightGray.cgColor
	}
	
	//MARK: Notification Location
	
	@IBAction func expandMap(_ sender: Any) {
		UIView.animate(withDuration: 0.3) {
			self.setLocationButton.layer.opacity = 0
			self.seperator.layer.opacity = 0.0
			self.locationDescriptionLabel.layer.opacity = 0.0
			self.clearButton.layer.opacity = 0.0
		}
		UIView.animate(withDuration: 1.0, animations: {
			self.mapShrinkedAnchor.priority = UILayoutPriority.defaultLow
			self.mapExpandedAnchor.priority = UILayoutPriority.defaultHigh
			self.view.layoutIfNeeded()
			self.mapToolbar.layer.opacity = 1.0
			self.searchBar.layer.opacity = 1.0
		}) { (result) in
			if !Settings.shared.hasSetLocation {
				self.showToast(message: NSLocalizedString("SettingLocationExplanation", comment: ""))
			}
		}
		
		initLocationTracking()
		
		if selectedLocation == nil {
			mapView.userTrackingMode = .follow
		} // else, the mapview will already be focused on the location, which happens when calling hideMap()
		allowMapInteraction(allow: true)
		
		doneButton?.isEnabled = false
		saveButton?.isEnabled = false
	}
	
	@IBAction func hideMap(_ sender: UIBarButtonItem) {
		allowMapInteraction(allow: false)
		doneButton?.isEnabled = true
		saveButton?.isEnabled = true
		
		UIView.animate(withDuration: 1.0, animations: {
			self.mapShrinkedAnchor.priority = UILayoutPriority.defaultHigh
			self.mapExpandedAnchor.priority = UILayoutPriority.defaultLow
			self.view.layoutIfNeeded()
			
			self.mapToolbar.layer.opacity = 0.0
			self.searchBar.layer.opacity = 0.0
			self.seperator.layer.opacity = 1.0
			if self.selectedLocation == nil || self.selectedRadius == nil {
				self.setLocationButton.layer.opacity = 0.7
			}
		}, completion: { (error) in
			if self.selectedLocation != nil && self.selectedRadius != nil {
				// if location is set, focus on the selected location
				self.showLocationOnMap(location: self.selectedLocation!, zoomLevel: self.calcZoomLevelForRadius(radius: self.selectedRadius!))
			}
		})
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
			UIView.animate(withDuration: 0.3, animations: {
				if self.selectedLocation != nil && self.selectedRadius != nil {
					self.clearButton.layer.opacity = 1.0
				}
				self.locationDescriptionLabel.layer.opacity = 1.0
			})
		}
	}
	
	private func allowMapInteraction(allow: Bool) {
		mapView.isZoomEnabled = allow
		mapView.isPitchEnabled = allow
		mapView.isRotateEnabled = allow
		mapView.isScrollEnabled = allow
		mapViewTapRecognizer.isEnabled = !allow
		mapViewLongPressRecognizer.isEnabled = allow
	}
	
	@IBAction func updateRadius(_ sender: UISlider) {
		guard selectedOverlay != nil, selectedRadius != nil, selectedLocation != nil else {
			return
		}
		
		selectedRadius = CLLocationDistance(exactly: radiusSlider.value)
		
		mapView.removeOverlay(selectedOverlay!)
		selectedOverlay = MKCircle(center: selectedLocation!.coordinate, radius: selectedRadius!)
		mapView.addOverlay(selectedOverlay!)
	}
	
	@IBAction func clearLocation(_ sender: UIButton) {
		sender.layer.opacity = 0.0
		if selectedOverlay != nil {
			mapView.removeOverlay(selectedOverlay!)
		}
		selectedOverlay = nil
		selectedLocation = nil
		selectedRadius = nil
		radiusSlider.isEnabled = false
		UIView.animate(withDuration: 0.3) {
			self.setLocationButton.layer.opacity = 0.7
		}
	}
	
	//MARK: Barcode Name
	
	@objc func tapOnView(_ sender: UIGestureRecognizer) {
		nameTextField.resignFirstResponder()
		nameEditDismissView.isHidden = true
	}
	
}

extension AddCodeViewController: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		nameEditDismissView.isHidden = true
		return true
	}
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		nameEditDismissView.isHidden = false
	}
	
}

extension AddCodeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		dismiss(animated: true, completion: nil)
	}
	
	@objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		guard imagePicked != nil,
			let selectedImage = info[UIImagePickerController.InfoKey.editedImage.rawValue] as? UIImage else {
			print("No valid Image selected")
			return
		}
		if imagePicked! == 0 {
			// Barcode selection
			barcodeButton.setBackgroundImage(selectedImage, for: .normal)
			barcodeButton.setTitle(nil, for: .normal)
		}
		if imagePicked! == 1 {
			// Logo selection
			logoImageResultButton.setBackgroundImage(selectedImage, for: .normal)
			barcodeLogo = selectedImage
		}
		imagePicked = nil
		dismiss(animated: true, completion: nil)
	}
	
}

extension AddCodeViewController: MKMapViewDelegate {
	
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		//Add if clause for other overlays
		guard let circle = overlay as? MKCircle else {
			print("Overlay not a RegionOverlay.")
			return MKOverlayRenderer()
		}
		let renderer = MKCircleRenderer(overlay: overlay)
		
		renderer.lineWidth = 2
		renderer.fillColor = circle == selectedOverlay ? UIColor(red: 0.3922, green: 0.949, blue: 0, alpha: 0.5) : UIColor(red: 0.3922, green: 0.949, blue: 0, alpha: 0.2)
		renderer.strokeColor = circle == selectedOverlay ? UIColor(red: 0.3922, green: 0.949, blue: 0, alpha: 0.5) : UIColor(red: 0.3922, green: 0.949, blue: 0, alpha: 0.2)
		
		return renderer
	}
	
	@IBAction func showUserLocation(_ sender: UIBarButtonItem) {
		self.mapView.userTrackingMode = .follow
	}
	
	private func initLocationTracking() {
		if CLLocationManager.locationServicesEnabled() {
			LocationService.shared.locationManager.requestWhenInUseAuthorization()
		} else {
			//location services not available
			//TODO: alert to user
			dismiss(animated: true, completion: nil)
		}
	}
	
	//add annotation when long press on map
	@IBAction func addAnnotation(_ sender: UILongPressGestureRecognizer) {
		guard sender.state == .began else {
			return
		}
		let point = sender.location(in: mapView)
		let coordinates = mapView.convert(point, toCoordinateFrom: mapView)
		setNewLocation(location: CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude),
					   distance: CLLocationDistance(exactly: radiusSlider.value)!)
	}
	
	private func setNewLocation(location: CLLocation, distance: CLLocationDistance) {
		self.selectedLocation = location
		self.selectedRadius = distance
		if selectedOverlay != nil {
			mapView.removeOverlay(selectedOverlay!)
		}
		selectedOverlay = MKCircle(center: location.coordinate, radius: self.selectedRadius!)
		mapView.addOverlay(selectedOverlay!)
		
		radiusSlider.isEnabled = true
		
		if !Settings.shared.hasSetLocation {
			// Save in settings, so that explanation won't be shown next time user opens map
			Settings.shared.hasSetLocation = true
			SettingsArchive.save()
		}
	}
	
	private func showLocationOnMap(location: CLLocation, zoomLevel: Double) {
		let span = MKCoordinateSpan(latitudeDelta: zoomLevel, longitudeDelta: zoomLevel)
		let region = MKCoordinateRegion(center: location.coordinate, span: span)
		mapView.setRegion(region, animated: true)
	}
	
	private func calcZoomLevelForRadius(radius: Double) -> Double {
		return defaultZoomLevel + 0.00002 * radius
	}
	
}

extension AddCodeViewController: UISearchBarDelegate {
	
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
		search()
	}
	
	private func search() {
		let localSearchRequest = MKLocalSearch.Request()
		localSearchRequest.naturalLanguageQuery = searchBar.text
		localSearchRequest.region = mapView.region
		
		let localSearch = MKLocalSearch(request: localSearchRequest)
		localSearch.start { (localSearchResponse, error) -> Void in
			if error != nil {
				//os_log(log, log: OSLog.default, type: .error)
			}
			
			if localSearchResponse == nil {
				//No results
				
			} else {
				let firstResult = localSearchResponse!.boundingRegion
				self.mapView.setRegion(firstResult, animated: true)
			}
		}
	}
	
}
