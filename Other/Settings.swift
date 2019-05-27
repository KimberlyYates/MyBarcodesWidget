
import Foundation

class Settings: NSObject, NSCoding {
	
	//MARK: Properties
	var selectedTheme: Themes
	var firstAppStart: Bool
	var hasSetLocation: Bool
	var openingCount: Int
	
	static var shared = Settings()
	
	struct PropertyKeys {
		static let selectedThemes = "selectedThemes"
		static let firstAppStart = "firstAppStart"
		static let hasSetLocation = "hasSetLocation"
		static let openingCount = "openingCount"
	}
	
	private override init() {
		selectedTheme = .light
		firstAppStart = true
		hasSetLocation = true
		openingCount = 0
		super.init()
	}
	
	func encode(with aCoder: NSCoder) {
		aCoder.encode(selectedTheme.rawValue, forKey: PropertyKeys.selectedThemes)
		aCoder.encode(firstAppStart, forKey: PropertyKeys.firstAppStart)
		aCoder.encode(hasSetLocation, forKey: PropertyKeys.hasSetLocation)
		aCoder.encode(openingCount, forKey: PropertyKeys.openingCount)
	}
	
	required init?(coder aDecoder: NSCoder) {
		guard let selectedTheme = Themes(rawValue: aDecoder.decodeInteger(forKey: PropertyKeys.selectedThemes)) else {
				fatalError("Error while decoding Settings!")
		}
		self.selectedTheme = selectedTheme
		self.firstAppStart = aDecoder.decodeBool(forKey: PropertyKeys.firstAppStart)
		self.hasSetLocation = aDecoder.decodeBool(forKey: PropertyKeys.hasSetLocation)
		self.openingCount = aDecoder.decodeInteger(forKey: PropertyKeys.openingCount)
	}
	
}
