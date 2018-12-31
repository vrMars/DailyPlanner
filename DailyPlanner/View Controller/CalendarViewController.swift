//
//  ViewController.swift
//  DailyPlanner
//
//  Created by Neelaksh Bhatia on 2018-11-04.
//  Copyright © 2018 Neelaksh Bhatia. All rights reserved.
//

import UIKit
import FSCalendar
import SnapKit

class CalendarViewController: UIViewController {

    var calendarView: FSCalendar!
    var canvasVC: CanvasViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let calendarView = FSCalendar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))
        self.calendarView = calendarView
        calendarView.dataSource = self
        calendarView.delegate = self


        view.backgroundColor = UIColor.white
        view.addSubview(calendarView)

        configureCalendarApperance(calendarView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

private func configureCalendarApperance(_ calendarView: FSCalendar) {
    // calendar gestures
    let scopeGesture = UIPanGestureRecognizer(target: calendarView, action: #selector(calendarView.handleScopeGesture(_:)));
    calendarView.addGestureRecognizer(scopeGesture)

    calendarView.scope = .week

    calendarView.clipsToBounds = false

}

extension CalendarViewController: FSCalendarDataSource, FSCalendarDelegate {
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        self.calendarView.snp.updateConstraints { (make) in
            make.height.equalTo(bounds.height)
            make.top.left.right.equalToSuperview()
        }
    }

    // FSCalendarDataSource
    func calendar(calendar: FSCalendar!, hasEventForDate date: NSDate!) -> Bool {
        return true
    }

    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {

        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return 0 }
        let fileURL = documentsDirectory.appendingPathComponent(date.description(with: .current))
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return 1
        }
        return 0
    }

    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        if self.canvasVC != nil {
            self.canvasVC?.removeFromParent()
            self.canvasVC?.view.removeFromSuperview()
            self.canvasVC = nil
        }
        let canvasVC = CanvasViewController()
        self.canvasVC = canvasVC
        canvasVC.selectedDate = date.description(with: .current)
        // ** DECODER **
        canvasVC.cachedImage = loadImageFromDiskWith(fileName: date.description(with: .current))
        canvasVC.calendarView = calendar
        self.addChild(canvasVC)
        view.addSubview(canvasVC.view)
        canvasVC.view.snp.makeConstraints { make in
            make.top.equalTo(calendarView.snp.bottom)
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
        }
        canvasVC.didMove(toParent: self)

        calendarView.setScope(FSCalendarScope.week, animated: true)
    }

    func loadImageFromDiskWith(fileName: String) -> UIImage? {

        let documentDirectory = FileManager.SearchPathDirectory.documentDirectory

        let userDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(documentDirectory, userDomainMask, true)

        if let dirPath = paths.first {
            let imageUrl = URL(fileURLWithPath: dirPath).appendingPathComponent(fileName)
            let image = UIImage(contentsOfFile: imageUrl.path)
            return image

        }

        return nil
    }
}
