//
//  NotifyingEntity.swift
//  RetroAccess App
//
//  Created by Xia Su on 8/3/22.
//

import Foundation
import RealityFoundation
import RoomPlan
import ARKit

public class NotifyingEntity: Entity, HasAnchoring, HasModel{

    public var anchoring: AnchoringComponent? {
        get { components[AnchoringComponent.self] }
        set { components[AnchoringComponent.self] = newValue }
    }

    //assign texture to anchor
    public var model: ModelComponent? {
        get { components[ModelComponent.self] }
        set { components[ModelComponent.self] = newValue }
    }

    public required convenience init() {
        self.init(dimensions: .zero)
    }

    public convenience init(roomObjectAnchor: RoomObjectAnchor) {
        self.init(dimensions: simd_float3.init(x: 0.3, y: 0.3, z: 0.3))
        //components.set([AnchoringComponent(roomObjectAnchor)])
        self.transform=Transform(matrix: roomObjectAnchor.transform)
    }
    public convenience init(anchor: ARAnchor,dim:Float=0.3) {
        
        self.init(dimensions: simd_float3.init(x: dim, y:dim, z: dim))
        //components.set([AnchoringComponent(anchor)])
        self.transform=Transform(matrix: anchor.transform)
    }

    public init(dimensions: simd_float3, category: CapturedRoom.Object.Category? = nil) {
        super.init()
//        let mesh = MeshResource.generateSphere(radius: 0.05)
//        let material = SimpleMaterial(color: .systemRed, roughness: 0.27, isMetallic: false)
//        let model = ModelComponent(mesh: mesh, materials: [material])
//        components.set([model])
    }
    public func updateTransform(transform: simd_float4x4){
        self.transform=Transform(matrix: transform)
    }
    public func show(){
        let mesh = MeshResource.generateSphere(radius: 0.05)
        let material = SimpleMaterial(color: .systemRed, roughness: 0.80, isMetallic: false)
        let model = ModelComponent(mesh: mesh, materials: [material])
        components.set([model])
    }
}
