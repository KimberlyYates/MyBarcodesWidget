
import Foundation
import UIKit
import AVFoundation

class BarcodeInfoPanel: UIView {
	
	static let BarcodeTypes: [String: AVMetadataObject.ObjectType] = [
		"QR": .qr,
		"Code 128": .code128,
		"Code 39": AVMetadataObject.ObjectType.code39,
		"Code 39 Mod 43": AVMetadataObject.ObjectType.code39Mod43,
		"Code 93": AVMetadataObject.ObjectType.code93,
		"DataMatrix": AVMetadataObject.ObjectType.dataMatrix,
		"EAN 13": AVMetadataObject.ObjectType.ean13,
		"EAN 8": AVMetadataObject.ObjectType.ean8,
		//"Face": AVMetadataObject.ObjectType.face,
		"Interleaved 2 of 5": AVMetadataObject.ObjectType.interleaved2of5,
		"ITF14": AVMetadataObject.ObjectType.itf14,
		"PDF417": AVMetadataObject.ObjectType.pdf417,
		"UPC-E": AVMetadataObject.ObjectType.upce,
		"Aztec": AVMetadataObject.ObjectType.aztec
	]
	
	let EXPANDED_HEIGHT_DIFF: CGFloat = 130
	
	var currVal: String? {
		didSet {
			if collapsed {
				setManually(manualButton)
			}
			valueTextField.text = currVal
			updateContinueButton(value: nil)
		}
	}
	var currType: AVMetadataObject.ObjectType? {
		didSet {
			guard currType != nil else {
				return
			}
			if collapsed {
				setManually(manualButton)
			}
			for i in 0..<pickerData.count {
				if BarcodeInfoPanel.BarcodeTypes[pickerData[i]] == currType! {
					typeWheel.selectRow(i, inComponent: 0, animated: false)
					break
				}
			}
		}
	}
	var pickerData: [String]!
	
	var continueButton: UIButton!
	var manualButton: UIButton!
	var valueTextField: UITextField!
	var typeWheel: UIPickerView!
	var resetButton: UIButton!
	var valueLabel: UILabel!
	var typeLabel: UILabel!
	var valueEditDismissView: UIView!
	
	var delegate: BarcodeInfoPanelDelegate?
	var collapsed: Bool!
	var origFrame: CGRect!
	var expandedFrame: CGRect!
	
