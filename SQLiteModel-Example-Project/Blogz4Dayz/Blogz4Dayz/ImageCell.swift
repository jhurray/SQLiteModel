//
//  ImageCollectionViewCell.swift
//  Blogz4Dayz
//
//  Created by Jeff Hurray on 4/9/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import UIKit
import Neon

class ImageCell: UICollectionViewCell {

    let imageView = UIImageView()
    
    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.whiteColor()
    
        self.contentView.addSubview(imageView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let padding: CGFloat = 4.0
        imageView.fillSuperview(left: padding, right: padding, top: padding, bottom: padding)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
