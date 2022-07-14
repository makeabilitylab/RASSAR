//
//  DimensionFilter.swift
//  RetroAccess App
//
//  Created by Xia Su on 7/11/22.
//

import Foundation
import ARKit
class Filter
{
    var keywords:[String]
    //TODO: create 2 json files
    let rubricFile=""
    let suggestionFile=""
    public init(keyword_list:[String]) {
        self.keywords=keyword_list
    }
    public func retrieve()->AccessibilityIssue?{
        fatalError("Unimplemented function")
    }
}


class DimensionFilter:Filter
{
    
}

class DangerousItemFilter:Filter
{
    
}

//TODO: add all filter classes here
