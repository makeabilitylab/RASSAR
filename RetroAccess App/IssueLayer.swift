//
//  IssueLayer.swift
//  RetroAccess App
//
//  Created by Xia Su on 8/16/22.
//

import Foundation
import UIKit

public class IssueLayer:CALayer{
    private var issue:AccessibilityIssue
    public var pos:CGPoint
    public init(issue:AccessibilityIssue,position:CGPoint){
        self.issue=issue
        self.pos=position
        super.init()
        generateLayer()
    }
    private func generateLayer(){
        //TODO: generate a layer that include short information and icon.
        var x=pos.x*926/1440-403.333
        var y=pos.y*926/1440
        //var x=pos.x
        //var y=pos.y
        //var x=214
        //var y=463
        self.bounds = CGRect(x: x, y: y, width:200, height: 100)
        self.frame=CGRect(x: x, y: y, width:200, height: 100)
        self.position = CGPoint(x: x, y: y)
        self.name = "Issue Preview"
        self.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 0.2, 0.2, 0.4])
        self.cornerRadius = 7
        
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        let category=issue.category.rawValue
        let formattedString = NSMutableAttributedString(string: category)
        let largeFont = UIFont(name: "Helvetica", size: 20.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: category.count))
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: 150, height: 50)
        textLayer.position = CGPoint(x:x+100, y: y+50)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        textLayer.contentsScale = 2.0 // retina rendering
        
        self.addSublayer(textLayer)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public func getExtendedLayer()->CALayer{
        //TODO: show more details in a extended layer and return it
        let textLayer = CATextLayer()
        textLayer.name = "Extended Layer"
        let details=issue.getDetails()
        let formattedString = NSMutableAttributedString(string: details)
        let largeFont = UIFont(name: "Helvetica", size: 15.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: details.count))
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: 400, height: 300)
        let pos=self.position
        textLayer.position = CGPoint(x:pos.x, y: pos.y+150)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        textLayer.contentsScale = 2.0 // retina rendering
        textLayer.backgroundColor=CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0,1.0, 0.4])
        textLayer.cornerRadius=7
        self.addSublayer(textLayer)
        _ = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { _ in
            textLayer.removeFromSuperlayer()
        })
        return textLayer
    }
}
