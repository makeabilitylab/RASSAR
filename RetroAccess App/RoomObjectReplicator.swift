import ARKit
import RoomPlan
import RealityKit

//This class replicates the detected room. All items, including Roomplan objects, surfaces, and Object Detection objects, will be stored here.
//So any issue detector will take this replicator class as input since it contains all information we have.
public class RoomObjectReplicator {

    private var trackedObjectAnchors: Set<RoomObjectAnchor>
    private var trackedObjectAnchorsByIdentifier: [UUID: RoomObjectAnchor]
    private var inflightObjectAnchors: Set<RoomObjectAnchor>
    
    private var trackedSurfaceAnchors: Set<RoomSurfaceAnchor>
    private var trackedSurfaceAnchorsByIdentifier: [UUID: RoomSurfaceAnchor]
    private var inflightSurfaceAnchors: Set<RoomSurfaceAnchor>
    
    private var trackedObjects:[DetectedObject]
    private var trackedObjectsByIdentifier:[UUID:DetectedObject]
    private var inflightObjects:[DetectedObject]
    
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
        inflightObjects=[DetectedObject]()
        
        detectedIssues=[UUID:AccessibilityIssue]()
        filter=nil
        filter=Filter(replicator: self)
    }

    public func anchor(objects: [CapturedRoom.Object],surfaces:[CapturedRoom.Surface] ,in session: RoomCaptureSession) {
        //TODO: still need to add OD objects in this flow. Also, remember to call this function when getting OD results.
        for object in objects {
            if let existingAnchor = trackedObjectAnchorsByIdentifier[object.identifier] {
                existingAnchor.update(object)
                inflightObjectAnchors.insert(existingAnchor)
                //session.arSession.delegate?.session?(session.arSession, didUpdate: [existingAnchor])
            } else {
                let anchor = RoomObjectAnchor(object)
                inflightObjectAnchors.insert(anchor)
                //session.arSession.add(anchor: anchor)
            }
        }
        for surface in surfaces {
            if let existingAnchor = trackedSurfaceAnchorsByIdentifier[surface.identifier] {
                //existingAnchor.update(surface)
                inflightSurfaceAnchors.insert(existingAnchor)
                //session.arSession.delegate?.session?(session.arSession, didUpdate: [existingAnchor])
            } else {
                let anchor = RoomSurfaceAnchor(surface)
                inflightSurfaceAnchors.insert(anchor)
                //session.arSession.add(anchor: anchor)
            }
        }

        trackInflightAnchors(in: session)
    }

    private func trackInflightAnchors(in session: RoomCaptureSession) {
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
    public func retrieveObjectWithKeyword(keyword:String)->(foundDetectedObjects:[DetectedObject],foundRoomplanObjects:[RoomObjectAnchor],foundRoomplanSurfaces:[RoomSurfaceAnchor]){
        let lowerkeyword=keyword.lowercased()
        var foundDetectedObjects=[DetectedObject]()
        var foundRoomplanObjects=[RoomObjectAnchor]()
        var foundRoomplanSurfaces=[RoomSurfaceAnchor]()
        for cat in ODCategory.allCases.map({ $0.rawValue }){
            if cat==lowerkeyword{
                //retrieve all ODObjects with same category
                for obj in trackedObjects{
                    if obj.detectedObjectCategory.rawValue==keyword{
                        foundDetectedObjects.append(obj)
                    }
                }
                return (foundDetectedObjects,foundRoomplanObjects,foundRoomplanSurfaces)
            }
        }
        for cat in RPObjectCategory.allCases.map({ $0.rawValue }){
            if cat==lowerkeyword{
                //retrieve all RPObjects with same category
                for obj in trackedObjectAnchors{
                    if obj.category==transformIntoRPObjectEnum(category:keyword){
                        foundRoomplanObjects.append(obj)
                    }
                }
                return (foundDetectedObjects,foundRoomplanObjects,foundRoomplanSurfaces)
            }
        }
        for cat in RPSurfaceCategory.allCases.map({ $0.rawValue }){
            if cat==lowerkeyword{
                //retrieve all RPSurfaces with same category
                for srf in trackedSurfaceAnchors{
                    if srf.category==transformIntoRPSurfaceEnum(category: keyword){
                        foundRoomplanSurfaces.append(srf)
                    }
                }
                return (foundDetectedObjects,foundRoomplanObjects,foundRoomplanSurfaces)
            }
        }
        print("Unable to find object of "+keyword)
        return (foundDetectedObjects,foundRoomplanObjects,foundRoomplanSurfaces)
        //fatalError("Unknown keyword given")
    }
    public func updateAccessibilityIssue(in session: RoomCaptureSession){
        //First search with current frame information
        let currentIssues=self.filter!.filter()
        //Then set all existing issue's updated attribute to false. This helps removing disappearing issues
        for (_,issue) in detectedIssues{
            issue.updated=false
        }
        //Try to compare and merge these current issues with existing ones. Notice that all incoming accessibility issues are new instances even thought content might be exactly same
        for issue in currentIssues{
            issue.updated=true
            if detectedIssues[issue.identifier] != nil{
                //Nothing to do for now
            }
            else{
                detectedIssues[issue.identifier]=issue
            }
        }
        for (id,issue) in detectedIssues{
            //Remove issues not updated. Those are disappearing issues
//            if issue.updated==false{
//                detectedIssues[id]=nil
//                print("Issue with type "+issue.category.rawValue+" is deleted")
//            }
        }
    }
    public func getAllIssuesToBePresented()->[AccessibilityIssue]{
//        var anchor2show=[RoomObjectAnchor]()
//        for (_,issue) in detectedIssues{
//            anchor2show.append(issue.getAnchor())
//        }
        return Array(detectedIssues.values)
    }
    func transformIntoRPObjectEnum(category:String)->CapturedRoom.Object.Category{
        
        switch category.lowercased(){
        case "bathtub":
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
        case "stove":
            return CapturedRoom.Object.Category.stove
        case "table":
            return CapturedRoom.Object.Category.table
        case "toilet":
            return CapturedRoom.Object.Category.toilet
        //case "washer":
            //return CapturedRoom.Object.Category.washer
        default:
            fatalError("Unknown RP object received")
        }
    }
    func transformIntoRPSurfaceEnum(category:String)->CapturedRoom.Surface.Category{
        
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
            fatalError("Unknown RP object received")
        }
    }

}
