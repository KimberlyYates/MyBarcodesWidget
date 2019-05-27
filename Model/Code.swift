

import Foundation
import AVFoundation
import UIKit

class Code: NSObject, NSCoding {
	
	//MARK: Properties
	var name: String
	var value: String
	var id: String
	var type: AVMetadataObject.ObjectType
	var logo: UIImage?
	var displaySize: Float
	var notification: LocationNotification?
	var showValue: Bool
	
	struct PropertyKeys {
		static let name = "name"
		static let value = "value"
		static let id = "id"
		static let type = "type"
		static let logo = "logo"
		static let displaySize = "displaySize"
		static let notification = "notification"
		static let showValue = "showValue"
	}
	
	init(name: String, value: String, type: AVMetadataObject.ObjectType, logo: UIImage?) {
		self.name = name
		self.value = value
		self.id = Utils.generateID()
		self.type = type
		self.logo = logo
		self.displaySize = 0.9
		self.showValue = true
		
		super.init()
	}
	
	//MARK: NSCoding
	func encode(with aCoder: NSCoder) {
		NSKeyedArchiver.setClassName("LocationNotification", for: LocationNotification.self)
		aCoder.encode(name, forKey: PropertyKeys.name)
		aCoder.encode(value, forKey: PropertyKeys.value)
		aCoder.encode(id, forKey: PropertyKeys.id)
		aCoder.encode(type, forKey: PropertyKeys.type)
		aCoder.encode(logo, forKey: PropertyKeys.logo)
		aCoder.encode(displaySize, forKey: PropertyKeys.displaySize)
		aCoder.encode(notification, forKey: PropertyKeys.notification)
		aCoder.encode(showValue, forKey: PropertyKeys.showValue)
	}
	
	required init?(coder aDecoder: NSCoder) {
		NSKeyedUnarchiver.setClass(LocationNotification.self, forClassName: "LocationNotification")
		guard let name = aDecoder.decodeObject(forKey: PropertyKeys.name) as? String,
			let value = aDecoder.decodeObject(forKey: PropertyKeys.value) as? String,
			let id = aDecoder.decodeObject(forKey: PropertyKeys.id) as? String,
			let type = aDecoder.decodeObject(forKey: PropertyKeys.type) as? AVMetadataObject.ObjectType else {
				fatalError("Error while decoding Code object!")
		}
		self.name = name
		self.value = value
		self.id = id
		self.type = type
		self.logo = aDecoder.decodeObject(forKey: PropertyKeys.logo) as? UIImage
		self.displaySize = aDecoder.decodeFloat(forKey: PropertyKeys.displaySize)
		self.notification = aDecoder.decodeObject(forKey: PropertyKeys.notification) as? LocationNotification
		self.showValue = aDecoder.decodeBool(forKey: PropertyKeys.showValue)
		if self.displaySize == 0 {
			// error loading float
			self.displaySize = 0.9
		}
	}
	
	
}
