import ARKit
import RoomPlan
import RealityKit
import AudioToolbox
//This class replicates the detected room. All items, including Roomplan objects, surfaces, and Object Detection objects, will be stored here.
//So any issue detector will take this replicator class as input since it contains all information we have.
public class RoomObjectReplicator{
    
    private var arView:ARView?
    var trackedObjectAnchors: Set<RoomObjectAnchor>
    private var trackedObjectAnchorsByIdentifier: [UUID: RoomObjectAnchor]
    private var inflightObjectAnchors: Set<RoomObjectAnchor>
    
    var trackedSurfaceAnchors: Set<RoomSurfaceAnchor>
    private var trackedSurfaceAnchorsByIdentifier: [UUID: RoomSurfaceAnchor]
    private var inflightSurfaceAnchors: Set<RoomSurfaceAnchor>
    
    var trackedObjects:[DetectedObject]
    private var trackedObjectsByIdentifier:[UUID:DetectedObject]
    
    private var detectedIssues:[UUID:AccessibilityIssue]
    private var filter:Filter?
    public init() {
        trackedObjectAnchors = Set<RoomObjectAnchor>()
        trackedObjectAnchorsByIdentifier = [UUID: RoomObjectAnchor]()
        inflightObjectAnchors = Set<RoomObjectAnchor>()
        
        trackedSurfaceAnchors = Set<RoomSurfaceAnchor>()
        trackedSurfaceAnchorsByIdentifier = [UUID: RoomSurfaceAnchor]()
        inflightSurfaceAnchors = Set<RoomSurfaceAnchor>()
        
        trackedObjects=[DetectedObject]()
        trackedObjectsByIdentifier=[UUID:DetectedObject]()
        
        detectedIssues=[UUID:AccessibilityIssue]()
        filter=nil
        filter=Filter(replicator: self)
    }
    public func setView(view:ARView){
        arView=view
    }
    public func anchor(objects: [CapturedRoom.Object],surfaces:[CapturedRoom.Surface] ,in session: RoomCaptureSession) {
        //TODO: still need to add OD objects in this flow. Also, remember to call this function when getting OD results.
        for object in objects {
            if let existingAnchor = trackedObjectAnchorsByIdentifier[object.identifier] {
                existingAnchor.update(object)
                inflightObjectAnchors.insert(existingAnchor)
//                if Settings.instance.BLVAssistance{
//                    Settings.instance.viewcontroller?.enqueueAudio(audioFeedback: AudioFeedback(content: existingAnchor.getCategoryName(), type: .detectedObject, uploadTime: Date(), issue: nil))
//                }
                //session.arSession.delegate?.session?(session.arSession, didUpdate: [existingAnchor])
            } else {
                let anchor = RoomObjectAnchor(object)
                inflightObjectAnchors.insert(anchor)
                if Settings.instance.BLVAssistance{
                    if !Settings.instance.existedUUID.contains(anchor.identifier){
                        Settings.instance.existedUUID.append(anchor.identifier)
                        Settings.instance.viewcontroller?.enqueueAudio(audioFeedback: AudioFeedback(content: anchor.getCategoryName(), type: .detectedObject, uploadTime: Date(), issue: nil))
                        print(anchor.identifier)
                    }
                }
                //session.arSession.add(anchor: anchor)
            }
        }
        for surface in surfaces {
            if let existingAnchor = trackedSurfaceAnchorsByIdentifier[surface.identifier] {
                //existingAnchor.update(surface)
                inflightSurfaceAnchors.insert(existingAnchor)
//                if Settings.instance.BLVAssistance && existingAnchor.category != .wall{
//                    Settings.instance.viewcontroller?.enqueueAudio(audioFeedback: AudioFeedback(content: existingAnchor.getCategoryName(), type: .detectedObject, uploadTime: Date(), issue: nil))
//                }
                //session.arSession.delegate?.session?(session.arSession, didUpdate: [existingAnchor])
            } else {
                let anchor = RoomSurfaceAnchor(surface)
                inflightSurfaceAnchors.insert(anchor)
                if Settings.instance.BLVAssistance && anchor.category != .wall{
                    if !Settings.instance.existedUUID.contains(anchor.identifier){
                        Settings.instance.existedUUID.append(anchor.identifier)
                        Settings.instance.viewcontroller?.enqueueAudio(audioFeedback: AudioFeedback(content: anchor.getCategoryName(), type: .detectedObject, uploadTime: Date(), issue: nil))
                        //print(anchor.identifier)
                    }
                }
                //session.arSession.add(anchor: anchor)
            }
        }

        trackInflightAnchors(in: session)
    }

