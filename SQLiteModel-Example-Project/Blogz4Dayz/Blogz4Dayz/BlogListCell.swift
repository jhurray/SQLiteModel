//
//  BlogListCell.swift
//  Blogz4Dayz
//
//  Created by Jeff Hurray on 4/9/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import UIKit
import Neon
import SQLiteModel

class BlogListCell: UICollectionViewCell {

    var titleLabel = UILabel()
    var monthLabel = UILabel()
    var dayLabel = UILabel()
    var timeLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        func styleLabel( inout label: UILabel, color: UIColor, size: CGFloat, numberOfLines: Int = 1) {
            label.textColor = color
            label.font = UIFont.systemFontOfSize(size)
            label.textAlignment = .Center
            label.numberOfLines = numberOfLines
            label.lineBreakMode = .ByTruncatingTail
            self.contentView.addSubview(label)
        }
        
        styleLabel(&titleLabel, color: UIColor.blackColor(), size: 14.0, numberOfLines: 2)
        styleLabel(&monthLabel, color: UIColor.blackColor(), size: 30.0)
        styleLabel(&dayLabel, color: UIColor.grayColor(), size: 48.0)
        styleLabel(&timeLabel, color: color, size: 14.0)
    }
    
    func reloadWithBlogModel(blog: BlogModel) {
        
        titleLabel.text = blog => BlogModel.Title
        
        guard let date = blog.localCreatedAt else{
            self.dayLabel.text = "?"
            self.monthLabel.text = "?"
            return
        }
        
        func dayFromDate(date: NSDate) -> String {
            let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
            let components = calendar.components(.Day, fromDate: date)
            let day = components.day
            return String(day)
        }
        
        func monthFromDate(date: NSDate) -> String {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "MMM"
            return dateFormatter.stringFromDate(date)
        }
        
        func timeFromDate(date: NSDate) -> String {
            let dateFormatter = NSDateFormatter()
            dateFormatter.timeStyle = .ShortStyle
            dateFormatter.dateStyle = .NoStyle
            return dateFormatter.stringFromDate(date)
        }
        
        monthLabel.text = monthFromDate(date)
        dayLabel.text = dayFromDate(date)
        timeLabel.text = timeFromDate(date)
        
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        monthLabel.anchorAndFillEdge(.Top, xPad: 16, yPad: 16, otherSize: 48)
        titleLabel.anchorAndFillEdge(.Bottom, xPad: 16, yPad: 8, otherSize: 40)
        timeLabel.align(.AboveCentered, relativeTo: titleLabel, padding: 8, width: monthLabel.width, height: 16)
        dayLabel.alignBetweenVertical(align: .UnderCentered, primaryView: monthLabel, secondaryView: timeLabel, padding: 8, width: monthLabel.width)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
