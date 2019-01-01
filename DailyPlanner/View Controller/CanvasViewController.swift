//
//  CanvasViewController.swift
//  DailyPlanner
//
//  Created by Neelaksh Bhatia on 2018-11-05.
//  Copyright © 2018 Neelaksh Bhatia. All rights reserved.
//

import UIKit
import FSCalendar
import Floaty

class CanvasViewController: UIViewController, SketchViewDelegate, UIScrollViewDelegate {
    var containerView: UIView!
    var fab: Floaty!
    var calendarView: FSCalendar!
    var sketchView: SketchView!
    var paths: [UIBezierPath]?
    var selectedDate: String!
    var scale: CGFloat = 1.0
    var saveTimer: Timer?
    var shouldSave: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        self.fab = Floaty()
        configureFab()

        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))

        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height + 300))
        self.containerView = containerView

        let sketchView = SketchView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height + 300))
        self.sketchView = sketchView

        if self.paths != nil {
            sketchView.loadPaths(bezPaths: paths!)
        }

        sketchView.sketchViewDelegate = self

        view.addSubview(scrollView)

        containerView.addSubview(sketchView)
        scrollView.addSubview(containerView)
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 2.5
        scrollView.contentSize = CGSize(width: sketchView.frame.width, height: sketchView.frame.height)

        scrollView.panGestureRecognizer.allowedTouchTypes = [0] // only finger
        scrollView.pinchGestureRecognizer?.allowedTouchTypes = [0]

        self.view.addSubview(fab)

        let secondFab = Floaty()
        secondFab.buttonImage = UIImage(named: "pen")


        secondFab.addItem("", icon: UIImage(named: "erase")) { item in
            self.sketchView.drawTool = .eraser
            secondFab.buttonImage = UIImage(named: "erase")
        }
        secondFab.addItem("", icon: UIImage(named: "pen")) { item in
            self.sketchView.drawTool = .pen
            secondFab.buttonImage = UIImage(named: "pen")
        }
        secondFab.size = 64
        secondFab.paddingX = sketchView.frame.width - 72
        secondFab.friendlyTap = false
        secondFab.itemButtonColor = UIColor(red: 73/255.0, green: 151/255.0, blue: 241/255.0, alpha: 1)
        
        self.view.addSubview(secondFab)
    }

    func configureFab() {
        guard let fab = self.fab else { return }
        // fab action items
        fab.addItem("Clear", icon: UIImage(named: "clear")) { item in
            let alert = UIAlertController(title: "Warning", message: "Are you sure you want to clear this page?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .destructive) { handler in
                self.sketchView.loadImage(image: UIImage())
                self.eraseDrawnData()
                self.calendarView.reloadData()
            })
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            self.present(alert, animated: true) {
                fab.close()
            }
        }

        fab.openAnimationType = .slideUp


        // fab config
        fab.openAnimationType = .slideUp
        fab.buttonImage = UIImage(named: "fab-icon")
        fab.rotationDegrees = 180
        fab.size = 64
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let penPaths = self.sketchView.pathArray as? [PenTool], shouldSave else { return }
        var resArray: [UIBezierPath] = []
        for path in penPaths {
            resArray.append(path.path)
        }
        self.saveDrawnData(path: resArray)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }

    func drawView(_ view: SketchView, willBeginDrawUsingTool tool: AnyObject) {
        if tool as? NSObject != NSNull() {
            self.saveTimer?.invalidate()
        }
    }
    func drawView(_ view: SketchView, didEndDrawUsingTool tool: AnyObject) {
        if tool as? NSObject != NSNull() {
            restartTimer()
            shouldSave = true
        }
    }

    func restartTimer() {
        self.saveTimer?.invalidate()
        self.saveTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { (Timer) in
            let pathArray = self.sketchView.pathArray
            var paths: [UIBezierPath] = []
            for path in pathArray {
                guard let path = path as? PenTool else { return }
                paths.append(path.path)
            }

            print("encoded: ", paths)
            self.saveDrawnData(path: paths)
            self.calendarView.reloadData()
        }
    }

    func saveDrawnData(path: [UIBezierPath]) {
        // encode path to user defaults
        let encodedData = NSKeyedArchiver.archivedData(withRootObject: path)
        UserDefaults.standard.set(encodedData, forKey: self.selectedDate)
    }

    func eraseDrawnData() {
        UserDefaults.standard.removeObject(forKey: self.selectedDate)
    }

    @objc private func onPinch(_ gesture: UIPinchGestureRecognizer) {
        if let view = gesture.view {

            switch gesture.state {
            case .changed:
                let pinchCenter = CGPoint(x: gesture.location(in: view).x - view.bounds.midX,
                                          y: gesture.location(in: view).y - view.bounds.midY)
                let transform = view.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
                    .scaledBy(x: gesture.scale, y: gesture.scale)
                    .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
                view.transform = transform
            case .ended:
                print(gesture.scale)
                UIView.animate(withDuration: 0.2, animations: {
                    view.transform = CGAffineTransform.identity
                })
            default:
                return
            }
        }
    }
}

extension CanvasViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.type != .pencil {
            return true
        }
        return false
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