	override init(frame: CGRect) {
		super.init(frame: frame)

		origFrame = frame
		expandedFrame = CGRect(x: frame.minX, y: frame.minY - EXPANDED_HEIGHT_DIFF, width: frame.width, height: frame.height + EXPANDED_HEIGHT_DIFF)
		pickerData = BarcodeInfoPanel.BarcodeTypes.keys.sorted()
		
		setupContButton()
		setupManualButton()
		setupInfoComponents()
		
		continueButton.layer.opacity = 0
		valueTextField.layer.opacity = 0
		typeWheel.layer.opacity = 0
		resetButton.layer.opacity = 0
		valueLabel.layer.opacity = 0
		typeLabel.layer.opacity = 0
		
		valueTextField.delegate = self
		
		backgroundColor = .white
		layer.cornerRadius = 10
		layer.masksToBounds = false
		clipsToBounds = true
		collapsed = true
		currType = BarcodeInfoPanel.BarcodeTypes[pickerData[0]]
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
		updateContinueButton(value: nil)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		if valueEditDismissView == nil {
			// IN INIT METHOD, SUPERVIEW IS NOT SET YET
			// Dismiss View, that removes focus from textField when user clicks somewhere on screen
			valueEditDismissView = UIView(frame: superview?.frame ?? frame)
			valueEditDismissView.isHidden = true
			superview?.addSubview(valueEditDismissView)
			// Dismiss Keyboard, when user taps somewhere else
			let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapOnView(_:)))
			valueEditDismissView.addGestureRecognizer(gestureRecognizer)
		}
	}
	
	@objc private func setManually(_ sender: UIButton) {
		self.manualButton.layer.opacity = 0
		self.manualButton.isEnabled = false
		UIView.animate(withDuration: 0.5, animations: {
			self.continueButton.layer.opacity = 1
			self.resetButton.layer.opacity = 1
			self.valueTextField.layer.opacity = 1
			self.typeWheel.layer.opacity = 1
			self.valueLabel.layer.opacity = 1
			self.typeLabel.layer.opacity = 1
			self.frame = self.expandedFrame
		}) { (res) in
			self.collapsed = false
		}
	}
	
	@objc private func deleteData(_ sender: UIButton) {
		currVal = nil
		currType = BarcodeInfoPanel.BarcodeTypes[pickerData[0]]
		
		self.continueButton.layer.opacity = 0
		self.resetButton.layer.opacity = 0
		self.valueTextField.layer.opacity = 0
		self.typeWheel.layer.opacity = 0
		self.valueLabel.layer.opacity = 0
		self.typeLabel.layer.opacity = 0
		self.manualButton.isEnabled = true
		UIView.animate(withDuration: 0.5, animations: {
			self.manualButton.layer.opacity = 1
			self.frame = self.origFrame
		}) { (res) in
			self.collapsed = true
		}
	}
	
	@objc private func continuePressed(_ sender: UIButton) {
		guard currVal != nil, currType != nil else {
			return
		}
		delegate?.didPressContinue(value: currVal!, type: currType!)
	}
	
	private func setupInfoComponents() {
		// Label displaying a section title
		valueLabel = UILabel()
		addSubview(valueLabel)
		valueLabel.text = NSLocalizedString("Value", comment: "")
		valueLabel.font = valueLabel.font.withSize(10)
		valueLabel.textColor = .lightGray
		valueLabel.translatesAutoresizingMaskIntoConstraints = false
		valueLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
		valueLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 10).isActive = true
		
		// Button that removes the selected barcode value and type and shrinks this view back to its original appearance
		resetButton = UIButton()
		resetButton.setTitle("×", for: .normal)
		resetButton.titleLabel?.font = resetButton.titleLabel?.font.withSize(25)
		resetButton.setTitleColor(.gray, for: .normal)
		addSubview(resetButton)
		resetButton.translatesAutoresizingMaskIntoConstraints = false
		resetButton.rightAnchor.constraint(equalTo: continueButton.leftAnchor, constant: -10).isActive = true
		resetButton.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 5).isActive = true
		resetButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
		resetButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
		resetButton.addTarget(self, action: #selector(deleteData(_:)), for: .touchUpInside)
		
		// Contains value of the barcode
		valueTextField = UITextField()
		valueTextField.borderStyle = .roundedRect
		addSubview(valueTextField)
		valueTextField.translatesAutoresizingMaskIntoConstraints = false
		valueTextField.placeholder = NSLocalizedString("BarcodeValue", comment: "")
		valueTextField.textColor = .black
		valueTextField.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 20).isActive = true
		valueTextField.rightAnchor.constraint(equalTo: resetButton.leftAnchor, constant: -10).isActive = true
		valueTextField.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 5).isActive = true
		
		// Label displaying a section title
		typeLabel = UILabel()
		addSubview(typeLabel)
		typeLabel.text = NSLocalizedString("Type", comment: "")
		typeLabel.font = valueLabel.font.withSize(10)
		typeLabel.textColor = .lightGray
		typeLabel.translatesAutoresizingMaskIntoConstraints = false
		typeLabel.topAnchor.constraint(equalTo: valueTextField.bottomAnchor, constant: 10).isActive = true
		typeLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 10).isActive = true
		
		// Data picker to select the barcode type
		typeWheel = UIPickerView()
		typeWheel.delegate = self
		typeWheel.dataSource = self
		addSubview(typeWheel)
		typeWheel.translatesAutoresizingMaskIntoConstraints = false
		typeWheel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 50).isActive = true
		typeWheel.rightAnchor.constraint(equalTo: resetButton.leftAnchor, constant: -10).isActive = true
		typeWheel.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 0).isActive = true
		typeWheel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
	}
	
	private func setupManualButton() {
		manualButton = UIButton()
		addSubview(manualButton)
		manualButton.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
		manualButton.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
		manualButton.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
		manualButton.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
		manualButton.translatesAutoresizingMaskIntoConstraints = false
		manualButton.setTitleColor(.black, for: .normal)
		manualButton.setTitle(NSLocalizedString("SetManually", comment: ""), for: .normal)
		manualButton.addTarget(self, action: #selector(setManually(_:)), for: .touchUpInside)
	}
	
	private func setupContButton() {
		continueButton = UIButton()
		addSubview(continueButton)
		continueButton.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.23).isActive = true
		continueButton.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
		continueButton.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
		continueButton.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
		continueButton.translatesAutoresizingMaskIntoConstraints = false
		continueButton.setTitle("→", for: .normal)
		continueButton.titleLabel?.font = continueButton.titleLabel?.font.withSize(25)
		continueButton.setTitleColor(.black, for: .normal)
		continueButton.layer.shadowRadius = 4
		continueButton.layer.shadowOffset = CGSize(width: 0, height: 0)
		continueButton.layer.shadowOpacity = 1
		continueButton.layer.shadowColor = UIColor.lightGray.cgColor
		continueButton.backgroundColor = .white
		continueButton.addTarget(self, action: #selector(continuePressed(_:)), for: .touchUpInside)
	}
	
	func updateContinueButton(value: String?) {
		let string = value ?? (valueTextField.text ?? "")
		if string.count > 0 {
			continueButton.isEnabled = true
			continueButton.setTitleColor(.black, for: .normal)
		} else {
			continueButton.isEnabled = false
			continueButton.setTitleColor(.lightGray, for: .normal)
		}
	}
	
}

extension BarcodeInfoPanel: UIPickerViewDelegate, UIPickerViewDataSource {
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return pickerData.count
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return pickerData[row]
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		currType = BarcodeInfoPanel.BarcodeTypes[pickerData[row]]
		updateContinueButton(value: nil)
	}
	
	func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
		var label: UILabel! = view as? UILabel
		if label == nil {
			label = UILabel()
		}
		label.font = UIFont(name: "Helvetica Neue", size: 12.0)
		label.text = pickerData[row]
		return label
	}
	
}

extension BarcodeInfoPanel: UITextFieldDelegate {
	
	@objc func tapOnView(_ sender: UIGestureRecognizer) {
		valueTextField.resignFirstResponder()
		valueEditDismissView.isHidden = true
		currVal = valueTextField.text ?? ""
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		valueEditDismissView.isHidden = true
		currVal = valueTextField.text ?? ""
		return true
	}
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		valueEditDismissView.isHidden = false
	}
	
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		updateContinueButton(value: string)
		return true
	}
	
	@objc func keyboardWillShow(notification: NSNotification) {
		if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
			self.frame.origin.y -= keyboardSize.height
		}
	}
	
	@objc func keyboardWillHide(notification: NSNotification) {
		if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
			self.frame.origin.y = self.origFrame.minY - (collapsed ? 0 : self.EXPANDED_HEIGHT_DIFF)
		}
	}
	
}


protocol BarcodeInfoPanelDelegate {
	
//	func didChangeValue(new value: String)
//
//	func didChangeType(new type: AVMetadataObject.ObjectType)
	
	func didPressContinue(value: String, type: AVMetadataObject.ObjectType)
	
}
