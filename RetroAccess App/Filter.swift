//
//  Filter.swift
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
    //var rubrics:Data?
    var replicator:RoomObjectReplicator
    var situations:[Situation]
    //var community:String
    public init(replicator:RoomObjectReplicator) {
        self.replicator=replicator
        self.situations=[]
        //Read all situations and store them as struct
        let rubrics=readLocalJSONFile(forName: rubricFile)
        if(rubrics==nil){
            fatalError("Failed to read json rubrics")
        }
        let json = try? JSONSerialization.jsonObject(with: rubrics!, options: [])
        if let situs = json as? [Any]{
            for situation in situs {
                self.situations.append(Situation(json:situation))
            }
        }
    }
    public func filter(replicator:RoomObjectReplicator)->[AccessibilityIssue]{
        //Go through the entire accessbility issue table to find potential issues
        var issuesFound:[AccessibilityIssue]=[]
        for situ in self.situations{
            //Use this situ to find if any issue exist in replicator
            let result=situ.search(replicator: replicator)
            issuesFound+=result
        }
        return issuesFound
    }
    public func filterWithKeyword(keyword:String)->[AccessibilityIssue]{
        //Find specific issues with keyword
        var issuesFound:[AccessibilityIssue]=[]
        for situ in self.situations{
            if(situ.keywords.contains(keyword)){
                //Use this situ to find if any issue exist in replicator
                let result=situ.search(replicator: replicator)
                issuesFound+=result
                }
        }
        return issuesFound
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
