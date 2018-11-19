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

enum Months: Int {
    case January
    case February
    case March
    case April
    case May
    case June
    case July
    case August
    case September
    case October
    case November
    case December
}

enum DayOfWeek: Int {
    case Sunday
    case Monday
    case Tuesday
    case Wednesday
    case Thursday
    case Friday
    case Saturday
}

class CalendarView: UIView {
    
    var components: DateComponents
    let visibleMonth: UILabel = UILabel()
    let weekContainer: UIView = UIView()
    let calendarView: JTAppleCalendarView = JTAppleCalendarView()
    
    override init(frame: CGRect) {
        let calendar = Calendar.current
        self.components = calendar.dateComponents([.month, .day, .year], from: Date())

        super.init(frame: frame)

        visibleMonth.text = "\(Months.init(rawValue: components.month! - 1)!)"
        visibleMonth.font = UIFont.boldSystemFont(ofSize: 36)
        visibleMonth.sizeToFit()
        
        for dayNum in 0...6 {
            let dayLabel = UILabel()
            dayLabel.text = "\(DayOfWeek.init(rawValue: dayNum)!)"
            dayLabel.font = UIFont.boldSystemFont(ofSize: 20)
            dayLabel.sizeToFit()

            weekContainer.addSubview(dayLabel)
            dayLabel.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(frame.width * CGFloat(dayNum) / 7 + 20)
            }
        }
        
        calendarView.register(UINib(nibName: "CalendarCellView", bundle: nil), forCellWithReuseIdentifier: "CalendarCellView")

        //configure calendar view
        calendarView.backgroundColor = UIColor.purple
        calendarView.minimumLineSpacing = 0
        calendarView.minimumInteritemSpacing = 0
        calendarView.isUserInteractionEnabled = true
        calendarView.scrollDirection = .vertical
        calendarView.scrollingMode = .stopAtEachCalendarFrame
        
        self.backgroundColor = .clear

        self.addSubview(calendarView)
        self.addSubview(weekContainer)
        self.addSubview(visibleMonth)
        
        configure()
    }
    
    func configure() {
        visibleMonth.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(20)
        }
        
        weekContainer.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(visibleMonth.snp.bottom).offset(20)
        }
        
        calendarView.snp.makeConstraints { (make) in
            make.top.equalTo(visibleMonth.snp.bottom).offset(50)
            make.bottom.left.right.equalToSuperview()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
