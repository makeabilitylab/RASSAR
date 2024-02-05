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
//Deprecated. Using IssueLayer now
    let screenSize: CGRect = UIScreen.main.bounds
    let accessibilityIssue:AccessibilityIssue
    let parent:ViewController
    public init(issue:AccessibilityIssue,parentController:ViewController,icon:UIImage) {
        //print(screenSize)
        self.accessibilityIssue=issue
        self.parent=parentController
        super.init(frame: CGRect(x: 0, y: 200, width:screenSize.width, height: screenSize.height-150))
        
        //self.frame=CGRect(x: 0, y: 200, width:screenSize.width, height: screenSize.height-200)
        self.layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.91).cgColor
        self.layer.cornerRadius = 9.33
        
        //Add banner
        let banner=UIView(frame: CGRect(x: 25, y: 20, width: screenSize.width-50, height: 60))
        let iconView=UIImageView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        iconView.image=icon
        banner.addSubview(iconView)
        let titleView=UITextView(frame: CGRect(x: 100, y: 0, width: screenSize.width-120, height: 60))
        titleView.text=issue.category.rawValue
        titleView.font=UIFont.systemFont(ofSize: 28)
        titleView.textColor=UIColor(red: 0.957, green: 0.353, blue: 0.322, alpha: 1)
        titleView.backgroundColor = .clear
        titleView.isEditable=false
        banner.addSubview(titleView)
        self.addSubview(banner)
        //Add Descriptive Image
        let imageView=UIImageView(frame: CGRect(x: (screenSize.width-250)/2, y: 80, width:250, height: 250))
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
        let textView=UITextView(frame: CGRect(x: (screenSize.width-350)/2, y: 330, width:350, height: screenSize.height-150-150-55-330-20))
        let details=issue.getDetails()
        let keywordsToBold = ["Warning", "Possible Fix","Relevant Communities"]

                // Create a mutable attributed string
                let attributedString = NSMutableAttributedString(string: details)
            attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 14), range: NSRange(location: 0, length: details.count))
                // Loop through the keywords and apply bold style to each occurrence
                for keyword in keywordsToBold {
                    let range = (details as NSString).range(of: keyword)
                    if range.location != NSNotFound {
                        attributedString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 16), range: range)
                    }
                }

                // Set the attributed string to the UITextView
                textView.attributedText = attributedString
        //textView.text=issue.getDetails()
        //textView.font=UIFont.systemFont(ofSize: 15)
        textView.backgroundColor = .clear
        textView.textColor=UIColor(red: 0.122, green: 0.216, blue: 0.267, alpha: 1)
        textView.isEditable=false
        self.addSubview(textView)
        let button1 = UIButton(frame:CGRect(x: screenSize.width/2-85, y: screenSize.height-150-150-55, width: 171, height: 55))
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
        button1.setTitle("Confirm Issue", for: .normal)
        shapes.isUserInteractionEnabled=false
        self.addSubview(button1)
        //button1.translatesAutoresizingMaskIntoConstraints = false
        //button1.widthAnchor.constraint(equalToConstant: 171).isActive = true
        //button1.heightAnchor.constraint(equalToConstant: 55).isActive = true
        button1.addTarget(self, action: #selector(didTapReturnButton), for: .touchUpInside)
        //button1.backgroundColor = .gray
        var button2 = UIButton(frame:CGRect(x: screenSize.width/2-85, y: screenSize.height-150-150, width: 171, height: 55))
        //button.layer.position=CGPoint(x: (screenSize.width-230)/2, y: 788)
        button2.setTitle("Remove Issue", for: .normal)
        button2.setTitleColor(UIColor(red: 0.122, green: 0.216, blue: 0.267, alpha: 1), for: .normal)
        //button2.backgroundColor = .red
        self.addSubview(button2)
        //button2.translatesAutoresizingMaskIntoConstraints = false
        //button2.widthAnchor.constraint(equalToConstant: 171).isActive = true
        //button2.heightAnchor.constraint(equalToConstant: 55).isActive = true
        button2.addTarget(self, action: #selector(didTapCancelButton), for: .touchUpInside)
        
        //let buttons=UIView(frame: CGRect(x: screenSize.width/2-85, y: screenSize.height-150-200, width: 171, height: 200))
        //buttons.backgroundColor=UIColor.lightGray
        //buttons.addSubview(button1)
        //buttons.addSubview(button2)
        //self.addSubview(buttons)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func didTapReturnButton(){
        //Remove this view
        //self.accessibilityIssue.cancel()
        parent.extendedViewIsOut=false
        self.removeFromSuperview()
    }
    @IBAction func didTapCancelButton(){
        //Remove this view and cancel this issue
        //print("Cancel!")
        parent.extendedViewIsOut=false
        //self.accessibilityIssue.cancel()
        parent.replicator.cancel(id:self.accessibilityIssue.identifier)
        //self.accessibilityIssue.cancel()
        //self.accessibilityIssue.cancel()
        self.removeFromSuperview()
    }
}
