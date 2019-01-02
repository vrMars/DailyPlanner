
//
//  ToolBar.swift
//  DailyPlanner
//
//  Created by Neelaksh Bhatia on 2019-01-01.
//  Copyright © 2019 Neelaksh Bhatia. All rights reserved.
//

import UIKit
import SnapKit

protocol ToolBarDelegate {
    func toggleCalendar()
    func selectPen()
    func selectEraser()
    func selectClear()
}

class ToolBar: UIView {

    var delegate: ToolBarDelegate!

    var container: UIView!

    var toggleCalendarButton: UIButton!

    var penTool: UIButton!

    var eraserTool: UIButton!

    var clearTool: UIButton!

    override init(frame: CGRect) {
        super.init(frame: frame)


        let viewShadow = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        viewShadow.center = self.center
        viewShadow.backgroundColor = UIColor.yellow
        viewShadow.layer.shadowColor = UIColor.black.cgColor
        viewShadow.layer.shadowOpacity = 0.1
        viewShadow.layer.shadowOffset = CGSize(width: 0, height: 5)
        viewShadow.layer.shadowRadius = 3
        self.addSubview(viewShadow)

        container = UIView(frame: frame)
        container.backgroundColor =  UIColor(red: 0.9569, green: 0.9569, blue: 0.9569, alpha: 1.0)

        self.addSubview(container)

        toggleCalendarButton = UIButton(type: UIButton.ButtonType.custom)
        toggleCalendarButton.setImage(UIImage(named: "up-arrow"), for: UIControl.State.normal)
        toggleCalendarButton.addTarget(self, action: #selector(toggleCalendar(_:)), for: .touchUpInside)
        container.addSubview(toggleCalendarButton)

        penTool = UIButton(type: UIButton.ButtonType.custom)
        penTool.setImage(UIImage(named: "pen"), for: UIControl.State.normal)
        penTool.addTarget(self, action: #selector(penSelected(_:)), for: .touchUpInside)
        container.addSubview(penTool)

        eraserTool = UIButton(type: UIButton.ButtonType.custom)
        eraserTool.setImage(UIImage(named: "erase"), for: UIControl.State.normal)
        eraserTool.addTarget(self, action: #selector(eraserSelected(_:)), for: .touchUpInside)
        container.addSubview(eraserTool)

        clearTool = UIButton(type: UIButton.ButtonType.custom)
        clearTool.setImage(UIImage(named: "clear"), for: UIControl.State.normal)
        clearTool.addTarget(self, action: #selector(clearSelected(_:)), for: .touchUpInside)
        container.addSubview(clearTool)


        configure()
    }

    func configure() {
        toggleCalendarButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-5)
        }

        penTool.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(-100)
            make.top.equalTo(toggleCalendarButton.snp.top)
            make.bottom.equalTo(toggleCalendarButton.snp.bottom)
        }

        eraserTool.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(100)
            make.top.equalTo(toggleCalendarButton.snp.top)
            make.bottom.equalTo(toggleCalendarButton.snp.bottom)
        }

        clearTool.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-10)
            make.top.equalTo(toggleCalendarButton.snp.top)
            make.bottom.equalTo(toggleCalendarButton.snp.bottom)
        }
    }

    private func deselectAll() {
        penTool.setImage(UIImage(named: "pen"), for: UIControl.State.normal)
        eraserTool.setImage(UIImage(named: "erase"), for: UIControl.State.normal)
    }

    // button handlers
    @objc private func toggleCalendar(_ sender: UIButton) {
            self.delegate.toggleCalendar()
            sender.setImage(sender.image(for: .normal)?.image(withRotation: .pi), for: .normal)
    }

    @objc private func penSelected(_ sender: UIButton) {
        self.delegate.selectPen()
        deselectAll()
        penTool.setImage(UIImage(named: "pen-selected"), for: UIControl.State.normal)
        // update selected image here
    }

    @objc private func eraserSelected(_ sender: UIButton) {
        self.delegate.selectEraser()
        deselectAll()
        eraserTool.setImage(UIImage(named: "erase-selected"), for: UIControl.State.normal)
        // update selected image here
    }

    @objc private func clearSelected(_ sender: UIButton) {
        self.delegate.selectClear()
        // update selected image here
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIImage {
    func image(withRotation radians: CGFloat) -> UIImage {
        let cgImage = self.cgImage!
        let LARGEST_SIZE = CGFloat(max(self.size.width, self.size.height))
        let context = CGContext.init(data: nil, width:Int(LARGEST_SIZE), height:Int(LARGEST_SIZE), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: cgImage.colorSpace!, bitmapInfo: cgImage.bitmapInfo.rawValue)!

        var drawRect = CGRect.zero
        drawRect.size = self.size
        let drawOrigin = CGPoint(x: (LARGEST_SIZE - self.size.width) * 0.5,y: (LARGEST_SIZE - self.size.height) * 0.5)
        drawRect.origin = drawOrigin
        var tf = CGAffineTransform.identity
        tf = tf.translatedBy(x: LARGEST_SIZE * 0.5, y: LARGEST_SIZE * 0.5)
        tf = tf.rotated(by: CGFloat(radians))
        tf = tf.translatedBy(x: LARGEST_SIZE * -0.5, y: LARGEST_SIZE * -0.5)
        context.concatenate(tf)
        context.draw(cgImage, in: drawRect)
        var rotatedImage = context.makeImage()!

        drawRect = drawRect.applying(tf)

        rotatedImage = rotatedImage.cropping(to: drawRect)!
        let resultImage = UIImage(cgImage: rotatedImage)
        return resultImage


    }
}
