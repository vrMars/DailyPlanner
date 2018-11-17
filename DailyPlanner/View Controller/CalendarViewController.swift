//
//  ViewController.swift
//  DailyPlanner
//
//  Created by Neelaksh Bhatia on 2018-11-04.
//  Copyright © 2018 Neelaksh Bhatia. All rights reserved.
//

import UIKit
import JTAppleCalendar

class CalendarViewController: UIViewController, UIGestureRecognizerDelegate, CanvasViewDelegate {

    // will contain all info about drawn strokes -> recreate for selected date
    var strokes: StrokeCollection?
    var containerView: UIScrollView!
    var calendarView: CalendarView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let bounds = view.bounds
        let flexibleDimensions: UIView.AutoresizingMask = [.flexibleWidth, .flexibleHeight]
        let containerView = UIScrollView(frame: bounds)
        view.addSubview(containerView)
        self.containerView = containerView
        containerView.delegate = self
        containerView.maximumZoomScale = 3.0
        containerView.minimumZoomScale = 1.0
        
        let calendarView = CalendarView(frame: bounds)
        self.calendarView = calendarView
        calendarView.calendarView.calendarDelegate = self
        calendarView.calendarView.calendarDataSource = self
        calendarView.autoresizingMask = flexibleDimensions
        containerView.addSubview(calendarView)
        
        view.backgroundColor = UIColor.white
     
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let strokes = self.strokes else {
            return
        }
        
        print(strokes.strokes)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func updateStrokeCollection(cell: CalendarCellView, strokeCollection: StrokeCollection) {
        cell.cgView = StrokeCGView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 50, height: 50)))
        cell.cgView?.strokeCollection = strokeCollection
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

extension CalendarViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.calendarView
    }
}

