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
    var community:[Community]=[]
    var height:Int=0
    
    var replicator:RoomObjectReplicator?=nil
    //Hyper parameters
    var dimension_tolerance=0
    var near_tolerance:Float=1 //The threshold in meter for determining how close is considered close to an object. For example, if a grab bar is not within 0.5 meter to a toilet, it is not considered as close
    var detectedObjectMergeThreshold=Float(0.3)
    var detectedObjectAnchorCountThreshold=3
    var raycastEnabled=true
    var modelURL:URL?
    var miniMap:MiniMapLayer?
    var yoloInputWidth:Int=640
    var yoloInputHeight:Int=640
    var yoloConfidenceThreshold:Float = 0.7
    var BLVAssistance:Bool=false
    var viewcontroller:ViewController?
    var noSmokeAlarmUUID=UUID()
    var existedUUID:[UUID]=[UUID]()
    //var globeAsset:MDLAsset
    //var globeEntity:Entity
}
