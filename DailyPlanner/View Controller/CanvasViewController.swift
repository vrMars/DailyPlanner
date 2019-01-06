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
    var calendarView: FSCalendar!
    var sketchView: SketchView!
    var paths: [UIBezierPath]?
    var selectedDate: String!
    var scale: CGFloat = 1.0
    var saveTimer: Timer?
    var shouldSave: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))

        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height + 300))
        self.containerView = containerView

        let sketchView = SketchView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height + 150))
        self.sketchView = sketchView
        sketchView.backgroundColor = UIColor(patternImage: UIImage(named: "lined-paper")!)


        if self.paths != nil {
            sketchView.loadPaths(bezPaths: paths!)
        }

        sketchView.sketchViewDelegate = self
        view.addSubview(scrollView)

        containerView.addSubview(sketchView)
        scrollView.addSubview(containerView)
        scrollView.backgroundColor = .lightGray
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 2.5
        scrollView.contentSize = CGSize(width: sketchView.frame.width, height: sketchView.frame.height + 600)

        scrollView.panGestureRecognizer.allowedTouchTypes = [0] // only finger
        scrollView.pinchGestureRecognizer?.allowedTouchTypes = [0]
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
        return sketchView
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
        self.saveTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { (Timer) in
            DispatchQueue.main.async {
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
    }

    func saveDrawnData(path: [UIBezierPath]) {
        // encode path to user defaults
        // TODO: SAVE FONTS ALONSIDE PATH
        let encodedData = NSKeyedArchiver.archivedData(withRootObject: path)
        UserDefaults.standard.set(encodedData, forKey: self.selectedDate)
    }

    public func eraseDrawnData() {
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
