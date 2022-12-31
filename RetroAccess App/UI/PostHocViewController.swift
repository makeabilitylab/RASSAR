//
//  SCNViewController.swift
//  RetroAccess App
//
//  Created by Xia Su on 12/16/22.
//

import Foundation
import SceneKit
import SwiftUI

class PostHocViewController:UIViewController{
    private let sceneView: SCNView = .init(frame: .zero)
    private let scene = RoomScene(room: Settings.instance.replicator!)
    private var sceneScale:Float=1
    var sideTapped: ((Int) -> Void)?
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sceneView)
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        sceneView.scene = scene
        let panRecognizer = UIPanGestureRecognizer(target: self,action: #selector(self.panGesture(_:)))
        sceneView.addGestureRecognizer(panRecognizer)
        //Xia tried to add a double tap recognizer but failed.
//        let doubleTapRecognizer = UITapGestureRecognizer(target: self,action: #selector(self.doubleTapGesture(_:)))
//        doubleTapRecognizer.numberOfTapsRequired = 2
//        sceneView.addGestureRecognizer(doubleTapRecognizer)
        let singleTapRecognizer = UITapGestureRecognizer(target: self,action: #selector(self.singleTapGesture(_:)))
        singleTapRecognizer.numberOfTapsRequired = 1
        sceneView.addGestureRecognizer(singleTapRecognizer)
        let pinchRecognizer = UIPinchGestureRecognizer(target: self,action: #selector(self.pinchGesture(_:)))
        sceneView.addGestureRecognizer(pinchRecognizer)
    }
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//            guard let touchPoint = touches.first?.location(in: sceneView) else { return }
//            guard let hitTestResult = sceneView.hitTest(touchPoint, options: nil).first else { return }
//            guard hitTestResult.node is BoxNode else { return }
//        print(hitTestResult.geometryIndex)
//        }
    @objc func panGesture(_ gesture: UIPanGestureRecognizer){
        let translation = gesture.translation(in: gesture.view!)
        let x = Float(translation.x)
        let y = Float(-translation.y)
        let anglePan = sqrt(pow(x,2)+pow(y,2))*(Float)(Double.pi)/180.0
        var rotationVector = SCNVector4()
        rotationVector.x = -y
        rotationVector.y = x
        rotationVector.z = 0
        rotationVector.w = anglePan
        scene.geometryNode!.rotation = rotationVector
        //geometryNode.transform = SCNMatrix4MakeRotation(anglePan, -y, x, 0)

        if(gesture.state == UIGestureRecognizer.State.ended) {
            let currentPivot = scene.geometryNode!.pivot
            let changePivot = SCNMatrix4Invert( scene.geometryNode!.transform)
            scene.geometryNode!.pivot = SCNMatrix4Mult(changePivot, currentPivot)
            scene.geometryNode!.transform = SCNMatrix4Identity
        }
    }
    @objc func singleTapGesture(_ gesture: UITapGestureRecognizer){
        if(gesture.state == UIGestureRecognizer.State.ended) {
            if(gesture.numberOfTouches == 1){
                let position=gesture.location(in: sceneView)
                guard let hitTestResult = sceneView.hitTest(position, options: nil).first else { return }
                guard hitTestResult.node is BoxNode else { return }
                print("Single Tap on box!")
                print(hitTestResult.geometryIndex)
            }
        }
    }
    @objc func doubleTapGesture(_ gesture: UITapGestureRecognizer){
        if(gesture.state == UIGestureRecognizer.State.ended) {
            if(gesture.numberOfTouches == 2){
                let position=gesture.location(in: sceneView)
                guard let hitTestResult = sceneView.hitTest(position, options: nil).first else { return }
                guard hitTestResult.node is BoxNode else { return }
                print("Double Tap on box!")
                print(hitTestResult.geometryIndex)
            }
        }
    }
    @objc func pinchGesture(_ gesture: UIPinchGestureRecognizer){
        let scale = gesture.scale
        scene.geometryNode!.scale.x=Float(scale)*sceneScale
        scene.geometryNode!.scale.y=Float(scale)*sceneScale
        scene.geometryNode!.scale.z=Float(scale)*sceneScale
        if(gesture.state == UIGestureRecognizer.State.ended) {
            let scale = gesture.scale
            sceneScale=Float(scale)
        }
    }
}
//class GameScene: SCNScene {
//    var geometryNode:SCNNode?
//    override init() {
//        super.init()
//
//        let cubeNode = BoxNode()
//        geometryNode=cubeNode
//        self.rootNode.addChildNode(cubeNode)
//        let sphereNode=BallNode()
//        geometryNode!.addChildNode(sphereNode)
//        let xAngle = SCNMatrix4MakeRotation(.pi / 3.8, 1, 0, 0)
//        let zAngle = SCNMatrix4MakeRotation(-.pi / 4, 0, 0, 1)
//        cubeNode.pivot = SCNMatrix4Mult(SCNMatrix4Mult(xAngle, zAngle), cubeNode.transform)
//
//        // Rotate the cube
//        let animation = CAKeyframeAnimation(keyPath: "rotation")
//        animation.values = [SCNVector4(1, 1, 0.3, 0 * .pi),
//                            SCNVector4(1, 1, 0.3, 1 * .pi),
//                            SCNVector4(1, 1, 0.3, 2 * .pi)]
//        animation.duration = 5
//        animation.repeatCount = HUGE
//        //cubeNode.addAnimation(animation, forKey: "rotation")
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
class RoomScene: SCNScene {
    var geometryNode:SCNNode?
    var replicator:RoomObjectReplicator
    init(room:RoomObjectReplicator) {
        replicator=room
        super.init()
        let floorNode = BoxNode(type: .floor, sourceObject: nil, sourceSurface: nil)
        floorNode.position.y=replicator.getFloorHeight()
        floorNode.position.x=replicator.getFloorHeight()
        floorNode.position.z=replicator.getFloorHeight()
        geometryNode=floorNode
        self.rootNode.addChildNode(floorNode)
        //Add all objects into the room
        for object in replicator.trackedObjectAnchors{
            let objectNode=BoxNode(type: .furniture, sourceObject: object, sourceSurface: nil)
            floorNode.addChildNode(objectNode)
        }
        for surface in replicator.trackedSurfaceAnchors{
            switch surface.category{
            case .window:
                let surfaceNode=BoxNode(type: .window, sourceObject: nil, sourceSurface: surface)
                floorNode.addChildNode(surfaceNode)
            case .wall:
                let surfaceNode=BoxNode(type: .wall, sourceObject: nil, sourceSurface: surface)
                floorNode.addChildNode(surfaceNode)
            case .opening:
                let surfaceNode=BoxNode(type: .opening, sourceObject: nil, sourceSurface: surface)
                floorNode.addChildNode(surfaceNode)
            case .door(isOpen: true):
                let surfaceNode=BoxNode(type: .opening, sourceObject: nil, sourceSurface: surface)
                floorNode.addChildNode(surfaceNode)
            case .door(isOpen:false):
                let surfaceNode=BoxNode(type: .opening, sourceObject: nil, sourceSurface: surface)
                floorNode.addChildNode(surfaceNode)
            }
            
        }
        //let sphereNode=BallNode()
        //geometryNode!.addChildNode(sphereNode)
        let xAngle = SCNMatrix4MakeRotation(.pi / 3.8, 1, 0, 0)
        let zAngle = SCNMatrix4MakeRotation(-.pi / 4, 0, 0, 1)
        //geometryNode!.pivot = SCNMatrix4Mult(SCNMatrix4Mult(xAngle, zAngle), geometryNode!.transform)
        
        // Rotate the cube
//        let animation = CAKeyframeAnimation(keyPath: "rotation")
//        animation.values = [SCNVector4(1, 1, 0.3, 0 * .pi),
//                            SCNVector4(1, 1, 0.3, 1 * .pi),
//                            SCNVector4(1, 1, 0.3, 2 * .pi)]
//        animation.duration = 5
//        animation.repeatCount = HUGE
        //cubeNode.addAnimation(animation, forKey: "rotation")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
struct PostHocView: View {
    var body: some View {
        //VStack {
            //SceneView(scene: SCNScene(named: "3dObjects/lowpoly.scn"), options: [.autoenablesDefaultLighting, .allowsCameraControl])
            //View()
            
        //}
        Text("PostHocView")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PostHocView()
    }
}

class BoxNode: SCNNode {
    var sourceRoomPlanObject:RoomObjectAnchor?
    var sourceRoomPlanSurface:RoomSurfaceAnchor?
    init(type:BoxNodeTypes,sourceObject:RoomObjectAnchor?,sourceSurface:RoomSurfaceAnchor?) {
        switch type{
        case .floor:
            //Create a dark gray floor which is big enough to contain all indoor space
            let box = SCNBox(width: 0, height: 0, length: 0, chamferRadius: 0)
            box.materials = [UIColor.white].map {
                let material = SCNMaterial()
                material.diffuse.contents = $0
                material.isDoubleSided = true
                material.transparencyMode = .aOne
                return material
            }
            super.init()
            self.geometry = box
            self.name = "floorNode"
            return
        case .furniture:
            //Create a light gray box using the position and size provided by room object anchor
            sourceRoomPlanObject=sourceObject
            let dimension=sourceRoomPlanObject!.dimensions
            let box = SCNBox(width: CGFloat(dimension.x), height: CGFloat(dimension.y), length: CGFloat(dimension.z), chamferRadius: 0)
            box.materials = [UIColor.lightGray].map {
                let material = SCNMaterial()
                material.diffuse.contents = $0
                material.isDoubleSided = true
                material.transparencyMode = .aOne
                return material
            }
            super.init()
            self.geometry = box
            self.name = "furnitureNode"
            self.transform=SCNMatrix4(sourceRoomPlanObject!.transform)
            return
        case .opening:
            //Create a dark gray box using the position and size provided by room surface anchor
            sourceRoomPlanSurface=sourceSurface
            let dimension=sourceRoomPlanSurface!.dimensions
            let box = SCNBox(width: CGFloat(dimension.x+0.05), height: CGFloat(dimension.y+0.05), length: CGFloat(dimension.z+0.05), chamferRadius: 0)
            box.materials = [UIColor.darkGray].map {
                let material = SCNMaterial()
                material.diffuse.contents = $0
                material.isDoubleSided = true
                material.transparencyMode = .aOne
                return material
            }
            super.init()
            self.geometry = box
            self.name = "furnitureNode"
            self.transform=SCNMatrix4(sourceRoomPlanSurface!.transform)
            return
        case .wall:
            //create a white gray box using the position and size provided by room surface anchor
            sourceRoomPlanSurface=sourceSurface
            let dimension=sourceRoomPlanSurface!.dimensions
            let box = SCNBox(width: CGFloat(dimension.x), height: CGFloat(dimension.y), length: CGFloat(dimension.z), chamferRadius: 0)
            box.materials = [UIColor.lightGray].map {
                let material = SCNMaterial()
                material.diffuse.contents = $0
                material.isDoubleSided = true
                material.transparencyMode = .aOne
                return material
            }
            super.init()
            self.geometry = box
            self.name = "furnitureNode"
            self.transform=SCNMatrix4(sourceRoomPlanSurface!.transform)
            return
        case .window:
            //create a light blue box using the position and size provided by room surface anchor
            sourceRoomPlanSurface=sourceSurface
            let dimension=sourceRoomPlanSurface!.dimensions
            let box = SCNBox(width: CGFloat(dimension.x+0.05), height: CGFloat(dimension.y+0.05), length: CGFloat(dimension.z+0.05), chamferRadius: 0)
            box.materials = [UIColor(hue: 0.5417, saturation: 0.47, brightness: 0.89, alpha: 1.0) /* #78c8e2 */].map {
                let material = SCNMaterial()
                material.diffuse.contents = $0
                material.isDoubleSided = true
                material.transparencyMode = .aOne
                return material
            }
            super.init()
            self.geometry = box
            self.name = "furnitureNode"
            self.transform=SCNMatrix4(sourceRoomPlanSurface!.transform)
            return
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
enum BoxNodeTypes{
    case floor, wall, window,opening,furniture
}
//Ball node is used to indicate issues
class BallNode: SCNNode {
    var sourceIssue:AccessibilityIssue!
    init(issue:AccessibilityIssue) {
        super.init()
        sourceIssue=issue
        self.geometry = SCNSphere(radius: 0.5)
        self.geometry!.materials = [UIColor.red].map {
            let material = SCNMaterial()
            material.diffuse.contents = $0
            material.isDoubleSided = true
            material.transparencyMode = .aOne
            return material
        }
        self.name = "sphereNode"
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

