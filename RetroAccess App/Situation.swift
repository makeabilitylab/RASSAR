//
//  Situation.swift
//  RetroAccess App
//
//  Created by Xia Su on 7/20/22.
//

import Foundation

public class Situation{
    var index:Int
    var community:[String]
    var dependency:[String]?
    var keyword:String
    var keywordMainPart:String
    var keywordFollowingPart:String?
    var requirement:String
    var dimension:ObjectDimension?
    var relativePosition:RelativePosition?
    var existence:Bool?
    
    public init(index:Int,keyword:String,requirement:String,json:Any!){
        //Here json is at the situation list item level
        if let dic=json as? [String:Any]{
            self.index=index
            self.requirement=requirement
            self.community = dic["Community"] as! [String]
            self.keyword = keyword //TODO: parse keyword by separating with - and _. A - separation means there are parts of item being addressed. A _ separation is used to avoid same keywords so content after _ can be ignored
            if keyword.contains("-"){
                let comps=self.keyword.split(separator: "-")
                keywordMainPart=String(comps[0])
                keywordFollowingPart=String(comps[1])
            }
            else{
                keywordMainPart=keyword
                keywordFollowingPart=nil
            }
            if let dependency=dic["Dependency"] as? [String]{
                self.dependency=dependency
            }
            else{
                self.dependency=nil
            }
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
        //Currently only the furniture dimension issues are retrieved.
        //When there's multiple keywords, iterate throught them and search one by one
        switch requirement{
        case "Height":
            issuesFound+=retrieveDimensionalIssue(replicator: replicator,measurement: "Height")
        case "Width":
            issuesFound+=retrieveDimensionalIssue(replicator: replicator,measurement: "Width")
        case "Depth":
            issuesFound+=retrieveDimensionalIssue(replicator: replicator,measurement: "Depth")
        case "Radius":
            issuesFound+=retrieveDimensionalIssue(replicator: replicator,measurement: "Radius")
        case "Existence":
            issuesFound+=retrieveExistenceIssue(replicator: replicator)
        case "DangerousItemDetection":
            issuesFound+=retrieveDangerousItemIssue(replicator: replicator)
        case "SharpEdges":
            //TODO: Implement sharp edges
            print("Haven't implemented sharp edge detection yet")
        default:
            print("Non-implemented situation")
        
        }
        
        return issuesFound
    }
    public func retrieveDimensionalIssue(replicator:RoomObjectReplicator,measurement:String)->[AccessibilityIssue]{
        //This func only search for objects not fulfilling required dimension
        var issuesFound:[AccessibilityIssue]=[AccessibilityIssue]()
        let retrieveResults=replicator.retrieveObjectWithKeyword(keyword: keyword)
        if retrieveResults.foundDetectedObjects.count>0{
            for obj in retrieveResults.foundDetectedObjects{
                if compareValues(target: obj.getDimension(measurement:measurement), comparison: self.dimension!.comparison!, values: self.dimension!.value!)==false{
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
                if compareValues(target: obj.getDimension(measurement:measurement), comparison: self.dimension!.comparison!, values: self.dimension!.value!)==false{
                    let issue=AccessibilityIssue(time: Date.now,identifier:obj.identifier,transform: obj.transform,
                                                 type: AccessibilityIssueType.ObjectDimension, description: "", rubric: self)
                    issue.setSourceRPObject(source: obj)
                    issuesFound.append(issue)
                }
            }
        }
        else if retrieveResults.foundRoomplanSurfaces.count>0{
            for obj in retrieveResults.foundRoomplanSurfaces{
                if compareValues(target: obj.getDimension(measurement:measurement), comparison: self.dimension!.comparison!, values: self.dimension!.value!)==false{
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
        
        return issuesFound
    }
    public func retrieveExistenceIssue(replicator:RoomObjectReplicator)->[AccessibilityIssue]{
        var issuesFound:[AccessibilityIssue]=[AccessibilityIssue]()
        //Use the requrements to find required cases in replicator.
        //First find all dependency items
        if dependency != nil{
            for depend in dependency!{
                let retrieveResults=replicator.retrieveObjectWithKeyword(keyword: depend)
            }
        }
        else{
            //No dependency, so all keyword items are issues
            
        }
        return issuesFound
    }
    public func retrieveDangerousItemIssue(replicator:RoomObjectReplicator)->[AccessibilityIssue]{
        //Directly find all keyword items
        let retrieveResults=replicator.retrieveObjectWithKeyword(keyword: keywordMainPart)
        var issuesFound:[AccessibilityIssue]=[AccessibilityIssue]()
        if retrieveResults.foundDetectedObjects.count>0{
            for obj in retrieveResults.foundDetectedObjects{
                let issue=AccessibilityIssue(time: Date.now,identifier:obj.identifier,transform: obj.transform,
                                             type: AccessibilityIssueType.ObjectDimension, description: "", rubric: self)
                issue.setSourceODObject(source: obj)
                issuesFound.append(issue)
                
            }
        }
        else if retrieveResults.foundRoomplanObjects.count>0{
            for obj in retrieveResults.foundRoomplanObjects{
                let issue=AccessibilityIssue(time: Date.now,identifier:obj.identifier,transform: obj.transform,
                                             type: AccessibilityIssueType.ObjectDimension, description: "", rubric: self)
                issue.setSourceRPObject(source: obj)
                issuesFound.append(issue)
                
            }
        }
        else if retrieveResults.foundRoomplanSurfaces.count>0{
            for obj in retrieveResults.foundRoomplanSurfaces{
                let issue=AccessibilityIssue(time: Date.now,identifier:obj.identifier,transform: obj.transform,
                                             type: AccessibilityIssueType.ObjectDimension, description: "", rubric: self)
                issue.setSourceRPSurface(source: obj)
                issuesFound.append(issue)
            }
        }
        else{
            print("Failed to find any object with this keyword: "+keyword)
        }
        
        return issuesFound
    }
    public func compareValues(target:Double,comparison:String,values:[Int])->Bool{
        //TODO: conduct unit transform. From meter to inch
        switch comparison{
        case "NoLessThan":
            if target>=Double(values[0]){
                return true
            }
            return false
        case "LessThan":
            if target<=Double(values[0]){
                return true
            }
            return false
        case "Between":
            if target>=Double(values[0]) && target<=Double(values[1]){
                return true
            }
            return false
        case "Equal":
            if target<=Double(values[0])+Double(Settings.instance.dimension_tolerance) && target>=Double(values[0])-Double(Settings.instance.dimension_tolerance){
                return true
            }
            return false
        default:
            fatalError("Unexpected comparisoon type")
        }
    }
}

struct ObjectDimension{
    //public var measurement:String
    public var comparison:String?
    public var value:[Int]?
    init(json:Any){
        let dic=json as! [String:Any]
        //measurement=dic["Measurement"] as! String
        if let comp=dic["Comparison"] as? String{
            comparison=comp
        }
        else
        {
            comparison=nil
        }
        if let v=dic["Value"] as? [Int]{
            value=v
        }
        else{
            value=nil
        }
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
