//
//  RoomObjectClasses.swift
//  RetroAccess App
//
//  Created by Xia Su on 8/16/22.
//

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
    case Medication="Medication",Rug="Rug",GrabBar="Grab Bar"
    case SmokeAlarm="Smoke Alarm",ElectricSocket="Electric Socket",Telephone="Telephone",Switch="Switch"
    case Doorhandle="Door Handle",Knife="Knife",Scissors="Scissors"
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
    public var transform:simd_float4x4{
        centerTransform
    }
    public var position: simd_float3 {
        centerPosition
    }
    public var notifier:NotifyingEntity{
        notifyingObject
    }
    //public private(set) var dimensions: simd_float3
    public private(set) var detectedObjectCategory: ODCategory
    private let detectedObjectIdentifier: UUID
    private var detectedObjectAnchors: [DetectedObjectAnchor]
    private var centerPosition:simd_float3
    private var centerTransform:simd_float4x4
    private var notifyingObject:NotifyingEntity
    public var valid:Bool=false
    public init(anchor:DetectedObjectAnchor)
    {
        detectedObjectIdentifier=anchor.identifier
        detectedObjectAnchors=[DetectedObjectAnchor]()
        detectedObjectAnchors.append(anchor)
        detectedObjectCategory=anchor.category!
        centerTransform=anchor.transform
        centerPosition=simd_make_float3(centerTransform.columns.3.x, centerTransform.columns.3.y, centerTransform.columns.3.z)
        notifyingObject=NotifyingEntity(anchor: anchor)
        //TODO: figure out how to calculate dimensions from image bbox and object distance to camera
        //dimensions=simd_make_float3(0, 0, 0)
    }
    
    //This function compares this object anchor with the other, in order to know if they are related to same item
    public func compare(object:DetectedObject)->Bool{
        
        fatalError("Unimplemented function")
    }
    
    //If 2 objects are related to a same item, just merge them. Notice that the object as parameter is the one being merged
    public func merge(object:DetectedObjectAnchor)->Bool{
        //TODO: compare 2 objects by their transform, category, and potentially dimension
        if object.category==detectedObjectCategory{
            if calculateDistance(centerPos: centerPosition, transform: object.transform)<Settings.instance.detectedObjectMergeThreshold{
                detectedObjectAnchors.append(object)
                if detectedObjectAnchors.count==Settings.instance.detectedObjectAnchorCountThreshold{
                    tellValidity()
                }
                calculateCenterPosition()
                return true
            }
        }
        return false
    }
    public func expel(object:DetectedObjectAnchor)->Bool{
        //This function determines if a new anchor should be expelled by this object.
        //If this object is valid (has many anchors), and close enough to anchor, and has different class
        if valid{
            if object.category != detectedObjectCategory{
                if calculateDistance(centerPos: centerPosition, transform: object.transform)<Settings.instance.detectedObjectMergeThreshold{
                    return true
                }
            }
        }
        return false
    }
    public func getDimension(measurement:String)->Double{
//        if measurement=="Height"{
//            return Double(dimensions.y)
//        }
//        else{
//            fatalError("Unexpected diension name")
//        }
        fatalError("OD object dimension not implemented yet!")
    }
    public func getCategoryName()->String{
        return self.detectedObjectCategory.rawValue
    }
    public func calculateDistance(centerPos:simd_float3,transform:simd_float4x4)->Float{
        let x=centerPos.x-transform.columns.3.x
        let y=centerPos.y-transform.columns.3.y
        let z=centerPos.z-transform.columns.3.z
        //print("Distance is \(sqrt(x*x+y*y+z*z))m")
        return sqrt(x*x+y*y+z*z)
    }
    public func calculateCenterPosition()->simd_float3{
        var x:Float=0
        var y:Float=0
        var z:Float=0
        for a in detectedObjectAnchors{
            x+=a.transform.columns.3.x
            y+=a.transform.columns.3.y
            z+=a.transform.columns.3.z
        }
        x=x/Float( detectedObjectAnchors.count)
        y=y/Float(detectedObjectAnchors.count)
        z=z/Float(detectedObjectAnchors.count)
        centerPosition=simd_make_float3(x, y, z)
        //Update the transform of self and notifying object
        centerTransform.columns.3.x=x
        centerTransform.columns.3.y=y
        centerTransform.columns.3.z=z
        notifyingObject.updateTransform(transform: centerTransform)
        return centerPosition
    }
    public func tellValidity(){
        if detectedObjectAnchors.count < Settings.instance.detectedObjectAnchorCountThreshold{
            fatalError("Unexpected error!")
        }
        //TODO: use scene context to understand if this item is placed right
        valid=true
        //notifyingObject.show()
    }
    public func getPosition(measurement:String)->Float{
        switch measurement{
        case "Height":
            return centerPosition.y-Settings.instance.replicator!.getFloorHeight()
        default:
            fatalError("Non-Implemented situation")
        }
    }
}
extension DetectedObject:Encodable{
    enum CodingKeys: String, CodingKey {
            case category
            case identifier
            case position
        case valid
        }
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(getCategoryName(), forKey: .category)
            try container.encode(identifier, forKey: .identifier)
            try container.encode(centerPosition, forKey: .position)
            try container.encode(valid, forKey: .valid)
        }
}
public class DetectedObjectAnchor:ARAnchor{
//    public override var identifier: UUID {
//        detectedObjectIdentifier!
//    }

//    public override var transform: simd_float4x4 {
//        detectedObjectTransform!
//    }

    //public private(set) var dimensions: simd_float3
    public private(set) var category: ODCategory?
    public var ODRect:CGRect?
    public var detectedObjectIdentifier: UUID?
    //private var detectedObjectTransform: simd_float4x4?

