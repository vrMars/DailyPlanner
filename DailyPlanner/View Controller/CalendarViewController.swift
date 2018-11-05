//
//  ViewController.swift
//  DailyPlanner
//
//  Created by Neelaksh Bhatia on 2018-11-04.
//  Copyright © 2018 Neelaksh Bhatia. All rights reserved.
//

import UIKit

class CalendarViewController: UIViewController, UIGestureRecognizerDelegate {
    
    var cgView: StrokeCGView!
    
    var pencilStrokeRecognizer: StrokeGestureRecognizer!
    
    var clearButton: UIButton!
    
    var configurations = [() -> ()]()
    
    var strokeCollection = StrokeCollection()
    var containerView: UIView!
    var canvasContainerView: CanvasContainerView!
    var calendarView: CalendarView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let bounds = view.bounds
        let screenBounds = UIScreen.main.bounds
        let maxScreenDimension = max(screenBounds.width, screenBounds.height)
        
        let flexibleDimensions: UIView.AutoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        
        let containerView = UIView(frame: bounds)
        view.addSubview(containerView)
        self.containerView = containerView
        
        let calendarView = CalendarView(frame: bounds)
        self.calendarView = calendarView
        calendarView.autoresizingMask = flexibleDimensions
        containerView.addSubview(calendarView)

        
        // sets drawable area dimensions
        let cgView = StrokeCGView(frame: CGRect(origin: .zero, size: CGSize(width: maxScreenDimension, height:maxScreenDimension)))
        cgView.autoresizingMask = flexibleDimensions
        self.cgView = cgView
        
        view.backgroundColor = UIColor.white
        
        let canvasContainerView = CanvasContainerView(canvasSize: cgView.frame.size)
        canvasContainerView.documentView = cgView
        self.canvasContainerView = canvasContainerView
        calendarView.addSubview(canvasContainerView)
        containerView.backgroundColor = canvasContainerView.backgroundColor
      //  scrollView.panGestureRecognizer.allowedTouchTypes = [UITouch.TouchType.direct.rawValue as NSNumber]
     //   scrollView.pinchGestureRecognizer?.allowedTouchTypes = [UITouch.TouchType.direct.rawValue as NSNumber]
        
