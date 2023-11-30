//
//  AccessibilityIssue.swift
//  RetroAccess App
//
//  Created by Xia Su on 7/11/22.
//

import Foundation
import ARKit

public enum AccessibilityIssueType:String{
    //TODO: add all existing issues
    case Exist="Risky Item"
    case NonExist="Lack of Assistive Item"
    case ObjectDimension="Object Dimension"
    case ObjectPosition="Object Position"
}

public class AccessibilityIssue:Equatable
{
    public static func == (lhs: AccessibilityIssue, rhs: AccessibilityIssue) -> Bool {
        if lhs.identifier == rhs.identifier{
            return true
        }
        return false
    }
    
    var time:Date
    var identifier:UUID
    var transform:simd_float4x4?
    var category:AccessibilityIssueType
    var description:String
    var problem:String
    var rubric:Rubric
    var sourceObject:DetectedObject?
    var sourceRPObject:RoomObjectAnchor?
    var sourceRPSurface:RoomSurfaceAnchor?
    var cancelled:Bool=false
    public var updated=false
    public init(time: Date, identifier:UUID,transform: simd_float4x4?,type:AccessibilityIssueType,description:String,rubric:Rubric,problem:String) {
        self.time = time
        self.identifier=identifier
        self.transform = transform
        self.category=type
        self.description=description
        self.rubric=rubric
        self.problem=problem
    }
    public func cancel(){
        if self.cancelled{
            print("Already cancelled!")
        }
        self.cancelled=true
    }
    public func getSuggestion()->String{
        //TODO: retrirve suggestion from document
        if let sug=rubric.suggestions{
            return sug[0]
        }
        return ""
    }
    public func getDetails()->String{
        //TODO: get detailed info for this issue
        var details=rubric.get_description()
        if details.contains("XXX"){
            let replaced = details.replacingOccurrences(of: "XXX", with: problem)
            return replaced
        }
        return details
    }
    public func getShortDescription()->String{
        return rubric.message!.replacingOccurrences(of: "Warning:\n", with: "").replacingOccurrences(of: "XXX", with: problem)
    }
    public func getAnchor()->RoomObjectAnchor{
        if sourceObject != nil{
            //TODO: Get an ARAcnhor from detected object
            fatalError("Uninplemented situation")
        }
        else if sourceRPObject != nil{
            let anchor=sourceRPObject!
            //TODO: Set style to red
            return anchor
        }
        else if sourceRPSurface != nil{
            let anchor=sourceRPSurface!
            //TODO: Set style to red
            fatalError("Uninplemented situation")
        }
        
        fatalError("Empty Accessibility Issue")
    }
    public func getSource()->(SourceDetectedObject:DetectedObject?,SourceRoomplanObject:RoomObjectAnchor?,SourceRoomplanSurface:RoomSurfaceAnchor?){
        return (sourceObject,sourceRPObject,sourceRPSurface)
    }
    public func getSourceUUID()->UUID?{
        let source = getSource()
        if source.SourceDetectedObject != nil{
            return source.SourceDetectedObject!.identifier
        }
        else if source.SourceRoomplanObject != nil{
            return source.SourceRoomplanObject!.identifier
        }
        else if source.SourceRoomplanSurface != nil{
            return source.SourceRoomplanSurface!.identifier
        }
        else{
            return nil
        }
    }
    public func update(){
        if sourceObject != nil{
            //TODO: Get an ARAcnhor from detected object
            fatalError("Uninplemented situation")
        }
        else if sourceRPObject != nil{
            let anchor=sourceRPObject!
            //TODO: Set style to red
        }
        else if sourceRPSurface != nil{
            let anchor=sourceRPSurface!
            //TODO: Set style to red
        }
        
        fatalError("Empty Accessibility Issue")
    }
    public func setSourceRPObject(source:RoomObjectAnchor){
        sourceRPObject=source
        sourceRPSurface=nil
        sourceObject=nil
    }
    public func setSourceRPSurface(source:RoomSurfaceAnchor){
        sourceRPSurface=source
        sourceRPObject=nil
        sourceObject=nil
    }
    public func setSourceODObject(source:DetectedObject){
        sourceObject=source
        sourceRPObject=nil
        sourceRPSurface=nil
    }
    public func hasSource()->Bool{
        if sourceObject != nil || sourceRPObject != nil || sourceRPSurface != nil{
            return true
        }
        return false
    }
    public func hasPosition()->Bool{
        if sourceObject != nil {
            return true
        }
        if sourceRPObject != nil {
            return true
        }
        if sourceRPSurface != nil{
            return true
        }
        return false
    }
    public func getPosition()->simd_float3{
        if sourceObject != nil {
            return sourceObject!.position
        }
        if sourceRPObject != nil {
            return sourceRPObject!.getFullPosition()
        }
        if sourceRPSurface != nil{
            return sourceRPSurface!.getFullPosition()
        }
        fatalError("This issue has no position!")
    }
}
extension AccessibilityIssue:Encodable{
    enum CodingKeys: String, CodingKey {
            case category
            case details
            case identifier
            case cancelled
        }
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(category.rawValue, forKey: .category)
            try container.encode(getSourceUUID(), forKey: .identifier)
            try container.encode(getDetails(), forKey: .details)
            try container.encode(cancelled, forKey: .cancelled)
        }
}
