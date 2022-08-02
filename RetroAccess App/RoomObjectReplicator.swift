import ARKit
import RoomPlan
import RealityKit

enum AllObjectCategory{
    //Cases from object detection
    case ElectricCords,Medication,Rug,GrabBar,NightLight,Handrail,ChildSafetyGate,TubMat,SmokeAlarm,ElectricSocket,Telephone,Switch,Doorhandle,Vase,Knife,Scissors,WindowGuard
    //Cases from Roomplan API
    case bathtub,bed,chair,dishwasher,fireplace,oven,refrigerator,screen,sink,sofa,stairs,storage,stove,table,toilet,unknown,washer
}

public enum ODCategory:String, CaseIterable{
    case ElectricCords="electriccords",Medication="medication",Rug="rug",GrabBar="grabbar"
    case NightLight="nightlight",Handrail="handrail",ChildSafetyGate="childsafetygate",TubMat="tubMat"
    case SmokeAlarm="smokealarm",ElectricSocket="electricsocket",Telephone="telephone",Switch="switch"
    case Doorhandle="doorhandle",Vase="vase",Knife="knife",Scissors="scissors",WindowGuard="windowguard"
}
public enum RPObjectCategory:String, CaseIterable{
    case bathtub="bathtub",bed="bed",chair="chair",dishwasher="dishwasher",fireplace="fireplace",oven="oven"
    case refrigerator="refrigerator",screen="screen",sink="sink",sofa="sofa",stairs="stairs",storage="storage"
    case stove="stove",table="table",toilet="toilet",unknown="unknown",washer="washer"
}
public enum RPSurfaceCategory:String, CaseIterable{
    case wall="wall",door="door",window="window",opening="opening"
}
public class DetectedObject{
    public var identifier: UUID {
        detectedObjectIdentifier
    }

    public var transform: simd_float4x4 {
        getCenterPosition()
    }
    public private(set) var dimensions: simd_float3
    public private(set) var detectedObjectCategory: ODCategory
    private let detectedObjectIdentifier: UUID
    private var detectedObjectTransform: [simd_float4x4]
    
    public init(category:ODCategory,transform:simd_float4x4)
    {
        detectedObjectIdentifier=UUID.init()
        detectedObjectTransform=[transform]
        detectedObjectCategory=category
        //TODO: figure out how to calculate dimensions from image bbox and object distance to camera
        dimensions=simd_make_float3(0, 0, 0)
    }
    
    //This function compares this object anchor with the other, in order to know if they are related to same item
    public func compare(object:DetectedObject)->Bool{
        //TODO: compare 2 objects by their transform, category, and potentially dimension
        fatalError("Unimplemented function")
    }
    
    //If 2 objects are related to a same item, just merge them. Notice that the object as parameter is the one being merged
    public func merge(object:DetectedObject){
        detectedObjectTransform.append(object.transform)
    }
    
    private func getCenterPosition()->simd_float4x4{
        //TODO: calculate middle position and return it
        return detectedObjectTransform[0]
    }
    public func getDimension(measurement:String)->Double{
        if measurement=="Height"{
            return Double(dimensions.y)
        }
        else{
            fatalError("Unexpected diension name")
        }
    }
}

//This class is used to replicate objects in RoomPlan results.
public class RoomObjectAnchor: ARAnchor {

    public override var identifier: UUID {
        roomObjectIdentifier
    }

    public override var transform: simd_float4x4 {
        roomObjectTransform
    }

    public private(set) var dimensions: simd_float3
    public private(set) var category: CapturedRoom.Object.Category

    private let roomObjectIdentifier: UUID
    private var roomObjectTransform: simd_float4x4

    public required init(anchor: ARAnchor) {
        guard let anchor = anchor as? RoomObjectAnchor else {
            fatalError("RoomObjectAnchor can only copy other RoomObjectAnchor instances")
        }

        roomObjectIdentifier = anchor.roomObjectIdentifier
        roomObjectTransform = anchor.roomObjectTransform
        dimensions = anchor.dimensions
        category = anchor.category

        super.init(anchor: anchor)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("Unavailable")
    }