        let pencilStrokeRecognizer = StrokeGestureRecognizer(target: self, action: #selector(strokeUpdated(_:)))
        pencilStrokeRecognizer.delegate = self
        pencilStrokeRecognizer.cancelsTouchesInView = false
        containerView.addGestureRecognizer(pencilStrokeRecognizer)
        pencilStrokeRecognizer.coordinateSpaceView = cgView
        pencilStrokeRecognizer.isForPencil = true
        self.pencilStrokeRecognizer = pencilStrokeRecognizer
        
        setupConfigurations()

        clearButton = addButton(title: "clear", action: #selector(clearButtonAction(_:)) )
        
        setupPencilUI()
    }
    
    // MARK: View setup helpers.
    var buttons = [UIButton]()
    func addButton(title: String, action: Selector) -> UIButton {
        let bounds = view.bounds
        let button = UIButton(type: .custom)
        let maxX: CGFloat
        if let lastButton = buttons.last {
            maxX = lastButton.frame.minX
        } else {
            maxX = bounds.maxX
        }
        button.setTitleColor(UIColor.orange, for: [])
        button.setTitleColor(UIColor.lightGray, for: .highlighted)
        button.setTitle(title, for: [])
        button.sizeToFit()
        button.frame = button.frame.insetBy(dx: -20.0, dy: -4.0)
        button.frame.origin = CGPoint(x: maxX - button.frame.width - 5.0, y: bounds.minY - 5.0)
        button.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        button.addTarget(self, action: action, for: .touchUpInside)
        let buttonLayer = button.layer
        buttonLayer.cornerRadius = 5.0
        button.backgroundColor = UIColor(white: 1.0, alpha: 0.4)
        view.addSubview(button)
        buttons.append(button)
        return button
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func setupConfigurations() {
        configurations = [
            { self.cgView.displayOptions = .ink }
        ]
        configurations.first?()
    }
    
    func toggleConfiguration(_ sender: UIButton) {
        if let index = Int(sender.titleLabel!.text!) {
            let nextIndex = (index + 1) % configurations.count
            configurations[nextIndex]()
            sender.setTitle(String(nextIndex), for: [])
        }
    }
    
    func receivedAllUpdatesForStroke(_ stroke: Stroke) {
        cgView.setNeedsDisplay(for: stroke)
        stroke.clearUpdateInfo()
    }
    
    @objc func clearButtonAction(_ sender: AnyObject) {
        self.strokeCollection = StrokeCollection()
        cgView.strokeCollection = self.strokeCollection
    }
    
    @objc func strokeUpdated(_ strokeGesture: StrokeGestureRecognizer) {
        
        if strokeGesture === pencilStrokeRecognizer {
            lastSeenPencilInteraction = Date.timeIntervalSinceReferenceDate
        }
        
        var stroke: Stroke?
        if strokeGesture.state != .cancelled {
            stroke = strokeGesture.stroke
            if strokeGesture.state == .began ||
                (strokeGesture.state == .ended && strokeCollection.activeStroke == nil) {
                strokeCollection.activeStroke = stroke
            }
        } else {
            strokeCollection.activeStroke = nil
        }
        
        if let stroke = stroke {
            if strokeGesture.state == .ended {
                if strokeGesture === pencilStrokeRecognizer {
                    // Make sure we get the final stroke update if needed.
                    stroke.receivedAllNeededUpdatesBlock = { [weak self] in
                        self?.receivedAllUpdatesForStroke(stroke)
                    }
                }
                strokeCollection.takeActiveStroke()
            }
        }
        
        cgView.strokeCollection = strokeCollection
    }
    
    
    // MARK: Pencil Recognition and UI Adjustments
    /*
     Since usage of the Apple Pencil can be very temporary, the best way to
     actually check for it being in use is to remember the last interaction.
     Also make sure to provide an escape hatch if you modify your UI for
     times when the pencil is in use vs. not.
     */
    
    // Timeout the pencil mode if no pencil has been seen for 5 minutes and the app is brought back in foreground.
    let pencilResetInterval = TimeInterval(60.0 * 5)
    
    var lastSeenPencilInteraction: TimeInterval? {
        didSet {
            if lastSeenPencilInteraction != nil && !pencilMode {
                pencilMode = true
            }
        }
    }
    
    private func setupPencilUI() {
        self.pencilMode = true
        
        notificationObservers.append(
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: UIApplication.shared, queue: nil)
            { [unowned self](_) in
                if self.pencilMode &&
                    (self.lastSeenPencilInteraction == nil ||
                        Date.timeIntervalSinceReferenceDate - self.lastSeenPencilInteraction! > self.pencilResetInterval) {
                    self.stopPencilButtonAction(nil)
                }
            }
        )
    }
    
    var notificationObservers = [NSObjectProtocol]()
    
    deinit {
        let defaultCenter = NotificationCenter.default
        for closure in notificationObservers {
            defaultCenter.removeObserver(closure)
        }
    }
    
    var pencilMode = false
    
    @objc func stopPencilButtonAction(_ sender: AnyObject?) {
        lastSeenPencilInteraction = nil
        pencilMode = false
    }
    
    // Since our gesture recognizer is beginning immediately, we do the hit test ambiguation here
    // instead of adding failure requirements to the gesture for minimizing the delay
    // to the first action sent and therefore the first lines drawn.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        for button in buttons {
            if button.hitTest(touch.location(in:clearButton), with: nil) != nil {
                return false
            }
        }
        
        return true
    }
    
    // We want the pencil to recognize simultaniously with all others.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === pencilStrokeRecognizer {
            return true
        }
        return false
    }
    
    
}

extension CalendarViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.calendarView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        var desiredScale = self.traitCollection.displayScale
        let existingScale = cgView.contentScaleFactor
        
        if scale >= 2.0 {
            desiredScale *= 2.0
        }
        
        if abs(desiredScale - existingScale) > 0.00001 {
            cgView.contentScaleFactor = desiredScale
            cgView.setNeedsDisplay()
        }
    }
}

