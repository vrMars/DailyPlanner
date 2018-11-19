//
//  ViewController.swift
//  DailyPlanner
//
//  Created by Neelaksh Bhatia on 2018-11-04.
//  Copyright © 2018 Neelaksh Bhatia. All rights reserved.
//

import UIKit
import JTAppleCalendar
import SnapKit

class CalendarViewController: UIViewController, CanvasViewDelegate {

    // will contain all info about drawn strokes -> recreate for selected date
    var strokes: StrokeCollection?
    var calendarView: CalendarView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let calendarView = CalendarView(frame: view.bounds)
        self.calendarView = calendarView
        calendarView.calendarView.calendarDelegate = self
        calendarView.calendarView.calendarDataSource = self
        
        view.backgroundColor = UIColor.white
        view.addSubview(calendarView)
        
        configure()
     
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func configure() {
        calendarView.snp.makeConstraints { make in
           make.edges.equalToSuperview()
        }
    }
    
    func updateStrokeCollection(cell: CalendarCellView, strokeCollection: StrokeCollection) {
        // ** ENCODING **
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        do {
            let data = try encoder.encode(strokeCollection)
            UserDefaults.standard.set(data, forKey: cell.date.description(with: .current))
        }
        catch {
            print(error)
        }
        calendarView.calendarView.reloadData()
    }
}

extension CalendarViewController: JTAppleCalendarViewDelegate, JTAppleCalendarViewDataSource {
    func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        let myCustomCell = cell as! CalendarCellView
        configureCalendarCell(myCustomCell: myCustomCell, date: date, cellState: cellState)
    }
    
    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        let myCustomCell = calendar.dequeueReusableCell(withReuseIdentifier: "CalendarCellView", for: indexPath) as! CalendarCellView
        configureCalendarCell(myCustomCell: myCustomCell, date: date, cellState: cellState)
        return myCustomCell
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        let components = Calendar.current.dateComponents([.month, .day, .year], from: visibleDates.monthDates[0].date)
        calendarView.visibleMonth.text = "\(Months.init(rawValue: components.month! - 1)!)"
    }

    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        let canvasVC = CanvasViewController()
        canvasVC.delegate = self
        canvasVC.cell = cell as? CalendarCellView
        // ** DECODER **
        if let data = UserDefaults.standard.object(forKey: date.description(with: .current)) as? Data {
            let decoder = PropertyListDecoder()
            canvasVC.strokeCollection = try? decoder.decode(StrokeCollection.self, from: data)
        }
        self.navigationController?.pushViewController(canvasVC, animated: true)
    }
    
    /// Handles calendar cell configurations.
    private func configureCalendarCell(myCustomCell: CalendarCellView, date: Date, cellState: CellState) {
        let isToday: Bool = Calendar.current.compare(date, to: Date(), toGranularity: .day) == .orderedSame
        // Setup Cell text
        myCustomCell.dayLabel.text = cellState.text
        myCustomCell.date = date
        myCustomCell.layer.borderWidth = 1
        myCustomCell.layer.borderColor = UIColor.init(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.1).cgColor
        myCustomCell.layer.cornerRadius = 0
        
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

