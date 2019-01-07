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
    var isCalendarVisible: Bool = true
    var oldCalendarHeight: CGFloat = 0
    var toolBar: ToolBar!
    var canvasVC: CanvasViewController?
    var currentTool: SketchToolType!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let calendarView = FSCalendar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))
        self.calendarView = calendarView
        calendarView.dataSource = self
        calendarView.delegate = self
        calendarView.select(calendarView.today)

        let toolBar = ToolBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 76))
        self.toolBar = toolBar
        toolBar.delegate = self
        
        view.backgroundColor = UIColor(red: 0.9569, green: 0.9569, blue: 0.9569, alpha: 1.0)
        view.addSubview(calendarView)
        view.addSubview(toolBar)

        selectToday()
        configureCalendarApperance(calendarView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
}

private func configureCalendarApperance(_ calendarView: FSCalendar) {
    // calendar gestures
    let scopeGesture = UIPanGestureRecognizer(target: calendarView, action: #selector(calendarView.handleScopeGesture(_:)));
    calendarView.addGestureRecognizer(scopeGesture)

    calendarView.scope = .week

    // Calendar
    calendarView.clipsToBounds = false
    calendarView.backgroundColor = UIColor(red: 0.9569, green: 0.9569, blue: 0.9569, alpha: 1.0)

    // Dates
    calendarView.appearance.eventDefaultColor = UIColor(red: 0.051, green: 0.6471, blue: 0, alpha: 1.0)
    calendarView.appearance.titleFont = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: UIFont.Weight.light)

    // Day of the week
    calendarView.appearance.weekdayFont = UIFont.systemFont(ofSize: 28, weight: UIFont.Weight.medium)
    calendarView.appearance.weekdayTextColor = .black

    // Header
    calendarView.appearance.headerTitleFont = UIFont.systemFont(ofSize: 36, weight: UIFont.Weight.heavy)
    calendarView.appearance.headerTitleColor = .black

}

extension CalendarViewController: ToolBarDelegate {
    func toggleCalendar() {
        isCalendarVisible = !isCalendarVisible
        UIView.animate(withDuration: 0.5, animations: {
            if (self.isCalendarVisible) {
                self.calendarView.isHidden = false
            }
            self.calendarView.snp.remakeConstraints { (make) in
                make.height.equalTo(self.isCalendarVisible ? self.oldCalendarHeight : 10)
                make.top.left.right.equalToSuperview()
            }
            self.calendarView.superview?.layoutIfNeeded()
        }, completion: { (completed) in
                self.calendarView.isHidden = !self.isCalendarVisible
        })

    }

    func selectPen() {
        self.canvasVC?.sketchView.drawTool = .pen
    }

    func selectFont() {
        let sliderVC = SliderPopOverViewController()
        sliderVC.modalPresentationStyle = .popover
        sliderVC.delegate = self
        let popOverVC = sliderVC.popoverPresentationController
        popOverVC?.delegate = self
        popOverVC?.sourceView = self.toolBar.fontSizeTool
        popOverVC?.sourceRect = CGRect(x: self.toolBar.fontSizeTool.bounds.midX, y: self.toolBar.fontSizeTool.bounds.maxY, width: 0, height: 0)
        popOverVC?.permittedArrowDirections = .up
        sliderVC.preferredContentSize = CGSize(width: 250, height: 100)
        self.present(sliderVC, animated: true)
    }

    func selectEraser() {
        self.canvasVC?.sketchView.drawTool = .eraser
    }

    func selectClear() {
        let alert = UIAlertController(title: "Warning", message: "Are you sure you want to clear this page?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive) { handler in
            self.canvasVC?.sketchView.clear()
            self.canvasVC?.eraseDrawnData()
            self.calendarView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true) {
            print("cleared")
        }
    }
}

extension CalendarViewController: UIPopoverPresentationControllerDelegate, SliderPopOverDelegate {
    func setFont(font: CGFloat) {
        self.canvasVC?.sketchView.lineWidth = font
    }
}

extension CalendarViewController: FSCalendarDataSource, FSCalendarDelegate {
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        self.calendarView.snp.updateConstraints { (make) in
            self.oldCalendarHeight = bounds.height
            make.height.equalTo(bounds.height)
            make.top.left.right.equalToSuperview()
        }
        if bounds.height > 500 {
            self.toolBar.snp.updateConstraints { make in
                make.height.equalTo(0)
                make.top.equalTo(calendarView.snp.bottom)
                make.left.right.equalToSuperview()
            }
        }
        else {
            self.toolBar.snp.updateConstraints { make in
                make.height.equalTo(76)
                make.top.equalTo(calendarView.snp.bottom)
                make.left.right.equalToSuperview()
            }
        }

    }

    // FSCalendarDataSource
    func calendar(calendar: FSCalendar!, hasEventForDate date: NSDate!) -> Bool {
        return true
    }

    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        if let data = UserDefaults.standard.object(forKey: date.description(with: .current)) as? Data {
            if let paths = NSKeyedUnarchiver.unarchiveObject(with: data) as? [UIBezierPath], !paths.isEmpty {
                return 1
            }
        }
        return 0
    }

    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        handleSelection(date.description(with: .current))
    }

    func selectToday() {
        handleSelection((calendarView.today?.description(with: .current))!)
    }

    private func handleSelection(_ date: String) {
        if self.canvasVC != nil {
            self.canvasVC?.removeFromParent()
            self.canvasVC?.view.removeFromSuperview()
            self.canvasVC = nil
        }
        let canvasVC = CanvasViewController()
        self.canvasVC = canvasVC
        canvasVC.selectedDate = date
        // ** DECODER **
        if let data = UserDefaults.standard.object(forKey: date) as? Data {
            if let paths = NSKeyedUnarchiver.unarchiveObject(with: data) as? [UIBezierPath] {
                canvasVC.paths = paths
            }
        }
        canvasVC.calendarView = calendarView
        self.addChild(canvasVC)
        view.addSubview(canvasVC.view)
        view.bringSubviewToFront(self.toolBar)
        canvasVC.view.snp.makeConstraints { make in
            make.top.equalTo(toolBar.snp.bottom)
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
        }
        canvasVC.didMove(toParent: self)

        //set default starting tool
        toolBar.currentlySelectedTool = .pen
        setFont(font: (UserDefaults.standard.object(forKey: "fontSize") as! CGFloat) * 10)
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
