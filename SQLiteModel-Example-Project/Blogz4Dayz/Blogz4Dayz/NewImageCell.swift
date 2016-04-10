//
//  NewImageCell.swift
//  Blogz4Dayz
//
//  Created by Jeff Hurray on 4/9/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import UIKit

class NewImageCell: UICollectionViewCell {

    let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    
        self.backgroundColor = UIColor.whiteColor()
        
        label.text = "+"
        label.font = UIFont.systemFontOfSize(64.0)
        label.textColor = color
        label.textAlignment = .Center
        
        self.contentView.addSubview(label)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let padding: CGFloat = 16.0
        label.fillSuperview(left: padding, right: padding, top: padding, bottom: padding)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
