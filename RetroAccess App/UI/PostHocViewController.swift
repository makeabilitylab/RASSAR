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
    private let sceneView: SCNView = .init(frame: .zero) //This view is the container for 3D model viewing
    private let infoView:UIView = .init(frame: .zero) //This view is the container for info details
    private let scene = RoomScene(room: Settings.instance.replicator!)
    private var sceneScale:Float=1
    private var panState=0
    private var translateX:Float=0
    private var translateY:Float=0
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sceneView)
        view.addSubview(infoView)
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
        ])
        sceneView.scene = scene
        NSLayoutConstraint.activate([
            infoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            infoView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            infoView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            infoView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        infoView.backgroundColor=UIColor.systemGray
        
        let panRecognizer = UIPanGestureRecognizer(target: self,action: #selector(self.panGesture(_:)))
        panRecognizer.maximumNumberOfTouches=1
        sceneView.addGestureRecognizer(panRecognizer)
        let moveRecognizer = UIPanGestureRecognizer(target: self,action: #selector(self.moveGesture(_:)))
        moveRecognizer.minimumNumberOfTouches=2
        moveRecognizer.maximumNumberOfTouches=2
        sceneView.addGestureRecognizer(moveRecognizer)
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
    @objc func panGesture(_ gesture: UIPanGestureRecognizer){
        let translation = gesture.translation(in: gesture.view!)
        let x = Float(translation.x)
        let y = Float(-translation.y)
        if(panState==0){
            if(x*x>=y*y/2){
                panState=1
            }
            else{
                panState=2
            }
        }
        if(panState==1){
            let anglePan = sqrt(pow(x,2))*(Float)(Double.pi)/180.0
            var rotationVector = SCNVector4()
            rotationVector.x = 0
            rotationVector.y = x
            rotationVector.z = 0
            rotationVector.w = anglePan
            scene.geometryNode!.rotation = rotationVector
        }
        if(panState==2){
            let anglePan = sqrt(pow(y,2))*(Float)(Double.pi)/180.0
            var rotationVector = SCNVector4()
            rotationVector.x = -y
            rotationVector.y = 0
            rotationVector.z = 0
            rotationVector.w = anglePan
            scene.geometryNode!.rotation = rotationVector
        }

        if(gesture.state == UIGestureRecognizer.State.ended) {
            let currentPivot = scene.geometryNode!.pivot
            let changePivot = SCNMatrix4Invert( scene.geometryNode!.transform)
            scene.geometryNode!.pivot = SCNMatrix4Mult(changePivot, currentPivot)
            scene.geometryNode!.transform = SCNMatrix4Identity
            panState=0
        }
    }
    @objc func moveGesture(_ gesture: UIPanGestureRecognizer){
        let translation = gesture.translation(in: gesture.view!)
        let x = Float(translation.x/200)
        let y = Float(-translation.y/200)
        scene.geometryNode!.localTranslate(by: SCNVector3(x-translateX, y-translateY,0))
        translateX=x
        translateY=y
        //geometryNode.transform = SCNMatrix4MakeRotation(anglePan, -y, x, 0)

        if(gesture.state == UIGestureRecognizer.State.ended) {
            translateX=0
            translateY=0
        }
    }
    @objc func singleTapGesture(_ gesture: UITapGestureRecognizer){
        if(gesture.state == UIGestureRecognizer.State.ended) {
            if(gesture.numberOfTouches == 1){
                let position=gesture.location(in: sceneView)
                guard let hitTestResult = sceneView.hitTest(position, options: nil).first else { return }
                guard hitTestResult.node is BoxNode else { return }
                if let box = hitTestResult.node as? BoxNode{
                    print(box.getSourceClass())
                    //Try to show the information here!
                    updateInfoView(sourceObject:box,sourceIssue:nil)
                }
            }
        }
    }
//    @objc func doubleTapGesture(_ gesture: UITapGestureRecognizer){
//        if(gesture.state == UIGestureRecognizer.State.ended) {
//            if(gesture.numberOfTouches == 2){
//                let position=gesture.location(in: sceneView)
//                guard let hitTestResult = sceneView.hitTest(position, options: nil).first else { return }
//                guard hitTestResult.node is BoxNode else { return }
//                print("Double Tap on box!")
//                print(hitTestResult.geometryIndex)
//            }
//        }
//    }
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
    func updateInfoView(sourceObject:BoxNode?,sourceIssue:BallNode?){
        //TODO: Add code here to generate detail view for source object. Use InfoView as container
        
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
        let rootNode=BoxNode(type: .root, sourceObject: nil, sourceSurface: nil)
        geometryNode=rootNode
        self.rootNode.addChildNode(rootNode)
        let floorNode = BoxNode(type: .floor, sourceObject: nil, sourceSurface: nil)
        floorNode.position.y=replicator.getFloorHeight()
        //floorNode.position.x=replicator.getFloorHeight()
        //floorNode.position.z=replicator.getFloorHeight()
        rootNode.addChildNode(floorNode)
        let ambientLightNode = SCNNode()
            ambientLightNode.light = SCNLight()
            ambientLightNode.light!.type = .ambient
            ambientLightNode.light!.color = UIColor(white: 0.70, alpha: 1.0)

            // Add ambient light to scene
        rootNode.addChildNode(ambientLightNode)
        //Add all objects into the room
        for object in replicator.trackedObjectAnchors{
            let objectNode=BoxNode(type: .furniture, sourceObject: object, sourceSurface: nil)
            rootNode.addChildNode(objectNode)
        }
        for surface in replicator.trackedSurfaceAnchors{
            switch surface.category{
            case .window:
                let surfaceNode=BoxNode(type: .window, sourceObject: nil, sourceSurface: surface)
                rootNode.addChildNode(surfaceNode)
            case .wall:
                let surfaceNode=BoxNode(type: .wall, sourceObject: nil, sourceSurface: surface)
                rootNode.addChildNode(surfaceNode)
            case .opening:
                let surfaceNode=BoxNode(type: .opening, sourceObject: nil, sourceSurface: surface)
                rootNode.addChildNode(surfaceNode)
            case .door(isOpen: true):
                let surfaceNode=BoxNode(type: .opening, sourceObject: nil, sourceSurface: surface)
                rootNode.addChildNode(surfaceNode)
            case .door(isOpen:false):
                let surfaceNode=BoxNode(type: .opening, sourceObject: nil, sourceSurface: surface)
                rootNode.addChildNode(surfaceNode)
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


class BoxNode: SCNNode {
    var sourceRoomPlanObject:RoomObjectAnchor?
    var sourceRoomPlanSurface:RoomSurfaceAnchor?
    var nodeType:BoxNodeTypes
    init(type:BoxNodeTypes,sourceObject:RoomObjectAnchor?,sourceSurface:RoomSurfaceAnchor?) {
        nodeType=type
        switch type{
        case .root:
            //Create a dark gray floor which is big enough to contain all indoor space
            let box = SCNBox(width: 0, height: 0, length: 0, chamferRadius: 0)
            box.materials = [UIColor.systemGray2].map {
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
        case .floor:
            //Create a dark gray floor which is big enough to contain all indoor space
            let box = SCNCylinder(radius: 10, height: 0.1)
            box.materials = [UIColor.systemGray2].map {
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
            box.materials = [UIColor.systemGray].map {
                let material = SCNMaterial()
                material.diffuse.contents = $0
                material.isDoubleSided = true
                material.transparencyMode = .aOne
                //material.fillMode = .lines
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
    func getSourceClass()->String{
        switch nodeType{
        case .root:
            return "Root"
        case .floor:
            return "Floor"
        case .furniture:
            return sourceRoomPlanObject!.getCategoryName()
        case .opening:
            return "opening"
        case .window:
            return "window"
        case .wall:
            return "wall"
        }
    }
}
enum BoxNodeTypes{
    case root,floor, wall, window,opening,furniture
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