    public init(anchor: ARAnchor,rect:CGRect,cat:String,identifier:UUID) {

        detectedObjectIdentifier = identifier
        //detectedObjectTransform = anchor.transform
        //dimensions = anchor.dimensions
        ODRect=rect
        category = ODCategory(rawValue: cat)

        super.init(anchor: anchor)
    }
    public required init(anchor: ARAnchor) {
//        fatalError("This constructor is not supposed to be used")
//        detectedObjectIdentifier = nil
//        detectedObjectTransform = nil
        super.init(anchor: anchor)
    }
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("Unavailable")
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
    public let roomObjectExtraIdentifier:UUID

    public required init(anchor: ARAnchor) {
        guard let anchor = anchor as? RoomObjectAnchor else {
            fatalError("RoomObjectAnchor can only copy other RoomObjectAnchor instances")
        }

        roomObjectIdentifier = anchor.roomObjectIdentifier
        roomObjectTransform = anchor.roomObjectTransform
        dimensions = anchor.dimensions
        category = anchor.category
        roomObjectExtraIdentifier = UUID.init()
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
        roomObjectExtraIdentifier = UUID.init()
        super.init(transform: object.transform)
    }

    public func update(_ object: CapturedRoom.Object) {
        roomObjectTransform = object.transform
        dimensions = object.dimensions
        category = object.category
    }
    public func getDimension(measurement:String)->Double{
        switch measurement{
        case "Height":
            return Double(dimensions.y)
        case "Depth":
            //TODO: find a way to figure out which direction is depth. Probably need to use geometric methods like plane detetion or mass center finding. Now just return the smallest dim of x and y
            return min(Double(dimensions.x), Double(dimensions.z))
        default:
            fatalError("Non-implemented situation")
        }
    }
    public func getSpecificPosition(measurement:String)->Float{
        switch measurement{
        case "Height":
            if category == .sink{
                return transform.columns.3.y-Settings.instance.replicator!.getFloorHeight()+dimensions.y/2
            }
            else{
                return transform.columns.3.y-Settings.instance.replicator!.getFloorHeight()-dimensions.y/2
            }
        default:
            fatalError("Wrong case given!")
        }
    }
    public func getFullPosition()->simd_float3{
        return simd_float3(x: transform.columns.3.x, y: transform.columns.3.y, z: transform.columns.3.z)
    }
    public func getCategoryName()->String{
        switch category {
        case .storage: return "storage"
        case .refrigerator: return "refrigerator"
        case .stove: return "stove"
        case .bed: return "bed"
        case .sink:  return "sink"
//        case .washerDryer: return SimpleMaterial(color: .systemPurple, roughness: roughness, isMetallic: false)
        case .toilet: return "toilet"
        case .bathtub: return "bathtub"
        case .oven: return "oven"
        case .dishwasher: return "dishwasher"
        case .table: return "table"
        case .sofa: return "sofa"
        case .chair: return "chair"
        case .fireplace: return "fireplace"
//        case .television: return SimpleMaterial(color: .systemGray3, roughness: roughness, isMetallic: false)
        case .stairs: return "stairs"
        @unknown default:
            return "unknown"
            //fatalError()
        }
    }
    public func getDescription()->String{
        var result=getCategoryName()
        result.capitalizeFirstLetter()
        result+=" detected with dimension of "
        result+=dimensions.toString()
        return result
    }
}
extension RoomObjectAnchor:Encodable{
    enum CodingKeys: String, CodingKey {
            case category
            case dimensions
            case identifier
            case transform
        }
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(getCategoryName(), forKey: .category)
            try container.encode(dimensions, forKey: .dimensions)
            try container.encode(identifier, forKey: .identifier)
            try container.encode(roomObjectTransform, forKey: .transform)
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
    public func getCategoryName()->String{
        switch category {
        case .door(isOpen: true): return "door"
        case .door(isOpen: false): return "door"
        case .opening: return "opening"
        case .wall: return "wall"
        case .window: return "window"
        @unknown default:
            return "unknown"
            //fatalError()
        }
    }
    public func getDimension(measurement:String)->Double{
        switch measurement{
        case "Radius":
            return max(Double(dimensions.x), Double(dimensions.z))
        default:
            fatalError("Non-implemented situation")
        }
    }
    public func getFullPosition(measurement:String)->Float{
        switch measurement{
        case "Height":
            return transform.columns.3.y-Settings.instance.replicator!.getFloorHeight()
        default:
            fatalError("Non-implemented situation")
        }
    }
    public func getFullPosition()->simd_float3{
        return simd_float3(x: transform.columns.3.x, y: transform.columns.3.y, z: transform.columns.3.z)
    }
    public func getDescription()->String{
        var result=getCategoryName()
        result.capitalizeFirstLetter()
        result+=" detected with dimension of "
        result += dimensions.toString()
        return result
    }
}
extension RoomSurfaceAnchor:Encodable{
    enum CodingKeys: String, CodingKey {
            case category
            case dimensions
            case identifier
            case transform
        }
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(getCategoryName(), forKey: .category)
            try container.encode(dimensions, forKey: .dimensions)
            try container.encode(identifier, forKey: .identifier)
            try container.encode(roomSurfaceTransform, forKey: .transform)
        }
}
extension simd_float4x4: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        try self.init(container.decode([SIMD4<Float>].self))
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode([columns.0,columns.1, columns.2, columns.3])
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}

extension simd_float3{
    func toString()->String{
        let x=roundf(self.x*100)/100.0
        let y=roundf(self.y*100)/100.0
        let z=roundf(self.z*100)/100.0
        return "\nLength : \(x) m Height : \(y) m Width : \(z)m"
    }
}
