
import Foundation
import MapKit

class LocationNotification: NSObject, NSCoding {
	
	//MARK: Properties
	var codeID: String
	var location: CLLocation
	var radius: CLLocationDistance
	var isEnabled: Bool {
		didSet {
			if isEnabled {
				LocationService.shared.registerLocalNotification(notification: self)
			} else {
				
				LocationService.shared.unregisterLocalNotification(notification: self)
			}
		}
	}
	var region: CLCircularRegion {
		get {
			let latitude = location.coordinate.latitude
			let longitude = location.coordinate.longitude
			let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
			let distance = CLLocationDistance().distance(to: radius)
			let region = CLCircularRegion(center: coordinates, radius: distance, identifier: codeID)
			region.notifyOnExit = alertType == .both || alertType == .onExit
			region.notifyOnEntry = alertType == .both || alertType == .onEntry
			return region
		}
	}
	var alertType: LocationAlertType
	
	struct PropertyKeys {
		static let codeID = "codeID"
		static let location = "location"
		static let radius = "radius"
		static let alertType = "alertType"
		static let isEnabled = "isEnabled"
	}
	
	init(codeID: String, location: CLLocation, radius: CLLocationDistance, alertType: LocationAlertType, isEnabled: Bool) {
		self.codeID = codeID
		self.location = location
		self.radius = radius
		self.alertType = alertType
		self.isEnabled = isEnabled
		
		super.init()
		
		// Not triggered by initialization of isEnabled
		LocationService.shared.registerLocalNotification(notification: self)
	}
	
	//MARK: NSCoding
	
	func encode(with aCoder: NSCoder) {
		aCoder.encode(codeID, forKey: PropertyKeys.codeID)
		aCoder.encode(location, forKey: PropertyKeys.location)
		aCoder.encode(radius, forKey: PropertyKeys.radius)
		aCoder.encode(alertType.rawValue, forKey: PropertyKeys.alertType)
		aCoder.encode(isEnabled, forKey: PropertyKeys.isEnabled)
	}
	
	required init?(coder aDecoder: NSCoder) {
		guard let id = aDecoder.decodeObject(forKey: PropertyKeys.codeID) as? String,
			let location = aDecoder.decodeObject(forKey: PropertyKeys.location) as? CLLocation,
			let radius = CLLocationDistance(exactly: aDecoder.decodeDouble(forKey: PropertyKeys.radius)),
			let alertType = LocationAlertType(rawValue: aDecoder.decodeInteger(forKey: PropertyKeys.alertType)) else {
			fatalError("Error while decoding object of class Notification")
		}
		self.codeID = id
		self.location = location
		self.radius = radius
		self.alertType = alertType
		self.isEnabled = aDecoder.decodeBool(forKey: PropertyKeys.isEnabled)
	}
	
}
