//
//  AccessibilityIssue.swift
//  RetroAccess App
//
//  Created by Xia Su on 7/11/22.
//

import Foundation
import ARKit

public enum AccessibilityIssueType{
    //TODO: add all existing issues
    case DangerousItem;
}

class AccessibilityIssue
{
    var time:Date
    var transform:simd_float4x4
    var category:AccessibilityIssueType
    var description:String
    
    public init(time: Date, transform: simd_float4x4,type:AccessibilityIssueType,description:String) {
        self.time = time
        self.transform = transform
        self.category=type
        self.description=description
    }
    public func getSuggestion()->String{
        //TODO: retrirve suggestion from document
        fatalError("Unimplemented function")
    }
    public func getAnchor()->ARAnchor{
        //TODO: output an aranchor for this issue
        fatalError("Unimplemented function")
    }
}
