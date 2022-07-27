//
//  Situation.swift
//  RetroAccess App
//
//  Created by Xia Su on 7/20/22.
//

import Foundation

class Situation{
    public var index=0
    public var community:[String]
    public var keywords:[String]
    public var dimension:ObjectDimension?
    public var relativePosition:RelativePosition?
    public var existence:Bool?
    
    public init(json:Any!){
        //Here json is at the situation list item level
        if let dic=json as? [String:Any]{
            index=dic["Index"] as! Int
            community = dic["Community"] as! [String]
            keywords = dic["Keyword"] as! [String]
            if let dim=dic["Dimension"] as? [String:Any]{
                dimension=ObjectDimension(json:dim)
            }
            else{
                dimension=nil
            }
            if let pos=dic["Relativeposition"] as? [String:Any]{
                relativePosition=RelativePosition(json:pos)
            }
            else{
                relativePosition=nil
            }
            if let exist=dic["Existence"] as? Bool{
                existence=exist
            }
            else{
                existence=nil
            }
        }
        else{
            fatalError("Error occurred in reading json situations")
        }
    }
    public func search(replicator:RoomObjectReplicator)->[AccessibilityIssue]{
        //TODO: Search for this situation within this replicator
        var issuesFound:[AccessibilityIssue]=[AccessibilityIssue]()
        //When there's multiple keywords, iterate throught them and search one by one
        for keyword in keywords{
            //if(keyword in ["Maneuvering","Passing"])
        }
        return issuesFound
    }
}

struct ObjectDimension{
    public var measurement:String
    public var comparison:String
    public var value:[Int]
    init(json:Any){
        let dic=json as! [String:Any]
        measurement=dic["measurement"] as! String
        comparison=dic["Comparison"] as! String
        value=dic["Value"] as! [Int] //TODO: check if this transform is valid
    }
}

struct RelativePosition{
    public var objectCategory:[String]
    public var relation:String
    init(json:Any){
        let dic=json as! [String:Any]
        objectCategory=dic["ObjectCategory"] as! [String]
        relation=dic["Relation"] as! String
    }
}

enum Community{
    case BVI,Wheelchair,Elder,Children
}

enum Keyword{
    case ElectricCords,Medication,Rug,GrabBar,NightLight,Handrail,ChildSafetyGate,TubMat,SmokeAlarm,ElectricSocket,Telephone,Switch,Doorhandle,Vase,Knife,Scissors,WindowGuard
    case Passing,Maneuvering
}

//enum Measurement{
    //case Height,Width,PositionHeight
//}

enum Comparison{
    case GreaterEqual,LessEqual,Between
}

enum ObjectCategory{
    //Cases from object detection
    case ElectricCords,Medication,Rug,GrabBar,NightLight,Handrail,ChildSafetyGate,TubMat,SmokeAlarm,ElectricSocket,Telephone,Switch,Doorhandle,Vase,Knife,Scissors,WindowGuard
    //Cases from Roomplan API
    case bathtub,bed,chair,dishwasher,fireplace,oven,refrigerator,screen,sink,sofa,stairs,storage,stove,table,toilet,unknown,washer
}

enum Relation{
    //TODO: make sure these are all relations needed
    case upon,under,near
}
