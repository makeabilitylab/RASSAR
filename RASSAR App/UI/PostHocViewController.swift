//
//  SCNViewController.swift
//  RetroAccess App
//
//  Created by Xia Su on 12/16/22.
//

//TODO list:
//Adjust the issue sphere size and position
//Prettify the information showing for post-hoc view
//Add more detailed information showing

import Foundation
import SceneKit
import SwiftUI

class PostHocViewController:UIViewController{
//This VC shows 3D model and detailed information of scanned room.
    private let sceneView: SCNView = .init(frame: .zero) //This view is the container for 3D model viewing
    private let infoView:UIView = .init(frame: .zero) //This view is the container for info details
    private let scene = RoomScene(room: Settings.instance.replicator!)
    private var sceneScale:Float=1
    private var panState=0
    private var translateX:Float=0
    private var translateY:Float=0
    let screenSize: CGRect = UIScreen.main.bounds
    private var selectedIssue:AccessibilityIssue?
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled=true
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
        sceneView.backgroundColor=UIColor.lightGray
        infoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            infoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            infoView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            infoView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            infoView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        infoView.backgroundColor=UIColor.white
        updateInfoView(sourceObject: nil, sourceIssue: nil)
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
        if let path = Bundle.main.path(forResource: "NodeTechnique", ofType: "plist") {
            if let dict = NSDictionary(contentsOfFile: path)  {
                let dict2 = dict as! [String : AnyObject]
                let technique = SCNTechnique(dictionary:dict2)

                // set the glow color to yellow
                let color = SCNVector3(1.0, 1.0, 0.0)
                technique?.setValue(NSValue(scnVector3: color), forKeyPath: "glowColorSymbol")

                sceneView.technique = technique
            }
        }
        