    public init(_ object: CapturedRoom.Object) {
        roomObjectIdentifier = object.identifier
        roomObjectTransform = object.transform
        dimensions = object.dimensions
        category = object.category
        super.init(transform: object.transform)
    }

    fileprivate func update(_ object: CapturedRoom.Object) {
        roomObjectTransform = object.transform
        dimensions = object.dimensions
        category = object.category
    }
    public func getDimension(measurement:String)->Double{
        if measurement=="Height"{
            return Double(dimensions.y)
        }
        else{
            fatalError("Unexpected diension name")
        }
    }
}

//This class is used to replicate surfaces in RoomPlan results.
public class RoomSurfaceAnchor: ARAnchor {

    public override var identifier: UUID {
        roomSurfaceIdentifier
    }

    public override var transform: simd_float4x4 {
        roomSurfaceTransform
    }

    public private(set) var dimensions: simd_float3
    public private(set) var category: CapturedRoom.Surface.Category

    private let roomSurfaceIdentifier: UUID
    private var roomSurfaceTransform: simd_float4x4

    public required init(anchor: ARAnchor) {
        guard let anchor = anchor as? RoomSurfaceAnchor else {
            fatalError("RoomObjectAnchor can only copy other RoomSurfaceAnchor instances")
        }

        roomSurfaceIdentifier = anchor.roomSurfaceIdentifier
        roomSurfaceTransform = anchor.roomSurfaceTransform
        dimensions = anchor.dimensions
        category = anchor.category

        super.init(anchor: anchor)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("Unavailable")
    }

    public init(_ object: CapturedRoom.Surface) {
        roomSurfaceIdentifier = object.identifier
        roomSurfaceTransform = object.transform
        dimensions = object.dimensions
        category = object.category
        super.init(transform: object.transform)
    }

    fileprivate func update(_ object: CapturedRoom.Surface) {
        roomSurfaceTransform = object.transform
        dimensions = object.dimensions
        category = object.category
    }
    public func getDimension(measurement:String)->Double{
        if measurement=="Height"{
            return Double(dimensions.y)
        }
        else{
            fatalError("Unexpected diension name")
        }
    }
}

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
        fatalError("Unknown keyword given")
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
                //Update anchor
                //session.arSession.remove(anchor: detectedIssues[issue.identifier]!.getAnchor())
                //session.arSession.add(anchor: issue.getAnchor())
                //issue.update()
                let updatedAnchor=issue.getAnchor()
                
                //session.arSession.delegate?.session?(session.arSession, didUpdate: [updatedAnchor])
                //detectedIssues[issue.identifier]=issue
                print("Issue with type "+issue.category.rawValue+" is updated")
                let anchors=session.arSession.currentFrame?.anchors
                print(session.arSession.currentFrame?.anchors)
            }
            else{
                detectedIssues[issue.identifier]=issue
                //Add anchor
                let anchor=issue.getAnchor()
                print("Before adding")
                print(anchor)
                print(session.arSession.currentFrame?.anchors)
                //session.arSession.add(anchor:ARAnchor(anchor: anchor))
                session.arSession.add(anchor: anchor)
                print("Issue with type "+issue.category.rawValue+" is added")
                print("After adding")
                let anchors=session.arSession.currentFrame?.anchors
                print(session.arSession.currentFrame?.anchors)
            }
        }
//        for (id,issue) in detectedIssues{
//            //Remove issues not updated. Those are disappearing issues
//            if issue.updated==false{
//                detectedIssues[id]=nil
//                //Remove anchor
//                //session.arSession.remove(anchor: issue.getAnchor())
//                print("Issue with type "+issue.category.rawValue+" is deleted")
//            }
//        }
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
