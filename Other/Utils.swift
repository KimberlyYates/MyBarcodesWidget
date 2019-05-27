
import Foundation
import AVFoundation
import UIKit
import RSBarcodes_Swift
import StoreKit

class Utils {
	
	static func generateID() -> String {
		return UUID().uuidString
	}
	
	static func generateCode(value: String, codeType: AVMetadataObject.ObjectType, targetSize: CGSize) -> UIImage? {
		guard let image = RSUnifiedCodeGenerator.shared.generateCode(value, machineReadableCodeObjectType: codeType.rawValue) else {
			return nil
		}
		return RSAbstractCodeGenerator.resizeImage(image, targetSize: targetSize, contentMode: UIView.ContentMode.scaleAspectFit)
	}
	
	static func loadJson(resourceName: String) -> [String: Any]? {
		if let path = Bundle.main.path(forResource: resourceName, ofType: "json") {
			do {
				let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
				let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
				if let jsonResult = jsonResult as? [String: Any] {
					return jsonResult
				}
			} catch {
				print("Error while decoding json resource \(resourceName).")
			}
		}
		return nil
	}
	
	static func urlGetJSON(url: URL, completionHandler: @escaping ([String: Any])->()) {
		URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
			
			guard error == nil else {
				print(error!.localizedDescription)
				return
			}
			
			guard let data = data else {
				print("Received empty data object for http get request!")
				return
			}
			
			guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
				print("Received error code from server for http get request!")
				return
			}
			
			if response.mimeType == "application/json" {
				do {
					let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
					DispatchQueue.main.async {
						completionHandler(json)
					}
				} catch {
					print(error.localizedDescription)
				}
			}
		}).resume()
	}
	
	static func urlGetImage(url: URL, completionHandler: @escaping (UIImage)->(), errorHandler: @escaping (Error)->()) {
		URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
			
			guard error == nil else {
				print(error!.localizedDescription)
				errorHandler(error!)
				return
			}
			
			guard let data = data else {
				print("Received empty data object for http get request!")
				return
			}
			
			guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
				print("Received error code from server for http get request!")
				return
			}
			
			if let image = UIImage(data: data) {
				completionHandler(image)
			}
		}).resume()
	}
	
	static func requestAppStoreRating() {
		let count = Settings.shared.openingCount
		switch count {
			case 4, 25:
				if #available(iOS 10.3, *) {
					SKStoreReviewController.requestReview()
				}
			case _ where count % 50 == 0 :
				if #available(iOS 10.3, *) {
					SKStoreReviewController.requestReview()
				}
			default:
				break
		}
	}
	
}
