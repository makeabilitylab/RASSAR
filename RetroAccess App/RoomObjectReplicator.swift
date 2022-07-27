import ARKit
import RoomPlan

public enum DetectedCategory{
    case ElectricCords;
}
public class DetectedObject{
    public var identifier: UUID {
        detectedObjectIdentifier
    }

    public var transform: simd_float4x4 {
        getCenterPosition()
    }
    public private(set) var dimensions: simd_float3
    public private(set) var detectedObjectCategory: DetectedCategory
    private let detectedObjectIdentifier: UUID
    private var detectedObjectTransform: [simd_float4x4]
    
    public init(category:DetectedCategory,transform:simd_float4x4)
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
    
    private var detectedIssues:[AccessibilityIssue]
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
        
        detectedIssues=[]
        filter=nil
        filter=Filter(replicator: self)
    }

    public func anchor(objects: [CapturedRoom.Object],surfaces:[CapturedRoom.Surface] ,in session: RoomCaptureSession) {
        //TODO: still need to add OD objects in this flow. Also, remember to call this function when getting OD results.
        for object in objects {
            if let existingAnchor = trackedObjectAnchorsByIdentifier[object.identifier] {
                existingAnchor.update(object)
                inflightObjectAnchors.insert(existingAnchor)
                session.arSession.delegate?.session?(session.arSession, didUpdate: [existingAnchor])
            } else {
                let anchor = RoomObjectAnchor(object)
                inflightObjectAnchors.insert(anchor)
                session.arSession.add(anchor: anchor)
            }
        }
        for surface in surfaces {
            if let existingAnchor = trackedSurfaceAnchorsByIdentifier[surface.identifier] {
                existingAnchor.update(surface)
                inflightSurfaceAnchors.insert(existingAnchor)
                session.arSession.delegate?.session?(session.arSession, didUpdate: [existingAnchor])
            } else {
                let anchor = RoomSurfaceAnchor(surface)
                inflightSurfaceAnchors.insert(anchor)
                session.arSession.add(anchor: anchor)
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

}
