//
//  IssueLayer.swift
//  RetroAccess App
//
//  Created by Xia Su on 8/16/22.
//

import Foundation
import UIKit
import RoomPlan
import RealityKit

class CenterCATextLayer : CATextLayer {
    override func draw(in context: CGContext) {
        let height = self.bounds.size.height
        let fontSize = self.fontSize
        let yDiff = (height-fontSize)/2 - fontSize/10

        context.saveGState()
        context.translateBy(x: 0, y: yDiff)
        super.draw(in: context)
        context.restoreGState()
    }
}

public class IssueLayer:CALayer{
//This layer includes detailed information of a detected access/safety issue. It also provides botton for removing issues.
    public var issue:AccessibilityIssue
    public var pos:CGPoint
    public init(issue:AccessibilityIssue,position:CGPoint){
        self.issue=issue
        self.pos=position
        super.init()
        generateLayer()
    }
    private func generateLayer(){
        //TODO: generate a layer that include short information and icon.
        //var x=pos.x*926/1440-403.333
        //var y=pos.y*926/1440
        var x=pos.x
        var y=pos.y
        //var x=214
        //var y=463
        //self.bounds = CGRect(x: x, y: y, width:340, height: 70)
        //self.frame=CGRect(x: x, y: y, width:340, height: 70)
        self.bounds = CGRect(x: x, y: y, width:70, height: 70)
        self.position = CGPoint(x: x, y: y)
        self.name = "Issue Preview"
        //self.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.663, 0.663, 0.663, 1])
        self.cornerRadius = 7
        
        let iconLayer = CALayer()
        iconLayer.name = "Object Icon"
        let iconCategory=getIconCategoryString()
        switch iconCategory{
        case "ObjectDimensionHigh":
            iconLayer.contents = UIImage(named: "ObjectDimensionHigh")?.cgImage
        case "ObjectDimensionLow":
            iconLayer.contents = UIImage(named: "ObjectDimensionLow")?.cgImage
        case "ObjectPositionHigh":
            iconLayer.contents = UIImage(named: "ObjectPositionHigh")?.cgImage
        case "ObjectPositionLow":
            iconLayer.contents = UIImage(named: "ObjectPositionLow")?.cgImage
        case "RiskyItem":
            iconLayer.contents = UIImage(named: "RiskyItem")?.cgImage
        case "AssistiveItem":
            iconLayer.contents = UIImage(named: "AssistiveItem")?.cgImage
        default:
            iconLayer.contents = UIImage(named: "Hazard")?.cgImage
        }
        //iconLayer.contents = UIImage(named: "Furniture")?.cgImage
        iconLayer.bounds = CGRect(x: 0, y: 0, width: 50, height: 50)
        iconLayer.position = CGPoint(x:x+35, y: y+35)
        //iconLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0, 0.663, 0.663, 1])
        self.addSublayer(iconLayer)

        let textLayer = CenterCATextLayer()
        textLayer.name = "Object Label"
        //let category=issue.category.rawValue+":"+getCategoryString()
        let category=getCategoryString()
        //let category=getCategoryString(category:issue.getSource().SourceRoomplanObject!.category)
        let formattedString = NSMutableAttributedString(string:category )
        let largeFont = UIFont(name: "Helvetica", size: 20.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: category.count))
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: 185, height: 50)
        textLayer.position = CGPoint(x:x+137.5, y: y+35)
        textLayer.alignmentMode = CATextLayerAlignmentMode.center
        textLayer.contentsScale = 2.0
        //self.addSublayer(textLayer)
        
        let checkLayer = CALayer()
        checkLayer.name = "Check Box"
        checkLayer.contents = UIImage(named: "V")?.cgImage
        checkLayer.bounds = CGRect(x: 0, y: 0, width: 50, height: 50)
        checkLayer.position = CGPoint(x:x+240, y: y+35)
        //self.addSublayer(checkLayer)
        
        let xLayer = CALayer()
        xLayer.name = "X Box"
        xLayer.contents = UIImage(named: "X")?.cgImage
        xLayer.bounds = CGRect(x: 0, y: 0, width: 50, height: 50)
        xLayer.position = CGPoint(x:x+300, y: y+35)
        //self.addSublayer(xLayer)
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
        let largeFont = UIFont(name: "Helvetica", size: 18.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: details.count))
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: 400, height: 300)
        let pos=self.position
        textLayer.position = CGPoint(x:220, y: 600)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        textLayer.contentsScale = 2.0 // retina rendering
        textLayer.backgroundColor=CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0,1.0, 0.4])
        textLayer.cornerRadius=7
        textLayer.isWrapped=true
        self.addSublayer(textLayer)
        _ = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { _ in
            textLayer.removeFromSuperlayer()
        })
        return textLayer
    }
    public func getCategoryString()->String{
        let source=issue.getSource()
        if source.SourceDetectedObject != nil{
            return source.SourceDetectedObject!.detectedObjectCategory.rawValue
        }
        else if source.SourceRoomplanObject != nil {
            let category=source.SourceRoomplanObject!.category
            switch category {
            case .storage: return "Storage too high"
            case .refrigerator: return "fridge"
            case .stove: return "stove"
            case .bed: return "bed"
            case .sink:  return "sink"
    //        case .washerDryer: return SimpleMaterial(color: .systemPurple, roughness: roughness, isMetallic: false)
            case .toilet: return "toilet"
            case .bathtub: return "bathtub"
            case .oven: return "oven"
            case .dishwasher: return "dishwasher"
            case .table: return "Table too low"
            case .sofa: return "Sofa too low"
            case .chair: return "Chair too shallow"
            case .fireplace: return "fireplace"
    //        case .television: return SimpleMaterial(color: .systemGray3, roughness: roughness, isMetallic: false)
            case .stairs: return "stairs"
            @unknown default:
                return "unknown"
                //fatalError()
            }
        }
        else if source.SourceRoomplanSurface != nil{
            let category=source.SourceRoomplanSurface!.category
            switch category{
            case .door(isOpen: true): return "door"
            case .door(isOpen: false): return "door"
            default:
                return "unknown"
            }
        }
        return "NULL"
    }
    public func getIconCategoryString()->String{
        switch issue.category{
        case .ObjectDimension:
            if issue.problem == "SHORT" || issue.problem == "NARROW"{
                return "ObjectDimensionLow"
            }
            else{
                return "ObjectDimensionHigh"
            }
        case .ObjectPosition:
            if issue.problem == "LOW"{
                return "ObjectPositionLow"
            }
            else{
                return "ObjectPositionHigh"
            }
        case .Exist:
            return "RiskyItem"
        case .NonExist:
            return "AssistiveItem"
        }
        
//        let source=issue.getSource()
//        if source.SourceDetectedObject != nil{
//            let category=source.SourceDetectedObject!.detectedObjectCategory
//            if category == .Medication{
//                return "medication"
//            }
//            else if category == .Knife || category == .Scissors{
//                return "sharp"
//            }
//            else{
//                return "notice"
//            }
//        }
//        else if source.SourceRoomplanObject != nil{
//            return "furniture"
//        }
//        else if source.SourceRoomplanSurface != nil{
//            return "furniture"
//        }
//        return "null"
//        switch category {
//        case .storage: return "furniture"
//        case .refrigerator: return "furniture"
//        case .stove: return "furniture"
//        case .bed: return "furniture"
//        case .sink:  return "furniture"
////        case .washerDryer: return SimpleMaterial(color: .systemPurple, roughness: roughness, isMetallic: false)
//        case .toilet: return "furniture"
//        case .bathtub: return "furniture"
//        case .oven: return "furniture"
//        case .dishwasher: return "furniture"
//        case .table: return "furniture"
//        case .sofa: return "furniture"
//        case .chair: return "furniture"
//        case .fireplace: return "furniture"
////        case .television: return SimpleMaterial(color: .systemGray3, roughness: roughness, isMetallic: false)
//        case .stairs: return "furniture"
//        @unknown default:
//            return "unknown"
//            //fatalError()
//        }
    }
    
    @objc func pressedCheckBtn(sender: UIButton) {
        print("Pressed the Check Button!")
    }
    
    @objc func pressedXBtn(sender: UIButton) {
        print("Pressed the X Button!")
    }
    public func getExtendedView(parent:ViewController)->UIView{
        let iconCategory=getIconCategoryString()
        var icon:UIImage?=nil
        switch iconCategory{
        case "ObjectDimensionHigh":
            icon = UIImage(named: "ObjectDimensionHigh")
        case "ObjectDimensionLow":
            icon = UIImage(named: "ObjectDimensionLow")
        case "ObjectPositionHigh":
            icon = UIImage(named: "ObjectPositionHigh")
        case "ObjectPositionLow":
            icon = UIImage(named: "ObjectPositionLow")
        case "RiskyItem":
            icon = UIImage(named: "RiskyItem")
        case "AssistiveItem":
            icon = UIImage(named: "AssistiveItem")
        default:
            icon = UIImage(named: "Hazard")
        }
        return IssueExtendedView(issue: issue, parentController: parent, icon: icon!)
    }
    
}
