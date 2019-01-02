//
//  SliderPopOverViewController.swift
//  DailyPlanner
//
//  Created by Neelaksh Bhatia on 2019-01-01.
//  Copyright © 2019 Neelaksh Bhatia. All rights reserved.
//

import UIKit
import SnapKit

protocol SliderPopOverDelegate {
    func setFont(font: CGFloat)
}

class SliderPopOverViewController: UIViewController {

    var slider: UISlider!
    var delegate: SliderPopOverDelegate!

    override func viewDidLoad() {
        super.viewDidLoad()
        slider = UISlider(frame: CGRect.zero)
        slider.value = UserDefaults.standard.float(forKey: "fontSize")
        slider.isContinuous = false
        slider.addTarget(self, action: #selector(handleSlider(_:)), for: UIControl.Event.valueChanged)
        self.view.addSubview(slider)

        configure()
    }

    func configure() {
        slider.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
        }
    }

    @objc func handleSlider(_ sender: UISlider){
        UserDefaults.standard.set(sender.value, forKey: "fontSize")
        delegate.setFont(font: CGFloat(sender.value * 10))
    }
}
