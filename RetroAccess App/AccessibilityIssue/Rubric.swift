//
//  Situation.swift
//  RetroAccess App
//
//  Created by Xia Su on 7/20/22.
//

import Foundation

public class Rubric{
    var index:Int
    var community:[String]
    var dependency:[String]
    var keyword:String
    var keywordMainPart:String
    var keywordFollowingPart:String?
    var requirement:String
    var dimension:ObjectDimension?
    var message:String?
    var relativePosition:RelativePosition?
    var existence:Bool?
    var suggestions:[String]?
    var sources:String="2010 ADA Standards for Accessible Design"
    var urls:String="https://www.ada.gov/regs2010/2010ADAStandards/2010ADAstandards.htm"
    
    public init(index:Int,keyword:String,requirement:String,json:Any!){
        //Here json is at the situation list item level
        if let dic=json as? [String:Any]{
            self.index=index
            self.requirement=requirement
            self.community = dic["Community"] as! [String]
            self.keyword = keyword //TODO: parse keyword by separating with - and _. A - separation means there are parts of item being addressed. A _ separation is used to avoid same keywords so content after _ can be ignored
            if keyword.contains("_"){
                let comps=self.keyword.split(separator: "_")
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
                self.dependency=[]
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
            if let msg=dic["Message"] as? String{
                message=msg
            }
            else{
                message=nil
            }
            if let sug=dic["Suggestions"] as? [String]{
                self.suggestions=sug
            }
            else{
                suggestions=nil
            }
        }
        else{
            fatalError("Error occurred in reading json situations")
        }
    }
    func roundFloatToOneSignificantDigit(_ number: Float) -> Float {
        let power = floor(log10(abs(number)))
        let scale = pow(10, power - 1)
        let roundedValue = round(number * scale) / scale
        return Float(roundedValue)
    }
    public func get_description()->String{
        if var msg=message{
            switch requirement{
            case "Dim_Height":
                let value=dimension!.value!
                var valueincm:[Float]=[]
                for v in value{
                    valueincm.append(roundFloatToOneSignificantDigit(Float(v)*2.54) )
                }
                msg += " \nThe ADA design guideline requires a height of \(valueincm) cm"
            case "Depth":
                let value=dimension!.value!
                var valueincm:[Float]=[]
                for v in value{
                    valueincm.append(roundFloatToOneSignificantDigit(Float(v)*2.54) )
                }
                msg += " \nThe ADA design guideline requires a depth of \(valueincm) cm"
            case "Radius":
                let value=dimension!.value!
                var valueincm:[Float]=[]
                for v in value{
                    valueincm.append(roundFloatToOneSignificantDigit(Float(v)*2.54) )
                }
                msg += " \nThe ADA design guideline requires a radius more than \(valueincm) cm"
            case "ExistenceOrNot":
                msg += ""
            case "Pos_Height":
                let value=dimension!.value!
                var valueincm:[Float]=[]
                for v in value{
                    valueincm.append(roundFloatToOneSignificantDigit(Float(v)*2.54) )
                }
                msg += " \nThe ADA design guideline requires height of \(valueincm) cm"
            default:
                print("Non-implemented situation")
            }
            if suggestions != nil{
                msg+="\nPossible Fix:"
                for s in suggestions!{
                    msg+="\n"
                    msg+=s
                }
            }
            if !community.isEmpty{
                msg+="\nRelevant Communities:\n"
                for c in community{
                    msg+=" "
                    if c == "Wheelchair"{
                        msg+="Wheelchair Users"
                    }
                    else if c == "Elder"{
                        msg+="Older Adults"
                    }
                    else if c == "BLV"{
                        msg+="Blind or Low Vision"
                    }
                    else if c == "Children"{
                        msg+="Children"
                    }
                }
            }
            return msg
        }
        return ""
    }
    public func search(replicator:RoomObjectReplicator)->[AccessibilityIssue]{
        //TODO: Search for this situation within this replicator
        var issuesFound:[AccessibilityIssue]=[AccessibilityIssue]()
        //Currently only the furniture dimension issues are retrieved.
        //When there's multiple keywords, iterate throught them and search one by one
        switch requirement{
        case "Dim_Height":
            issuesFound+=retrieveDimensionalIssue(replicator: replicator,measurement: "Height")
        case "Depth":
            issuesFound+=retrieveDimensionalIssue(replicator: replicator,measurement: "Depth")
        case "Radius":
            issuesFound+=retrieveDimensionalIssue(replicator: replicator,measurement: "Radius")
        case "ExistenceOrNot":
            issuesFound+=retrieveExistenceIssue(replicator: replicator)
        case "Pos_Height":
            issuesFound+=retrievePositionalIssue(replicator: replicator, measurement: "Height")
        default:
            print("Non-implemented situation")
        
        }
        
        return issuesFound
    }
    public func retrieveDimensionalIssue(replicator:RoomObjectReplicator,measurement:String)->[AccessibilityIssue]{
        //This func only search for objects not fulfilling required dimension
        var issuesFound:[AccessibilityIssue]=[AccessibilityIssue]()
        let retrieveResults=replicator.retrieveObjectWithKeyword(keyword: keywordMainPart)
        if retrieveResults.foundDetectedObjects.count>0{
            //This should not happen! Since detected objects don;t have dimension now.
            fatalError("Dim for OD objects not supported now")
        }
        else if retrieveResults.foundRoomplanObjects.count>0{
            for obj in retrieveResults.foundRoomplanObjects{
                let problem=compareValues(target: Float(obj.getDimension(measurement:measurement)), comparison: self.dimension!.comparison!, values: self.dimension!.value!)
                if problem.count>0{
                    let issue=AccessibilityIssue(time: Date.now,identifier:obj.identifier,transform: obj.transform,
                                                 type: AccessibilityIssueType.ObjectDimension, description: "", rubric: self,problem: problem)
                    issue.setSourceRPObject(source: obj)
                    issuesFound.append(issue)
                }
            }
        }
        else if retrieveResults.foundRoomplanSurfaces.count>0{
            //Only door for now
            for obj in retrieveResults.foundRoomplanSurfaces{
                let problem=compareValues(target: Float(obj.getDimension(measurement:measurement)), comparison: self.dimension!.comparison!, values: self.dimension!.value!)
                if problem.count>0{
                    let issue=AccessibilityIssue(time: Date.now,identifier:obj.identifier,transform: obj.transform,
                                                 type: AccessibilityIssueType.ObjectDimension, description: "", rubric: self,problem: problem)
                    issue.setSourceRPSurface(source: obj)
                    issuesFound.append(issue)
                }
            }
        }
        else{
            //print("Failed to find any object with this keyword: "+keywordMainPart)
        }
        
        return issuesFound
    }
    public func retrieveExistenceIssue(replicator:RoomObjectReplicator)->[AccessibilityIssue]{
        var issuesFound:[AccessibilityIssue]=[AccessibilityIssue]()
        //If exist
        let retrieveObjectResults=replicator.retrieveObjectWithKeyword(keyword: keywordMainPart)
        var dependencyObjects=replicator.retrieveObjectWithKeyword(keywords: dependency)
        if existence!{
            //Then non existence would be problem
            let count=retrieveObjectResults.foundRoomplanSurfaces.count+retrieveObjectResults.foundRoomplanObjects.count+retrieveObjectResults.foundDetectedObjects.count
            let count_dep=dependency.count
            if count_dep==0{
                //Then just tell if there is any retrieved object existing
                if count == 0{
                    issuesFound.append(AccessibilityIssue(time: Date.now, identifier: Settings.instance.noSmokeAlarmUUID, transform: nil, type: .NonExist, description: "", rubric: self,problem: ""))
                }
            }
            else{
                //Tell if all dependency objects has at least one item near them
                for dep in dependencyObjects.foundRoomplanObjects{
                    //Iterate through OD objects
                    var exist:Bool=false
                    for obj in retrieveObjectResults.foundDetectedObjects{
                        if obj.valid{
                            if obj.calculateDistance(centerPos: obj.position, transform: dep.transform)<Settings.instance.near_tolerance{
                                exist=true
                                break
                            }
                        }
                    }
                    if exist{
                        //Do nothing
                    }
                    else{
                        let issue=AccessibilityIssue(time: Date.now, identifier: dep.identifier, transform: dep.transform, type: .NonExist, description: "", rubric: self,problem: "")
                        issue.setSourceRPObject(source: dep)
                        issuesFound.append(issue)
                    }
                }
            }
        }
        else{
            //Then exist become problem. Only detected objects would be considered
            for obj in retrieveObjectResults.foundDetectedObjects{
                if obj.valid{
                    let issue=AccessibilityIssue(time: Date.now, identifier: obj.identifier, transform: obj.transform, type: .Exist, description: "", rubric: self,problem: "")
                    issue.setSourceODObject(source: obj)
                    issuesFound.append(issue)
                }
            }
        }
        
        return issuesFound
    }
    public func retrievePositionalIssue(replicator:RoomObjectReplicator,measurement:String)->[AccessibilityIssue]{
        var issuesFound:[AccessibilityIssue]=[AccessibilityIssue]()
        //Use the requrements to find required cases in replicator.
        //Note: dependency not implemented considering we havn't figure out plane detection and understanding. All values will be evaluated against floor
//        if dependency != nil{
//            for depend in dependency!{
//                let retrieveResults=replicator.retrieveObjectWithKeyword(keyword: depend)
//            }
//        }
        let retrieveResults=replicator.retrieveObjectWithKeyword(keyword: keywordMainPart)
        for obj in retrieveResults.foundDetectedObjects{
            if obj.valid != true{
                continue
            }
            //print(obj.detectedObjectCategory.rawValue)
            //print(obj.position)
            let problem=compareValues(target: obj.getPosition(measurement: measurement), comparison: self.dimension!.comparison!, values: self.dimension!.value!)
            if  problem.count>0{
                let issue=AccessibilityIssue(time: Date.now,identifier:obj.identifier,transform: obj.transform,
                                             type: AccessibilityIssueType.ObjectPosition, description: "", rubric: self,problem: problem)
                issue.setSourceODObject(source: obj)
                issuesFound.append(issue)
            }
        }
        for obj in retrieveResults.foundRoomplanObjects{
            let problem=compareValues(target: obj.getSpecificPosition(measurement: measurement), comparison: self.dimension!.comparison!, values: self.dimension!.value!)
            if  problem.count>0{
                //print("Found obj position issue")
                //print(obj.category)
                //print(obj.getSpecificPosition(measurement: measurement))
                //print(obj.transform.columns.3)
                let issue=AccessibilityIssue(time: Date.now,identifier:obj.identifier,transform: obj.transform,
                                             type: AccessibilityIssueType.ObjectPosition, description: "", rubric: self,problem: problem)
                issue.setSourceRPObject(source: obj)
                issuesFound.append(issue)
            }
        }
        for obj in retrieveResults.foundRoomplanSurfaces{
            let problem=compareValues(target: obj.getFullPosition(measurement: measurement), comparison: self.dimension!.comparison!, values: self.dimension!.value!)
            if problem.count>0{
                let issue=AccessibilityIssue(time: Date.now,identifier:obj.identifier,transform: obj.transform,
                                             type: AccessibilityIssueType.ObjectPosition, description: "", rubric: self,problem: problem)
                issue.setSourceRPSurface(source: obj)
                issuesFound.append(issue)
            }
        }
            
        
        return issuesFound
    }
    public func compareValues(target:Float,comparison:String,values:[Int])->String{
        //TODO: conduct unit transform. From meter to inch
        //First transform the target value to inch!
        let targetTransformed=target*39.37
        let v=Float(values[0])
        //let targetTransformed=target
        switch requirement{
        case "Dim_Height":
            switch comparison{
            case "NoLessThan":
                if targetTransformed>=Float(values[0]){
                    return ""
                }
                return "LOW"
            case "LessThan":
                if targetTransformed<=Float(values[0]){
                    return ""
                }
                return "HIGH"
            case "Between":
                if targetTransformed >= Float(values[0]) && targetTransformed <= Float(values[1]){
                    return ""
                }
                else if targetTransformed <= Float(values[0]){
                    return "LOW"
                }
                else{
                    return "HIGH"
                }
            case "Equal":
                if targetTransformed<=Float(values[0])+Float(Settings.instance.dimension_tolerance) && targetTransformed>=Float(values[0])-Float(Settings.instance.dimension_tolerance){
                    return ""
                }
                else if targetTransformed<=Float(values[0])+Float(Settings.instance.dimension_tolerance){
                    return "LOW"
                }
                else{
                    return "HIGH"
                }
            default:
                fatalError("Unexpected comparisoon type")
            }
        case "Depth":
            switch comparison{
            case "NoLessThan":
                if targetTransformed>=Float(values[0]){
                    return ""
                }
                return "SHALLOW"
            case "LessThan":
                if targetTransformed<=Float(values[0]){
                    return ""
                }
                return "DEEP"
            case "Between":
                if targetTransformed >= Float(values[0]) && targetTransformed <= Float(values[1]){
                    return ""
                }
                else if targetTransformed <= Float(values[0]){
                    return "SHALLOW"
                }
                else{
                    return "DEEP"
                }
            case "Equal":
                if targetTransformed<=Float(values[0])+Float(Settings.instance.dimension_tolerance) && targetTransformed>=Float(values[0])-Float(Settings.instance.dimension_tolerance){
                    return ""
                }
                else if targetTransformed<=Float(values[0])+Float(Settings.instance.dimension_tolerance){
                    return "SHALLOW"
                }
                else{
                    return "DEEP"
                }
            default:
                fatalError("Unexpected comparisoon type")
            }
        case "Radius":
            switch comparison{
            case "NoLessThan":
                if targetTransformed>=Float(values[0]){
                    return ""
                }
                return "NARROW"
            case "LessThan":
                if targetTransformed<=Float(values[0]){
                    return ""
                }
                return "WIDE"
            case "Between":
                if targetTransformed >= Float(values[0]) && targetTransformed <= Float(values[1]){
                    return ""
                }
                else if targetTransformed <= Float(values[0]){
                    return "NARROW"
                }
                else{
                    return "WIDE"
                }
            case "Equal":
                if targetTransformed<=Float(values[0])+Float(Settings.instance.dimension_tolerance) && targetTransformed>=Float(values[0])-Float(Settings.instance.dimension_tolerance){
                    return ""
                }
                else if targetTransformed<=Float(values[0])+Float(Settings.instance.dimension_tolerance){
                    return "NARROW"
                }
                else{
                    return "WIDE"
                }
            default:
                fatalError("Unexpected comparisoon type")
            }
        case "ExistenceOrNot":
            return ""
        case "Pos_Height":
            switch comparison{
            case "NoLessThan":
                if targetTransformed>=Float(values[0]){
                    return ""
                }
                return "LOW"
            case "LessThan":
                if targetTransformed<=Float(values[0]){
                    return ""
                }
                return "HIGH"
            case "Between":
                if targetTransformed >= Float(values[0]) && targetTransformed <= Float(values[1]){
                    return ""
                }
                else if targetTransformed <= Float(values[0]){
                    return "LOW"
                }
                else{
                    return "HIGH"
                }
            case "Equal":
                if targetTransformed<=Float(values[0])+Float(Settings.instance.dimension_tolerance) && targetTransformed>=Float(values[0])-Float(Settings.instance.dimension_tolerance){
                    return ""
                }
                else if targetTransformed<=Float(values[0])+Float(Settings.instance.dimension_tolerance){
                    return "LOW"
                }
                else{
                    return "HIGH"
                }
            default:
                fatalError("Unexpected comparisoon type")
            }
        default:
            return ""
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

enum Community:String{
    case wheelchair="Wheelchair",elder="Elder",children="Children",BLV="BLV"
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
