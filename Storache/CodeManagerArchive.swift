
import Foundation

class CodeManagerArchive {
	
	static let CODEMANAGERDIR = "CodeManager"
	
	//MARK: TaskManager
	static func codeManagerDir() -> URL {
		guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.KimberlyYatescodesourcebarcode.app") else {//urls(for: .documentDirectory, in: .userDomainMask).first else {
			fatalError("Failed to retrieve task manager archive URL!")
		}
		return url.appendingPathComponent(CODEMANAGERDIR)
	}
	
	static func saveCodeManager() {
		NSKeyedArchiver.setClassName("CodeManager", for: CodeManager.self)
		let success = NSKeyedArchiver.archiveRootObject(CodeManager.shared, toFile: codeManagerDir().path)
		if !success {
			fatalError("Error while saving task manager!")
		}
	}
	
	static func loadCodeManager() -> CodeManager? {
		NSKeyedUnarchiver.setClass(CodeManager.self, forClassName: "CodeManager")
		return NSKeyedUnarchiver.unarchiveObject(withFile: codeManagerDir().path) as? CodeManager
	}
}
