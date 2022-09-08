//
//  Settings.swift
//  RetroAccess App
//
//  Created by Xia Su on 7/27/22.
//

import Foundation

//This class stores all golbal settings, like all user selections done in thee onboarding view.
class Settings{
    static let instance = Settings()
        
    private init() {
    }
    public func setReplicator(rep:RoomObjectReplicator){
        replicator=rep
    }
        
    //creates the global variable
    var community:String="null"
    var height:Int=0
    
    var replicator:RoomObjectReplicator?=nil
    //Hyper parameters
    var dimension_tolerance=0
    var detectedObjectMergeThreshold=Float(0.3)
    var detectedObjectAnchorCountThreshold=5
}
