

import UIKit
import AVFoundation

class ScanCodeViewController: UIViewController {

	//MARK: Properties
	var captureSession: AVCaptureSession!
	var videoPreviewLayer: AVCaptureVideoPreviewLayer!
	var codeHighlightView: UIView!
	var addButton: UIButton!
	
	var infoPanel: BarcodeInfoPanel!
	
	var currVal: String?
	var currType: AVMetadataObject.ObjectType?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		captureSession = AVCaptureSession()
		initCaptureSession()
		
		videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
		initPreviewLayer()
		
		codeHighlightView = UIView()
		initHighlightView()
		
//		setupAddButton()
		setupInfoPanel()
		
		captureSession.startRunning()
    }
	
//	@objc private func didSelectCode(_ sender: UIButton) {
//		guard let dest = navigationController?.viewControllers.first as? AddCodeViewController,
//			currVal != nil, currType != nil else {
//			return
//		}
//		dest.setBarcode(value: currVal!, type: currType!)
//		navigationController?.popViewController(animated: true)
//	}
	
	//MARK: Setup Methods
	
	private func setupInfoPanel() {
		infoPanel = BarcodeInfoPanel(frame: CGRect(x: 10, y: view.frame.height - 70, width: view.frame.width - 20, height: 50))
		infoPanel.layer.borderColor = UIColor.lightGray.cgColor
		infoPanel.layer.borderWidth = 1
		view.addSubview(infoPanel)
		infoPanel.delegate = self
		
		infoPanel.layer.shadowRadius = 3
		infoPanel.layer.shadowOpacity = 1
		infoPanel.layer.shadowOffset = CGSize(width: 0, height: 0)
		infoPanel.layer.shadowColor = UIColor.gray.cgColor
	}
	
	private func initHighlightView() {
		codeHighlightView.layer.borderColor = UIColor.green.cgColor
		codeHighlightView.layer.borderWidth = 2
		view.addSubview(codeHighlightView)
		view.bringSubviewToFront(codeHighlightView)
	}
	
	private func initPreviewLayer() {
		// Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
		videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
		videoPreviewLayer.frame = view.layer.bounds
		view.layer.addSublayer(videoPreviewLayer!)
	}
	
	private func initCaptureSession() {
		if #available(iOS 10.2, *) {
			let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
			
			guard let captureDevice = deviceDiscoverySession.devices.first else {
				let failController = UIAlertController(title: NSLocalizedString("Oops", comment: ""), message: NSLocalizedString("CameraFailAlertControllerText", comment: ""), preferredStyle: .alert)
				failController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
				self.present(failController, animated: true, completion: nil)
				return
			}
			
			do {
				// Get an instance of the AVCaptureDeviceInput class using the previous device object.
				let input = try AVCaptureDeviceInput(device: captureDevice)
				
				// Set the input device on the capture session.
				captureSession.addInput(input)
				
				// Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
				let captureMetadataOutput = AVCaptureMetadataOutput()
				captureSession.addOutput(captureMetadataOutput)
				
				// Set delegate and use the default dispatch queue to execute the call back
				captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
				captureMetadataOutput.metadataObjectTypes = [.qr, .code128, .ean8, .aztec, .code39, .code39Mod43, .code93, .ean13, .interleaved2of5, .itf14, .pdf417, .upce]
			} catch {
				// If any error occurs, simply print it out and don't continue any more.
				print(error)
				return
			}
		} else {
			// Fallback on earlier versions
			//TODO
		}
	}
	
	private func setupAddButton() {
		//setup addButton
		addButton = UIButton(type: .custom)
		let title = NSAttributedString(string: ">", attributes: [NSAttributedString.Key.font: UIFont(name: "AmericanTypewriter", size: 45)!])
		addButton.setAttributedTitle(title, for: .normal)
		addButton.setTitleColor(UIColor.black, for: .normal)
		addButton.setTitleColor(UIColor.lightGray, for: .highlighted)
		let size = 60
		addButton.frame = CGRect(x: 0, y: 0, width: size, height: size)
		self.view.insertSubview(addButton, aboveSubview: self.view)
//		setAddButtonActive(active: false)
		addButton.center = CGPoint(x: self.view.frame.width - 30 - (self.addButton.frame.width / 2), y: self.view.frame.height - 80 - (self.addButton.frame.height / 2))
		if UIScreen.main.nativeBounds.height == 2436 {
			//iPhone X
			addButton.center = CGPoint(x: self.view.frame.width - 30 - (self.addButton.frame.width / 2), y: self.view.frame.height - 120 - (self.addButton.frame.height / 2))
		}
		addButton.layer.cornerRadius = addButton.frame.height / 2
		addButton.layer.shadowColor = UIColor.black.cgColor
		addButton.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
		addButton.layer.shadowOpacity = 1.0
		addButton.layer.shadowRadius = 3.0
//		addButton.addTarget(self, action: #selector(self.didSelectCode(_:)), for: UIControl.Event.touchUpInside)
	}
	
//	private func setAddButtonActive(active: Bool) {
//		addButton.isEnabled = active
//		if active {
//			addButton.backgroundColor = .green
//		} else {
//			addButton.backgroundColor = .lightGray
//		}
//	}

}

extension ScanCodeViewController: AVCaptureMetadataOutputObjectsDelegate {
	
	func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
//		setAddButtonActive(active: metadataObjects.count > 0)
		guard metadataObjects.count > 0 else {
			codeHighlightView.frame = CGRect.zero
			return
		}
		
		// Get the metadata object.
		let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
		
		infoPanel.currVal = metadataObj.stringValue
		infoPanel.currType = metadataObj.type
		infoPanel.updateContinueButton(value: nil)
		
		let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
		codeHighlightView.frame = barCodeObject!.bounds
	}
	
}

extension ScanCodeViewController: BarcodeInfoPanelDelegate {
	
	func didPressContinue(value: String, type: AVMetadataObject.ObjectType) {
		guard let dest = navigationController?.viewControllers.first as? AddCodeViewController else {
				return
		}
		dest.setBarcode(value: value, type: type)
		navigationController?.popViewController(animated: true)
	}
	
}
