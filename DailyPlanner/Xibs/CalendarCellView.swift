//
//  CalendarCellView.swift
//  DailyPlanner
//
//  Created by Neelaksh Bhatia on 2018-11-04.
//  Copyright © 2018 Neelaksh Bhatia. All rights reserved.
//

//DEPRECATED ***


import JTAppleCalendar

class CalendarCellView: JTAppleCell {
    @IBOutlet var dayLabel: UILabel!
    @IBOutlet var journalDot: UIImageView!
    var date: Date!
}
