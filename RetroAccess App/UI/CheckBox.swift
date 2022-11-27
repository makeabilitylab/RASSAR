//
//  CheckBox.swift
//  RetroAccess App
//
//  Created by Xia Su on 10/4/22.
//

import UIKit

class CheckBox: UIButton {
    // Images
    
    // Bool property
    var isChecked: Bool = false {
        didSet {
            if isChecked == true {
                self.layer.borderColor=UIColor.white.cgColor
                self.layer.borderWidth=4
            } else {
                self.layer.borderColor=UIColor.gray.cgColor
                self.layer.borderWidth=1
            }
        }
    }
        
    override func awakeFromNib() {
        self.addTarget(self, action:#selector(buttonClicked(sender:)), for: UIControl.Event.touchUpInside)
        self.isChecked = false
        self.layer.cornerRadius=5
        self.layer.borderColor=UIColor.gray.cgColor
        self.layer.borderWidth=1
    }
        
    @objc func buttonClicked(sender: UIButton) {
        if sender == self {
            isChecked = !isChecked
        }
    }
    public func setImageName(img_name:String){
        self.setImage(UIImage(named: img_name)! as UIImage, for: UIControl.State.normal)
    }
}
