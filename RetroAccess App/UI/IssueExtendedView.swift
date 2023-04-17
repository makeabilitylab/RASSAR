//
//  IssueExtendedView.swift
//  RetroAccess App
//
//  Created by Xia Su on 4/4/23.
//

import Foundation
import UIKit
import ARKit
import RealityKit
class IssueExtendedView:UIView{
    let screenSize: CGRect = UIScreen.main.bounds
    let accessibilityIssue:AccessibilityIssue
    public init(issue:AccessibilityIssue,parentView:ARView,icon:UIImage) {
        print(screenSize)
        self.accessibilityIssue=issue
        super.init(frame: CGRect(x: 0, y: 200, width:screenSize.width, height: screenSize.height-200))
        
        //self.frame=CGRect(x: 0, y: 200, width:screenSize.width, height: screenSize.height-200)
        self.layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.91).cgColor
        self.layer.cornerRadius = 9.33
        
        //Add banner
        let banner=UIView(frame: CGRect(x: 25, y: 50, width: screenSize.width-50, height: 80))
        let iconView=UIImageView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        iconView.image=icon
        banner.addSubview(iconView)
        let titleView=UITextView(frame: CGRect(x: 120, y: 0, width: screenSize.width-170, height: 80))
        titleView.text=issue.category.rawValue
        titleView.font=UIFont.systemFont(ofSize: 32)
        titleView.textColor=UIColor(red: 0.957, green: 0.353, blue: 0.322, alpha: 1)
        titleView.backgroundColor = .clear
        banner.addSubview(titleView)
        self.addSubview(banner)
        //Add Descriptive Image
        let imageView=UIImageView(frame: CGRect(x: (screenSize.width-300)/2, y: 120, width:300, height: 300))
        switch issue.category{
        case .Exist:
            imageView.image=UIImage(named: "RiskyItemDiagram")!
        case .NonExist:
            imageView.image=UIImage(named: "AssistiveItemDiagram")!
        case .ObjectPosition:
            imageView.image=UIImage(named: "ObjectPositionDiagram")!
        case .ObjectDimension:
            imageView.image=UIImage(named: "ObjectDimensionDiagram")!
        }
        
        self.addSubview(imageView)
        //Add text
        let textView=UITextView(frame: CGRect(x: (screenSize.width-350)/2, y: 400, width:350, height: 200))
        textView.text=issue.getDetails()
        textView.font=UIFont.systemFont(ofSize: 15)
        textView.backgroundColor = .clear
        textView.textColor=UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        self.addSubview(textView)
        let button1 = UIButton(frame:CGRect(x: screenSize.width/2-85, y: screenSize.height-200-160, width: 171, height: 55))
        //button.layer.position=CGPoint(x: (screenSize.width-230)/2, y: 788)
        let shapes = UIView()
        shapes.frame = CGRect(x: 0, y: 0, width: 171, height: 55)
        shapes.clipsToBounds = true
        button1.addSubview(shapes)
        let layer1 = CALayer()
        layer1.backgroundColor = UIColor(red: 0.122, green: 0.216, blue: 0.267, alpha: 1).cgColor
        layer1.bounds = shapes.bounds
        layer1.position = shapes.center
        shapes.layer.addSublayer(layer1)
        shapes.layer.cornerRadius = 27
        button1.setTitle("Keep Issue", for: .normal)
        shapes.isUserInteractionEnabled=false
        self.addSubview(button1)
        button1.translatesAutoresizingMaskIntoConstraints = false
        //button1.widthAnchor.constraint(equalToConstant: 171).isActive = true
        //button1.heightAnchor.constraint(equalToConstant: 55).isActive = true
        button1.addTarget(self, action: #selector(didTapReturnButton), for: .touchUpInside)
        //button1.backgroundColor = .gray
        let button2 = UIButton(frame:CGRect(x: screenSize.width/2-85, y: screenSize.height-200-100, width: 171, height: 55))
        //button.layer.position=CGPoint(x: (screenSize.width-230)/2, y: 788)
        button2.setTitle("Not An Issue", for: .normal)
        button2.setTitleColor(UIColor(red: 0.122, green: 0.216, blue: 0.267, alpha: 1), for: .normal)
        //button2.backgroundColor = .red
        self.addSubview(button2)
        button2.translatesAutoresizingMaskIntoConstraints = false
        //button2.widthAnchor.constraint(equalToConstant: 171).isActive = true
        //button2.heightAnchor.constraint(equalToConstant: 55).isActive = true
        button2.addTarget(self, action: #selector(didTapCancelButton), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func didTapReturnButton(){
        //Remove this view
        self.accessibilityIssue.cancel()
        self.removeFromSuperview()
    }
    @IBAction func didTapCancelButton(){
        //Remove this view and cancel this issue
        self.accessibilityIssue.cancel()
        self.removeFromSuperview()
    }
}
