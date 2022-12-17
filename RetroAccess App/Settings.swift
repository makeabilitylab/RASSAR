//
//  Settings.swift
//  RetroAccess App
//
//  Created by Xia Su on 7/27/22.
//

import Foundation
import ARKit
import RealityKit
//This class stores all golbal settings, like all user selections done in thee onboarding view.
class Settings{
    static let instance = Settings()
        
    private init() {
//        let bundle = Bundle.main
//        let path = bundle.path(forResource: "Globe 3D Model", ofType: "obj")
//        let url = URL(fileURLWithPath: path!)
//        globeAsset = MDLAsset(url: url)
//        var urlpath     = Bundle.main.path(forResource: "Wireframe_3D_Globe", ofType: "usdz")
//        let url = URL(fileURLWithPath: urlpath!)
//        globeEntity = try! Entity.load(contentsOf: url)
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
    var raycastEnabled=true
    var modelURL:URL?
    //var globeAsset:MDLAsset
    //var globeEntity:Entity
}
