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
    //TODO: create 2 json files
    let rubricFile="Rubrics"
    let suggestionFile=""
    var rubrics:=nil
    public init() {
        if let path = Bundle.main.path(forResource: rubricFile, ofType: "json") {
            do {
                  let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                  let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                  if let jsonResult = jsonResult as? Dictionary<String, AnyObject>, let person = jsonResult["person"] as? [Any] {
                            // do stuff
                  }
              } catch {
                   // handle error
              }
        }
    }
    public func filter()->AccessibilityIssue?{
        //Go through the entire accessbility issue table to find potential issues
        fatalError("Unimplemented function")
    }
    public func retrieve()->AccessibilityIssue?{
        //Gp through the entire accessbility issue table to 
        fatalError("Unimplemented function")
    }
}
