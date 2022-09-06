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
    case ExistenceOrNot="ExistOrNot"
    case ObjectDimension="ObjDim"
    case ObjectPosition="ObjPos"
}

public class AccessibilityIssue
{
    var time:Date
    var identifier:UUID
    var transform:simd_float4x4?
    var category:AccessibilityIssueType
    var description:String
    var rubric:Situation
    var sourceObject:DetectedObject?
    var sourceRPObject:RoomObjectAnchor?
    var sourceRPSurface:RoomSurfaceAnchor?
    public var updated=false
    public init(time: Date, identifier:UUID,transform: simd_float4x4?,type:AccessibilityIssueType,description:String,rubric:Situation) {
        self.time = time
        self.identifier=identifier
        self.transform = transform
        self.category=type
        self.description=description
        self.rubric=rubric
    }
    public func getSuggestion()->String{
        //TODO: retrirve suggestion from document
        fatalError("Unimplemented function")
    }
    public func getDetails()->String{
        //TODO: get detailed info for this issue
        return "Detailed information of this accessibility issue"
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
    
}