    private func trackInflightAnchors(in session: RoomCaptureSession) {
        //var new_objects:String=""
//        if Settings.instance.BLVAssistance{
//            for inflight in inflightObjectAnchors{
//                Settings.instance.viewcontroller?.enqueueAudio(audioFeedback: AudioFeedback(content: inflight.getCategoryName(), type: .detectedObject, uploadTime: Date(), issue: nil))
//            }
//            for inflight in inflightSurfaceAnchors{
//                if inflight.category != .wall{
//                    Settings.instance.viewcontroller?.enqueueAudio(audioFeedback: AudioFeedback(content: inflight.getCategoryName(), type: .detectedObject, uploadTime: Date(), issue: nil))
//                }
//            }
//        }
        trackedObjectAnchors.subtracting(inflightObjectAnchors).forEach(session.arSession.remove)
        trackedObjectAnchors.removeAll(keepingCapacity: true)
        trackedObjectAnchors.formUnion(inflightObjectAnchors)
        inflightObjectAnchors.removeAll(keepingCapacity: true)
        trackedObjectAnchorsByIdentifier.removeAll(keepingCapacity: true)

        for trackedAnchor in trackedObjectAnchors {
            trackedObjectAnchorsByIdentifier[trackedAnchor.identifier] = trackedAnchor
        }

        trackedSurfaceAnchors.subtracting(inflightSurfaceAnchors).forEach(session.arSession.remove)
        trackedSurfaceAnchors.removeAll(keepingCapacity: true)
        trackedSurfaceAnchors.formUnion(inflightSurfaceAnchors)
        inflightSurfaceAnchors.removeAll(keepingCapacity: true)
        trackedSurfaceAnchorsByIdentifier.removeAll(keepingCapacity: true)

        for trackedAnchor in trackedSurfaceAnchors {
            trackedSurfaceAnchorsByIdentifier[trackedAnchor.identifier] = trackedAnchor
        }
    }
    public func addODAnchor(anchors:[DetectedObjectAnchor]){
        //Match inflight anchors with existing DetectedObjects
        var anchorList=anchors
        for obj in trackedObjects{
            var includedAnchor=[DetectedObjectAnchor]()
            //loop one by one to try merge.
            for a in anchorList{
                if obj.merge(object: a){
                    includedAnchor.append(a)
                }
            }
            anchorList=anchorList.filter{ !includedAnchor.contains($0) }
        }
        for obj in trackedObjects{
            var expelledAnchor=[DetectedObjectAnchor]()
            //loop one by one to try merge.
            for a in anchorList{
                if obj.expel(object: a){
                    expelledAnchor.append(a)
                }
            }
            anchorList=anchorList.filter{ !expelledAnchor.contains($0) }
        }
        //Add the rest of anchors as trackedObjects
        while anchorList.count>0{
            let newObject=DetectedObject(anchor: anchorList[0])
            trackedObjects.append(newObject)
            arView?.scene.addAnchor(newObject.notifier)
            anchorList.remove(at: 0)
            var includedAnchor=[DetectedObjectAnchor]()
            for a in anchorList{
                if newObject.merge(object: a){
                    includedAnchor.append(a)
                }
            }
            anchorList=anchorList.filter{ !includedAnchor.contains($0) }
        }
    }
    public func retrieveObjectWithKeyword(keyword:String)->(foundDetectedObjects:[DetectedObject],foundRoomplanObjects:[RoomObjectAnchor],foundRoomplanSurfaces:[RoomSurfaceAnchor]){
        let lowerkeyword=keyword.lowercased()
        var foundDetectedObjects=[DetectedObject]()
        var foundRoomplanObjects=[RoomObjectAnchor]()
        var foundRoomplanSurfaces=[RoomSurfaceAnchor]()
        let cat1=transformIntoODObjectEnum(category: lowerkeyword)
        if cat1 != nil{
            for obj in trackedObjects{
                if obj.detectedObjectCategory==cat1{
                    foundDetectedObjects.append(obj)
                }
            }
            return (foundDetectedObjects,foundRoomplanObjects,foundRoomplanSurfaces)
        }
        let cat2=transformIntoRPObjectEnum(category: lowerkeyword)
        if cat2 != nil{
            for obj in trackedObjectAnchors{
                if obj.category==cat2{
                    foundRoomplanObjects.append(obj)
                }
            }
            return (foundDetectedObjects,foundRoomplanObjects,foundRoomplanSurfaces)
        }
        let cat3=transformIntoRPSurfaceEnum(category: lowerkeyword)
        if cat3 != nil{
            for obj in trackedSurfaceAnchors{
                if obj.category==cat3{
                    foundRoomplanSurfaces.append(obj)
                }
            }
            return (foundDetectedObjects,foundRoomplanObjects,foundRoomplanSurfaces)
        }
        //print("Unable to find object of "+keyword)
        return (foundDetectedObjects,foundRoomplanObjects,foundRoomplanSurfaces)
    }
    public func retrieveObjectWithKeyword(keywords:[String])->(foundDetectedObjects:[DetectedObject],foundRoomplanObjects:[RoomObjectAnchor],foundRoomplanSurfaces:[RoomSurfaceAnchor]){
        var foundDetectedObjects=[DetectedObject]()
        var foundRoomplanObjects=[RoomObjectAnchor]()
        var foundRoomplanSurfaces=[RoomSurfaceAnchor]()
        for keyword in keywords{
            let lowerkeyword=keyword.lowercased()
            let cat1=transformIntoODObjectEnum(category: lowerkeyword)
            if cat1 != nil{
                for obj in trackedObjects{
                    if obj.detectedObjectCategory==cat1{
                        foundDetectedObjects.append(obj)
                    }
                }
            }
            let cat2=transformIntoRPObjectEnum(category: lowerkeyword)
            if cat2 != nil{
                for obj in trackedObjectAnchors{
                    if obj.category==cat2{
                        foundRoomplanObjects.append(obj)
                    }
                }
            }
            let cat3=transformIntoRPSurfaceEnum(category: lowerkeyword)
            if cat3 != nil{
                for obj in trackedSurfaceAnchors{
                    if obj.category==cat3{
                        foundRoomplanSurfaces.append(obj)
                        //print("Found door!")
                    }
                }
            }
        }
        //print("Unable to find object of "+keyword)
        return (foundDetectedObjects,foundRoomplanObjects,foundRoomplanSurfaces)
    }
    public func getFloorHeight()->Float{
        //TODO: calculate the height of floor
        var minHeight:Float=10
//        for obj in trackedObjects{
//            if obj.position.z<minHeight{
//                minHeight=obj.position.z
//            }
//        }
        for obj in trackedObjectAnchors{
            if obj.transform.columns.3.y-obj.dimensions.y/2<minHeight{
                minHeight=obj.transform.columns.3.y-obj.dimensions.y/2
            }
        }
        for srf in trackedSurfaceAnchors{
            if srf.transform.columns.3.y-srf.dimensions.y/2<minHeight{
                minHeight=srf.transform.columns.3.y-srf.dimensions.y/2
            }
        }
        //print(String(format: "%@%f", "Calculated Min Height: ", minHeight))
        return minHeight
    }
    public func updateAccessibilityIssue(in session: RoomCaptureSession){
        //First search with current frame information
        let currentIssues=self.filter!.filter()
//        for obj in trackedObjectAnchors{
//            print(obj.category)
//            print(obj.transform.columns.3)
//            print(obj.dimensions)
//        }
//        for obj in trackedSurfaceAnchors{
//            print(obj.category)
//            print(obj.transform.columns.3)
//            print(obj.dimensions)
//        }
        //Then set all existing issue's updated attribute to false. This helps removing disappearing issues
        for (_,issue) in detectedIssues{
            issue.updated=false
        }
        //Try to compare and merge these current issues with existing ones. Notice that all incoming accessibility issues are new instances even though content might be exactly same
        for issue in currentIssues{
            issue.updated=true
            if detectedIssues[issue.identifier] != nil{
                //Nothing to do for now
                if detectedIssues[issue.identifier]!.cancelled{
                    issue.cancel()
                }
                detectedIssues[issue.identifier]=issue
            }
            else{
                detectedIssues[issue.identifier]=issue
                //AudioServicesPlaySystemSound (1057);
                Settings.instance.viewcontroller?.enqueueAudio(audioFeedback: AudioFeedback(content: issue.getShortDescription(), type: .detectedIssue, uploadTime: Date(), issue: issue))
            }
        }
        for (id,issue) in detectedIssues{
            //Remove issues not updated. Those are disappearing issues
           if issue.updated==false{
                detectedIssues[id]=nil
//                print("Issue with type "+issue.category.rawValue+" is deleted")
            }
        }
    }
    public func getIssueSummary()->String{
        //TODO: Return a text summary of all issues
        var dimCount=0,posCount=0,risCount=0,assCount=0
        for (id,issue) in detectedIssues{
            switch issue.category{
            case .Exist:
                risCount+=1
            case .NonExist:
                assCount+=1
            case .ObjectDimension:
                dimCount+=1
            case .ObjectPosition:
                posCount+=1
            }
        }
        var message="Scan finished! We detected \(detectedIssues.count) issues in total. Among which \(dimCount) are object dimension issues, \(posCount) are object position issues,\(risCount) are risky items, \(assCount) are lack of assistive items"
        return message
    }
    public func cancel(id:UUID){
        if detectedIssues[id] != nil{
            detectedIssues[id]?.cancel()
        }
    }
    public func getAllIssuesToBePresented()->[AccessibilityIssue]{
//        var anchor2show=[RoomObjectAnchor]()
//        for (_,issue) in detectedIssues{
//            anchor2show.append(issue.getAnchor())
//        }
        return Array(detectedIssues.values)
    }
    func transformIntoODObjectEnum(category:String)->ODCategory?{
        switch category.lowercased(){
        case "knob":
            return .Doorhandle
        case "doorhandle":
            return .Doorhandle
        case "lightingswitch":
            return .Switch
        case "grabbar":
            return .GrabBar
        case "outlets":
            return .ElectricSocket
        case "carpet":
            return .Rug
        case "scissors":
            return .Scissors
        case "knives":
            return .Knife
        case "medication":
            return .Medication
        case "firealarms":
            return .SmokeAlarm
        default:
            return nil
        }
    }
    func transformIntoRPObjectEnum(category:String)->CapturedRoom.Object.Category?{
        
        switch category.lowercased(){
        case "tub":
            return CapturedRoom.Object.Category.bathtub
        case "bed":
            return CapturedRoom.Object.Category.bed
        case "chair":
            return CapturedRoom.Object.Category.chair
        case "dishwasher":
            return CapturedRoom.Object.Category.dishwasher
        case "fireplace":
            return CapturedRoom.Object.Category.fireplace
        case "oven":
            return CapturedRoom.Object.Category.oven
        case "refrigerator":
            return CapturedRoom.Object.Category.refrigerator
        //case "screen":
            //return CapturedRoom.Object.Category.screen
        case "sink":
            return CapturedRoom.Object.Category.sink
        case "sofa":
            return CapturedRoom.Object.Category.sofa
        case "stairs":
            return CapturedRoom.Object.Category.stairs
        case "storage":
            return CapturedRoom.Object.Category.storage
        case "cabinet":
            return CapturedRoom.Object.Category.storage
        case "stove":
            return CapturedRoom.Object.Category.stove
        case "table":
            return CapturedRoom.Object.Category.table
        case "counter":
            return CapturedRoom.Object.Category.table
        case "toilet":
            return CapturedRoom.Object.Category.toilet
        //case "washer":
            //return CapturedRoom.Object.Category.washer
        default:
            return nil
        }
    }
    func transformIntoRPSurfaceEnum(category:String)->CapturedRoom.Surface.Category?{
        
        switch category.lowercased(){
        case "wall":
            return CapturedRoom.Surface.Category.wall
        case "door":
            return CapturedRoom.Surface.Category.door(isOpen: false)//TODO: check if this isOpen feature matters
        case "window":
            return CapturedRoom.Surface.Category.window
        case "opening":
            return CapturedRoom.Surface.Category.opening
       
        default:
            return nil
        }
    }
    
    

}
extension RoomObjectReplicator:Encodable{
    enum CodingKeys: String, CodingKey {
            case time
            case objectAnchors
            case surfaceAnchors
            case detectedObjects
        case accessibilityIssues
        }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(NSDate().timeIntervalSince1970, forKey: .time)
        try container.encode(trackedObjectAnchors, forKey: .objectAnchors)
        try container.encode(trackedSurfaceAnchors, forKey: .surfaceAnchors)
        try container.encode(trackedObjects, forKey: .detectedObjects)
        try container.encode(detectedIssues,forKey: .accessibilityIssues)
    }
}

