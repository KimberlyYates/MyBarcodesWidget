

import UIKit

class PrivacyPolicyViewController: UIViewController {

	@IBOutlet weak var textView: UITextView!
	
    override func viewDidLoad() {
        super.viewDidLoad()

		if #available(iOS 11.0, *) {
			self.navigationItem.largeTitleDisplayMode = .never
		}
        
        let HtmlWebView : UIWebView = UIWebView.init(frame: self.view.bounds)
        
        //    let PrivacyfilePath = Bundle.mainBundle().pathForResource("reading", ofType: "html")
        
        let PrivacyPath = Bundle.main.path(forResource: "Barcodeprivacypolicy", ofType: "html")
        
        do {
            let htmlString = try NSString.init(contentsOfFile: PrivacyPath!, encoding: String.Encoding.utf8.rawValue)
            HtmlWebView.loadHTMLString(htmlString as String  , baseURL: NSURL.fileURL(withPath: PrivacyPath!))
            self.view.addSubview(HtmlWebView)
            
        }catch{
            
        }
//        do {
//            let at : NSAttributedString = try NSAttributedString(data: NSLocalizedString("PrivacyPolicy", comment: "").data(using: .unicode)!, options:
//                [NSAttributedString.DocumentReadingOptionKey.documentType : NSAttributedString.DocumentType.html], documentAttributes: nil);
//            textView.attributedText = at;
//        } catch {
//            textView.text = NSLocalizedString("PrivacyPolicy", comment: "");
//        }
    }
    


}
