//
//  CalendarView.swift
//  DailyPlanner
//
//  Created by Neelaksh Bhatia on 2018-11-04.
//  Copyright © 2018 Neelaksh Bhatia. All rights reserved.
//

import UIKit
import SnapKit
import JTAppleCalendar

class CalendarView: UIView {
    
    var todaysDate: UILabel = UILabel()
    var components : DateComponents
    
    let calendarView: JTAppleCalendarView = JTAppleCalendarView()
    
    override init(frame: CGRect) {
        let calendar = Calendar.current
        self.components = calendar.dateComponents([.month, .day, .year], from: Date())

        super.init(frame: frame)

        todaysDate.text = "Today is: \(components.month!) \(components.day!) \(components.year!)"
        todaysDate.sizeToFit()
        
        calendarView.frame = frame
        calendarView.register(UINib(nibName: "CalendarCellView", bundle: nil), forCellWithReuseIdentifier: "CalendarCellView")

        //configure calendar view
        calendarView.backgroundColor = UIColor.clear
        calendarView.minimumLineSpacing = 0
        calendarView.minimumInteritemSpacing = 0
        calendarView.isUserInteractionEnabled = true
        calendarView.scrollDirection = .horizontal
        calendarView.scrollingMode = .stopAtEachCalendarFrame
        
        self.backgroundColor = .clear

        self.addSubview(calendarView)
        self.addSubview(todaysDate)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