        //Add an export button
        let exportButton=UIButton()
        exportButton.frame=CGRect(x: screenSize.width-80, y: 30, width: 50, height: 50)
        exportButton.addTarget(self, action: #selector(btnExportData), for: .touchUpInside)
        let buttonShapeView=UIView()
        buttonShapeView.isUserInteractionEnabled=false
        buttonShapeView.frame=CGRect(x: 0, y: 0, width: 56, height: 56)
        let circleLayer = CAShapeLayer()
        let radius: CGFloat = 28
        circleLayer.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 2.0 * radius, height: 2.0 * radius), cornerRadius: radius).cgPath
        circleLayer.frame=CGRect(x: 0, y: 0, width: 56, height: 56)
        circleLayer.fillColor = UIColor(red: 0.122, green: 0.216, blue: 0.267, alpha: 1).cgColor
        buttonShapeView.layer.addSublayer(circleLayer)
        let exportIcon=UIImage(named: "export")!.resizeImage(newSize: CGSize(width: 40, height: 40))
        let iconView=UIImageView(image: exportIcon)
        iconView.frame=CGRect(x: 8, y: 8, width: 40, height: 40)
        buttonShapeView.addSubview(iconView)
        exportButton.addSubview(buttonShapeView)
        exportButton.accessibilityLabel="Export scan results"
        self.view.addSubview(exportButton)
    }
    @objc func panGesture(_ gesture: UIPanGestureRecognizer){
        let translation = gesture.translation(in: gesture.view!)
        let x = Float(translation.x)
        let y = Float(-translation.y)
        if(panState==0 && x*x+y*y>10){
            if(x*x>=y*y){
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
                //First let every object unhighlighted
                sceneView.scene?.rootNode.setNonHighlighted()
                let position=gesture.location(in: sceneView)
                guard let hitTestResult = sceneView.hitTest(position, options: nil).first else { return }
                //guard hitTestResult.node is BoxNode else { return }
                if let box = hitTestResult.node as? BoxNode{
                    print(box.getSourceClass())
                    //Try to show the information here!
                    updateInfoView(sourceObject:box,sourceIssue:nil)
                    //box.runAction(SCNAction.levitate(distance: 0.03, duration: 2.0) )
                    box.setHighlighted()
                    if box.issue != nil{
                        selectedIssue=box.issue!
                    }
                }
                if let ball = hitTestResult.node as? BallNode{
                    print(ball.getSourceClass())
                    //Try to show the information here!
                    updateInfoView(sourceObject:nil,sourceIssue:ball)
                    //ball.runAction(SCNAction.levitate(distance: 0.03, duration: 2.0) )
                    ball.setHighlighted()
                    selectedIssue=ball.sourceIssue
                }
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
    func updateInfoView(sourceObject:BoxNode?,sourceIssue:BallNode?){
        //TODO: Add code here to generate detail view for source object. Use InfoView as container
        infoView.subviews.forEach { $0.removeFromSuperview() }
        let stack=UIStackView(frame: infoView.bounds)
        //let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        //let stack=UIStackView()
        stack.isLayoutMarginsRelativeArrangement=true
        stack.distribution = .fill
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing=10
        let title = UILabel(frame: CGRect(x: 20, y: 20, width: 400, height: 100))
        title.textColor = UIColor.black
        title.backgroundColor = UIColor.white
        title.font = UIFont.boldSystemFont(ofSize: 30.0)
        let description = UILabel()
        description.textColor = UIColor.black
        description.backgroundColor = UIColor.white
        description.lineBreakMode = .byWordWrapping
        description.frame=CGRect(x: 20, y: 70, width: 400, height: 400)
        description.numberOfLines=0
        description.textAlignment = .left
        
        //description.ContentMode=.scaleToFill
        if (sourceObject != nil){
            title.text=sourceObject!.getSourceClass()
            description.text=sourceObject!.getSourceDescription()
            if let issue = sourceObject?.issue{
                if issue.cancelled == false{
                    description.text! += "\n"
                    description.text! += issue.getDetails()
                    
    //                let cancel = UILabel(frame: CGRect(x: 20, y: 300, width: 400, height: 100))
    //                cancel.textColor = UIColor.black
    //                cancel.backgroundColor = UIColor.white
    //                cancel.font = UIFont.boldSystemFont(ofSize: 20.0)
    //                let underlineAttriString = NSAttributedString(string: "Cancel this issue",
    //                                                          attributes: [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue])
    //                cancel.attributedText=underlineAttriString
    //                infoView.addSubview(cancel)
                    let cancelButton=UIButton(frame: CGRect(x: 20, y: 300, width: 400, height: 100))
                    cancelButton.setTitle("Remove this issue", for: .normal)
                    cancelButton.addTarget(self, action: #selector(didTapCancelButton), for: .touchUpInside)
                    cancelButton.setTitleColor(UIColor(red: 0.957, green: 0.353, blue: 0.322, alpha: 1), for: .normal)
                    infoView.addSubview(cancelButton)
                }
                
            }
        }
        else if (sourceIssue != nil)
        {
            title.text=sourceIssue!.getSourceClass()
            description.text=sourceIssue!.getSourceDescription()
//            let cancel = UILabel(frame: CGRect(x: 20, y: 300, width: 400, height: 100))
//            cancel.textColor = UIColor.black
//            cancel.backgroundColor = UIColor.white
//            cancel.font = UIFont.boldSystemFont(ofSize: 20.0)
//            let underlineAttriString = NSAttributedString(string: "Cancel this issue",
//                                                      attributes: [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue])
//            cancel.attributedText=underlineAttriString
//            infoView.addSubview(cancel)
            let cancelButton=UIButton(frame: CGRect(x: 20, y: 300, width: 400, height: 100))
            cancelButton.setTitle("Remove this issue", for: .normal)
            cancelButton.setTitleColor(UIColor(red: 0.957, green: 0.353, blue: 0.322, alpha: 1), for: .normal)
            cancelButton.addTarget(self, action: #selector(didTapCancelButton), for: .touchUpInside)
            infoView.addSubview(cancelButton)
        }
        else{
            title.text = "Item Category"
            description.text = "Please tap any object or issues in 3D view to see details. The information will include object category and dimension."
        }
        title.sizeToFit()
        description.sizeToFit()
        let fullText = description.text!
        let keywordsToBold = ["Warning", "Possible Fix"]

                // Create a mutable attributed string
                let attributedString = NSMutableAttributedString(string: fullText)
            attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 14), range: NSRange(location: 0, length: fullText.count))
                // Loop through the keywords and apply bold style to each occurrence
                for keyword in keywordsToBold {
                    let range = (fullText as NSString).range(of: keyword)
                    if range.location != NSNotFound {
                        attributedString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 16), range: range)
                    }
                }

                // Set the attributed string to the UITextView
                description.attributedText = attributedString
        //stack.addArrangedSubview(title)
        
        //stack.addArrangedSubview(description)
        infoView.addSubview(title)
        infoView.addSubview(description)
    }
    @objc func btnExportData(_ sender: Any) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HHmm E, d MMM y"
        let prompt = UIAlertController(title: "Warning! The exported data might contain layout information of your home space!", message: "If you are aware of the risk, please provide file name and proceed.", preferredStyle: .alert)
        prompt.addTextField {(textField) in textField.text = formatter.string(from: Date.now)}
        prompt.addAction(UIAlertAction(title: "Export", style: .default, handler: {
            (_) in
            do {
                let jsonData = try! JSONEncoder().encode(Settings.instance.replicator!)
                let jsonString = String(data: jsonData, encoding: .utf8)!
                let data = jsonString.data(using: .utf8)!
                let fm = FileManager.default
                let fileFolder = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileURL = fileFolder.appendingPathComponent(prompt.textFields![0].text! + ".txt")
                do {
                    try data.write(to: fileURL)
                } catch {
                    print("Save failed")
                }
                let sharing = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                            sharing.completionWithItemsHandler = {
                                (type, completed, items, error) in
                                do {
                                    try fm.removeItem(at: fileURL)
                                } catch {
                                }
                            }
                            sharing.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItems?.first
                            self.present(sharing, animated: true, completion: nil)
            }
        }))
        prompt.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(prompt, animated: true, completion: nil)
    }
    @IBAction func didTapCancelButton(){
        //Remove this view and cancel this issue
        print("Cancel!")
        if selectedIssue != nil{
            selectedIssue!.cancel()
            selectedIssue!.cancel()
            selectedIssue!.cancel()
            //Update model and info view if possible
            for node in scene.geometryNode!.childNodes{
                if let box=node as? BoxNode{
                    if box.issue == selectedIssue{
                        //Turn box to gray color
                        box.geometry!.materials = [UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)].map {
                            let material = SCNMaterial()
                            material.diffuse.contents = $0
                            material.isDoubleSided = true
                            material.transparencyMode = .aOne
                            return material
                        }
                        updateInfoView(sourceObject: box, sourceIssue: nil)
                    }
                }
                else if let ball=node as? BallNode{
                    if ball.sourceIssue == selectedIssue{
                        //delete ball
                        ball.removeFromParentNode()
                        updateInfoView(sourceObject: nil, sourceIssue: nil)
                    }
                }
            }
        }
        
    }
}
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
//        let ambientLightNode = SCNNode()
//            ambientLightNode.light = SCNLight()
//            ambientLightNode.light!.type = .ambient
//            ambientLightNode.light!.color = UIColor(white: 0.70, alpha: 1.0)
//
//            // Add ambient light to scene
//        rootNode.addChildNode(ambientLightNode)
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
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
            case .floor:
                print("Do nothing now")
            @unknown default:
                print("Do nothing now")
            }
            
        }
        for issue in replicator.getAllIssuesToBePresented() {
            if issue.cancelled{
                continue
            }
            if issue.hasSource(){
                if issue.sourceObject != nil{
                    let issueNode=BallNode(issue: issue)
                    rootNode.addChildNode(issueNode)
                }
                else{
                    //Find the corresponding node and make it red
                    for node in rootNode.childNodes{
                        if let box = node as? BoxNode{
                            if box.sourceRoomPlanObject != nil && issue.sourceRPObject != nil{
                                if box.sourceRoomPlanObject==issue.sourceRPObject{
                                    box.geometry!.materials = [UIColor.red].map {
                                        let material = SCNMaterial()
                                        material.diffuse.contents = $0
                                        material.isDoubleSided = true
                                        material.transparencyMode = .aOne
                                        return material
                                    }
                                    box.issue=issue
                                }
                            }
                            if box.sourceRoomPlanSurface != nil && issue.sourceRPSurface != nil{
                                if box.sourceRoomPlanSurface==issue.sourceRPSurface{
                                    box.geometry!.materials = [UIColor.red].map {
                                        let material = SCNMaterial()
                                        material.diffuse.contents = $0
                                        material.isDoubleSided = true
                                        material.transparencyMode = .aOne
                                        return material
                                    }
                                    box.issue=issue
                                }
                            }
                        }
                    }
                }
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
    var issue:AccessibilityIssue?
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
            self.name = "rootNode"
            return
        case .floor:
            //Create a dark gray floor which is big enough to contain all indoor space. Use the information in minimap
            //let box = SCNCylinder(radius: 5, height: 0.1)
            let map=Settings.instance.miniMap
            let box=SCNBox(width:CGFloat( map!.xrange!.len()), height:0.1 , length: CGFloat( map!.xrange!.len()), chamferRadius: 0)
            box.materials = [UIColor.systemGray2].map {
                let material = SCNMaterial()
                material.diffuse.contents = $0
                material.isDoubleSided = true
                material.transparencyMode = .aOne
                return material
            }
            
            super.init()
            self.geometry = box
            self.transform=SCNMatrix4(map!.longestWall!.transform)
            self.position=SCNVector3(x: map!.outlineCenter!.x, y: Settings.instance.replicator!.getFloorHeight(), z: map!.outlineCenter!.y)
            self.name = "floorNode"
            return
        case .furniture:
            //Create a light gray box using the position and size provided by room object anchor
            sourceRoomPlanObject=sourceObject
            let dimension=sourceRoomPlanObject!.dimensions
            let box = SCNBox(width: CGFloat(dimension.x), height: CGFloat(dimension.y), length: CGFloat(dimension.z), chamferRadius: 0)
            box.materials = [UIColor(red: 0.5686, green: 0.3294, blue: 0.0706, alpha: 1.0)].map {
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
            self.name = "openingNode"
            self.transform=SCNMatrix4(sourceRoomPlanSurface!.transform)
            return
        case .wall:
            //create a white gray box using the position and size provided by room surface anchor
            sourceRoomPlanSurface=sourceSurface
            let dimension=sourceRoomPlanSurface!.dimensions
            let box = SCNBox(width: CGFloat(dimension.x), height: CGFloat(dimension.y), length: CGFloat(dimension.z), chamferRadius: 0)
            box.materials = [UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)].map {
                let material = SCNMaterial()
                material.diffuse.contents = $0
                material.isDoubleSided = true
                material.transparencyMode = .aOne
                return material
            }
            super.init()
            self.geometry = box
            self.name = "wallNode"
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
            self.name = "windowNode"
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
    func getSourceDescription()->String{
        switch nodeType{
        case .root:
            return "Root"
        case .floor:
            return "Floor of the space"
        case .furniture:
            return sourceRoomPlanObject!.getDescription()
        case .opening:
            return sourceRoomPlanSurface!.getDescription()
        case .window:
            return sourceRoomPlanSurface!.getDescription()
        case .wall:
            return sourceRoomPlanSurface!.getDescription()
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
        self.geometry = SCNSphere(radius: 0.2)
        self.geometry!.materials = [UIColor.red].map {
            let material = SCNMaterial()
            material.diffuse.contents = $0
            material.isDoubleSided = true
            material.transparencyMode = .aOne
            return material
        }
        self.name = "issueNode"
        self.position=SCNVector3(issue.getPosition())
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func getSourceClass()->String{
        return "Accessibility Issue"
    }
    func getSourceDescription()->String{
        sourceIssue.getDetails()
    }
}

fileprivate extension SCNAction {
    class func levitate(distance: CGFloat, duration: TimeInterval) -> SCNAction {
        let moveUp = SCNAction.moveBy(x: 0, y: distance/2, z: 0.0, duration: duration/2)
        let moveDown = SCNAction.moveBy(x: 0, y: -distance/2, z: 0.0, duration: duration/2)
        (distance: 0.03, duration: 2.0)
        moveUp.timingMode = .easeInEaseOut
        moveDown.timingMode = .easeInEaseOut

        return SCNAction.repeatForever(SCNAction.sequence([moveUp, moveDown]))

    }
}
extension SCNNode {
    func setHighlighted( _ highlighted : Bool = true, _ highlightedBitMask : Int = 2 ) {
        categoryBitMask = highlightedBitMask
        for child in self.childNodes {
            child.setHighlighted()
        }
    }
    func setNonHighlighted( _ highlighted : Bool = false, _ highlightedBitMask : Int = 1 ) {
        categoryBitMask = highlightedBitMask
        for child in self.childNodes {
            child.setNonHighlighted()
        }
    }
}
