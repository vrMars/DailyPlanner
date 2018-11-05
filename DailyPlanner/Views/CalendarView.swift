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
        calendarView.calendarDataSource = self
        calendarView.calendarDelegate = self
        calendarView.register(UINib(nibName: "CalendarCellView", bundle: nil), forCellWithReuseIdentifier: "CalendarCellView")
        
        
        //configure calendar view
        calendarView.backgroundColor = UIColor.white
        calendarView.minimumLineSpacing = 0
        calendarView.minimumInteritemSpacing = 0
        calendarView.scrollDirection = .horizontal
        calendarView.scrollingMode = .stopAtEachCalendarFrame
        
        self.backgroundColor = .green

        self.addSubview(calendarView)
        self.addSubview(todaysDate)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

extension CalendarView: JTAppleCalendarViewDataSource, JTAppleCalendarViewDelegate {
    func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        let myCustomCell = cell as! CalendarCellView
        calendarDiff(myCustomCell: myCustomCell, date: date, cellState: cellState)
    }
    
    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        let myCustomCell = calendar.dequeueReusableCell(withReuseIdentifier: "CalendarCellView", for: indexPath) as! CalendarCellView
        calendarDiff(myCustomCell: myCustomCell, date: date, cellState: cellState)
        return myCustomCell
    }
    
    /// Handles calendar cell configurations.
    private func calendarDiff(myCustomCell: CalendarCellView, date: Date, cellState: CellState) {
        let isToday: Bool = Calendar.current.compare(date, to: Date(), toGranularity: .day) == .orderedSame
        // Setup Cell text
        myCustomCell.dayLabel.text = cellState.text
        
        // Setup text color
        if cellState.dateBelongsTo == .thisMonth {
            if isToday {
                myCustomCell.dayLabel.textColor = .red
            }
            else {
                myCustomCell.dayLabel.textColor = UIColor.black
            }
        } else {
            myCustomCell.dayLabel.textColor = UIColor.gray
        }
    }
    
    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MM dd"

        let startDate = formatter.date(from: "2018 11 01")!
        let endDate = formatter.date(from: "2019 01 01")!
        let parameters = ConfigurationParameters(startDate: startDate,
                                                 endDate: endDate,
                                                 numberOfRows: 6, // Only 1, 2, 3, & 6 are allowed
            calendar: Calendar.current,
            generateInDates: .forAllMonths,
            generateOutDates: .tillEndOfRow,
            firstDayOfWeek: .sunday)
        return parameters
    }
}
