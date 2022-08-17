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
    public func getCategoryName()->String{
        return self.detectedObjectCategory.rawValue
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
            //TODO: find a way to figure out which direction is depth. Probably need to use geometric methods like plane detetion or mass center finding
            return Double(dimensions.x)
        case "Radius":
            //TODO: find a way to figure out radius. Probably need to use
            return Double(dimensions.x)
        default:
            print("Non-implemented situation")
        }
        
        if measurement=="Height"{
            return Double(dimensions.y)
        }
        else{
            fatalError("Unexpected diension name")
        }
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
        case "Height":
            return Double(dimensions.y)
        case "Depth":
            //TODO: find a way to figure out which direction is depth. Probably need to use geometric methods like plane detetion or mass center finding
            return Double(dimensions.x)
        case "Radius":
            //TODO: find a way to figure out radius. Probably need to use
            return Double(dimensions.x)
        default:
            print("Non-implemented situation")
        }
        
        if measurement=="Height"{
            return Double(dimensions.y)
        }
        else{
            fatalError("Unexpected diension name")
        }
    }
}

