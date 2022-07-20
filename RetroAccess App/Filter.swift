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
    var rubrics:Data?
    var replicator:RoomObjectReplicator
    public init(replicator:RoomObjectReplicator) {
        self.replicator=replicator
        rubrics=readLocalJSONFile(forName: rubricFile)
        if(rubrics==nil){
            fatalError("Failed to read json rubrics")
        }
    }
    public func filter()->AccessibilityIssue?{
        //Go through the entire accessbility issue table to find potential issues
        
        fatalError("Unimplemented function")
    }
    public func retrieve(keyword:String)->AccessibilityIssue?{
        //Find specific issues with keyword
        fatalError("Unimplemented function")
    }
    func readLocalJSONFile(forName name: String) -> Data? {
        do {
            if let filePath = Bundle.main.path(forResource: name, ofType: "json") {
                let fileUrl = URL(fileURLWithPath: filePath)
                let data = try Data(contentsOf: fileUrl)
                return data
            }
        } catch {
            print("error: \(error)")
        }
        return nil
    }
}
