//
//  CodeCollectionViewCell.swift
//  TodayExtension
//
//  Created by Alexander Schulz on 04.10.18.
//  Copyright © 2018 Alexander Schulz. All rights reserved.
//

import UIKit

class CodeCollectionViewCell: UICollectionViewCell {
	
	//MARK: Properties
	var code: Code! {
		didSet {
			if code.logo != nil {
				imageView.image = code.logo!
			} else {
				if let image = Utils.generateCode(value: code.value, codeType: code.type, targetSize: imageView.frame.size) {
					imageView.image = image.imageWithInsets(insets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)) ?? UIImage(named: "barcodeAddIcon")
				}
			}
			nameLabel.text = code.name
		}
	}
	
	//MARK: Outlets
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var nameLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		imageView.backgroundColor = .white
		imageView.layer.cornerRadius = 15
//		imageView.layer.shadowColor = UIColor.lightGray.cgColor
//		imageView.layer.shadowOffset = CGSize(width: 0, height: 3)
//		imageView.layer.shadowOpacity = 1.0
		imageView.clipsToBounds = true
	}
	
}
