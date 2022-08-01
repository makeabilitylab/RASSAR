//
//  Situation.swift
//  RetroAccess App
//
//  Created by Xia Su on 7/20/22.
//

import Foundation

class Situation{
    var name:String
    var community:[String]
    var keywords:[String]
    var dimension:ObjectDimension?
    var relativePosition:RelativePosition?
    var existence:Bool?
    var type:Int
    
    public init(name:String,json:Any!){
        //Here json is at the situation list item level
        if let dic=json as? [String:Any]{
            self.name=name
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
        //Use the read info to classify this situation. TODO: more to be added
        if dimension != nil && existence == nil && relativePosition == nil{
            type=1
        }
        else{
            type=0
        }
    }
    public func search(replicator:RoomObjectReplicator)->[AccessibilityIssue]{
        //TODO: Search for this situation within this replicator
        var issuesFound:[AccessibilityIssue]=[AccessibilityIssue]()
        //Currently only the furniture dimension issues are retrieved.
        //When there's multiple keywords, iterate throught them and search one by one
        switch type{
        case 1:
            issuesFound+=retrieveDimensionalIssue(replicator: replicator)
        
        default:
            print("Non-implemented situation")
        
        }
        
        return issuesFound
    }
    public func retrieveDimensionalIssue(replicator:RoomObjectReplicator)->[AccessibilityIssue]{
        //This func only search for objects not fulfilling required dimension
        var issuesFound:[AccessibilityIssue]=[AccessibilityIssue]()
        for keyword in keywords{
            let retrieveResults=replicator.retrieveObjectWithKeyword(keyword: keyword)
            if retrieveResults.foundDetectedObjects.count>0{
                for obj in retrieveResults.foundDetectedObjects{
                    if compareValues(target: obj.getDimension(measurement:self.dimension!.measurement), comparison: self.dimension!.comparison, values: self.dimension!.value)==false{
                        //False means against the rubric, need to be reported
                        let issue=AccessibilityIssue(time: Date.now,identifier:obj.identifier,transform: obj.transform,
                                                     type: AccessibilityIssueType.ObjectDimension, description: "", rubric: self)
                        issue.setSourceODObject(source: obj)
                        issuesFound.append(issue)
                    }
                }
            }
            else if retrieveResults.foundRoomplanObjects.count>0{
                for obj in retrieveResults.foundRoomplanObjects{
                    if compareValues(target: obj.getDimension(measurement:self.dimension!.measurement), comparison: self.dimension!.comparison, values: self.dimension!.value)==false{
                        let issue=AccessibilityIssue(time: Date.now,identifier:obj.identifier,transform: obj.transform,
                                                     type: AccessibilityIssueType.ObjectDimension, description: "", rubric: self)
                        issue.setSourceRPObject(source: obj)
                        issuesFound.append(issue)
                    }
                }
            }
            else if retrieveResults.foundRoomplanSurfaces.count>0{
                for obj in retrieveResults.foundRoomplanSurfaces{
                    if compareValues(target: obj.getDimension(measurement:self.dimension!.measurement), comparison: self.dimension!.comparison, values: self.dimension!.value)==false{
                        let issue=AccessibilityIssue(time: Date.now,identifier:obj.identifier,transform: obj.transform,
                                                     type: AccessibilityIssueType.ObjectDimension, description: "", rubric: self)
                        issue.setSourceRPSurface(source: obj)
                        issuesFound.append(issue)
                    }
                }
            }
            else{
                print("Failed to find any object with this keyword: "+keyword)
            }
        }
        return issuesFound
    }
    public func compareValues(target:Double,comparison:String,values:[Int])->Bool{
        switch comparison{
        case "GreaterEqual":
            if target>=Double(values[0]){
                return true
            }
            return false
        case "LessEqual":
            if target<=Double(values[0]){
                return true
            }
            return false
        case "Between":
            if target>=Double(values[0]) && target<=Double(values[1]){
                return true
            }
            return false
        default:
            fatalError("Unexpected comparisoon type")
        }
    }
}

struct ObjectDimension{
    public var measurement:String
    public var comparison:String
    public var value:[Int]
    init(json:Any){
        let dic=json as! [String:Any]
        measurement=dic["Measurement"] as! String
        comparison=dic["Comparison"] as! String
        value=dic["Value"] as! [Int] //TODO: check if this transform is valid
    }
}

struct RelativePosition{
    public var objectCategory:[String]
    public var relation:String
    public var dimension:[Int]
    init(json:Any){
        let dic=json as! [String:Any]
        objectCategory=dic["ObjectCategory"] as! [String]
        relation=dic["Relation"] as! String
        if let dim=dic["Dimension"] as? [Int] //TODO: check if this transform is valid
        {
            dimension=dim
        }
        else{
            dimension=[Int]()
        }
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


enum Relation{
    //TODO: make sure these are all relations needed
    case upon,under,near
}
