//
//  CanvasViewController.swift
//  DailyPlanner
//
//  Created by Neelaksh Bhatia on 2018-11-05.
//  Copyright © 2018 Neelaksh Bhatia. All rights reserved.
//

import UIKit
import Sketch

class CanvasViewController: UIViewController, SketchViewDelegate, UIScrollViewDelegate {
    var containerView: UIView!
    var sketchView: DrawingView!
    var backgroundImage: UIImageView!
    var scale: CGFloat = 1.0

    override func viewDidLoad() {
        super.viewDidLoad()

        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))

        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height + 300))
        self.containerView = containerView

        let sketchView = DrawingView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height + 300))
        self.sketchView = sketchView

        let paper = UIImage(named: "lined_background.png")

        let paperImageView = UIImageView(frame: sketchView.frame)
        backgroundImage = paperImageView
        paperImageView.image = paper

        view.addSubview(scrollView)

        containerView.addSubview(backgroundImage)
        containerView.addSubview(sketchView)
        scrollView.addSubview(containerView)
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 2.5
        scrollView.contentSize = CGSize(width: sketchView.frame.width, height: sketchView.frame.height)

        scrollView.panGestureRecognizer.allowedTouchTypes = [0] // only finger
        scrollView.pinchGestureRecognizer?.allowedTouchTypes = [0]
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
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
