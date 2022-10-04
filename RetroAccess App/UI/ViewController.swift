//
//  ViewController.swift
//  RetroAccess App
//
//  Created by Xia Su on 7/11/22.
//
import ARKit
import UIKit
import RealityKit
import RoomPlan
import PDFKit

class ViewController: UIViewController,RoomCaptureViewDelegate {
    
    @IBOutlet var arView: ARView!
    private var roomCaptureSession:RoomCaptureSession?
    //private var roomCaptureView: RoomCaptureView!
    //private var roomCaptureSessionConfig: RoomCaptureSession.Configuration = RoomCaptureSession.Configuration()
    private var isScanning: Bool = false
    private var finalResults: CapturedRoom?
    var replicator = RoomObjectReplicator()
    var timer = Timer()
    private var AnchorList=[ARAnchor]()
    var ODResults: [VNObservation]=[VNObservation]();
    private var requests = [VNRequest]()
    private var detectionOverlay: CALayer! = nil
    var bufferSize: CGSize = .zero
    var rootLayer: CALayer! = nil
    
    var yolo = YOLO4My()
    var boundingBoxes = [BoundingBox]()
    var colors: [UIColor] = []
    let maxBoundingBoxes = 10
    let ciContext = CIContext()
    var resizedPixelBuffer: CVPixelBuffer?
    var showBbox:Bool=false
    
    var resizers:[YOLOResizer]=[YOLOResizer]()
    
    private var bboxOverlay: CALayer! = nil
    override func viewDidLoad() {
        replicator.setView(view:arView)
        Settings.instance.setReplicator(rep: replicator)
        showBbox=true
        super.viewDidLoad()
        print(Settings.instance.community)
        setupRoomCapture()
        setupLayers()
        
        //Load new OD framework
        Task { [weak self] in
            try! await self!.yolo.load(width: 416, height: 416, confidence: 0.6, nms: 0.6, maxBoundingBoxes: 10)//TODO: adjust cnfidence to filter away erronous resutls
            print("YOLO successfully loaded")
        }
        setUpBoundingBoxes()
        setUpCoreImage()
        setUpYOLOResizers()
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { _ in
            for resizer in self.resizers{
                self.updateOD(resizer: resizer)
            }
            //self.drawVisionRequestResults(self.ODResults)
            //self.updateObjectLabelWithODResult(self.ODResults)
        })
        
        //Add button for ending scanning process and export pdf report
        let rect1 = CGRect(x: 250, y: 50, width: 150, height: 50)
        // STOP BUTTON
        let stopButton = UIButton(frame: rect1)
        stopButton.setTitle("Export Results", for: .normal)
        stopButton.addTarget(self, action: #selector(stop), for: .touchUpInside)
        stopButton.setTitleColor(.white, for: .normal)
        stopButton.backgroundColor = .blue
        //self.view.addSubview(stopButton)
    }
    @objc func stop(sender: UIButton!) {
        //Generate pdf report with scanned issues
//        if let vc = self.storyboard?.instantiateViewController(
//            withIdentifier: "PreviewView") {
//                let pdfCreator = PDFCreator(title: "Detection Result", body: "List of Accessibility issues",contact: "some author contact")
//                vc.documentData = pdfCreator.createFlyer()
//                vc.modalPresentationStyle = .fullScreen
//                present(vc, animated: true)
//        }
    }
    private func setupRoomCapture() {
        //roomCaptureView = RoomCaptureView(frame: view.bounds)
        //roomCaptureView.captureSession.delegate = self
        //roomCaptureView.delegate = self
        //roomCaptureView.captureSession.arSession.delegate=self
        
        //view.insertSubview(roomCaptureView, at: 0)
        roomCaptureSession = RoomCaptureSession()
        roomCaptureSession?.delegate = self
        roomCaptureSession?.run(configuration: .init())
        rootLayer=view.layer
        bufferSize=CGSize(width: rootLayer.bounds.width, height: rootLayer.bounds.height)
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true, block: { _ in
            self.replicator.updateAccessibilityIssue(in:self.roomCaptureSession!)
            print("Successfully updated issues")
            print(self.replicator.getAllIssuesToBePresented())
        })
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSession()
    }
    
    override func viewWillDisappear(_ flag: Bool) {
        super.viewWillDisappear(flag)
        stopSession()
    }
    
    private func startSession() {
        isScanning = true
        roomCaptureSession?.run(configuration:  .init())
    }
    
    private func stopSession() {
        isScanning = false
        roomCaptureSession?.stop()
    }
    func setUpBoundingBoxes() {
        for _ in 0 ..< maxBoundingBoxes {
            boundingBoxes.append(BoundingBox())
        }
        
        // Make colors for the bounding boxes. There is one color for each class,
        // 20 classes in total.
        for r: CGFloat in [0.1,0.2, 0.3,0.4,0.5, 0.6,0.7, 0.8,0.9, 1.0] {
            for g: CGFloat in [0.3,0.5, 0.7,0.9] {
                for b: CGFloat in [0.4,0.6 ,0.8] {
                    let color = UIColor(red: r, green: g, blue: b, alpha: 1)
                    colors.append(color)
                }
            }
        }
        DispatchQueue.main.async {
            guard let  boxes = self.boundingBoxes,let videoLayer  = self.bboxOverlay else {return}
            for box in boxes {
                box.addToLayer(videoLayer)
            }
        }
    }
    
    func setUpCoreImage() {
        let status = CVPixelBufferCreate(nil, 416, 416,
                                         kCVPixelFormatType_32BGRA, nil,
                                         &resizedPixelBuffer)
        if status != kCVReturnSuccess {
            print("Error: could not create resized pixel buffer", status)
        }
    }
    func setupLayers() {
        detectionOverlay = CALayer() // container layer that has all the renderings of the observations
        detectionOverlay.name = "DetectionOverlay"
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: 0,
                                         height: 0)
        var bounds=rootLayer.bounds
        detectionOverlay.position = CGPoint(x: 0, y: 0)
        rootLayer.addSublayer(detectionOverlay)
        
        bboxOverlay = CALayer() // container layer that has all the renderings of the observations
        bboxOverlay.name = "BoundingBoxOverlay"
        bboxOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: 0,
                                         height: 0)
        bboxOverlay.position = CGPoint(x: 0, y: 0)
        rootLayer.addSublayer(bboxOverlay)
    }
    func setUpYOLOResizers(){
        //Firstly, we have a null resizer that does nothing.
        //TODO: First test the resized one, then update the showing func to show both results
        //resizers.append(YOLOResizer(fullBufferSize: CGSize(width:1440,height:1920), fullScreenSize: CGSize(width:428,height:926), croppingPosition: .middle, croppingRatio: 1))
        
        //Then add a middle part resizer
        let middleResizer=YOLOResizer(fullBufferSize: CGSize(width:1440,height:1920), fullScreenSize: CGSize(width:428,height:926), croppedBufferSize: CGSize(width: 416, height: 416), croppingPosition: .middle, rotate: .up)
        resizers.append(middleResizer)
        rootLayer.addSublayer(middleResizer.getNotifyingFrame())
    }
    func updateOD(resizer:YOLOResizer){
        //try to add od here
        guard let currentFrame = roomCaptureSession?.arSession.currentFrame else {
            return
        }
        let buffer = currentFrame.capturedImage
        //visionRequest(buffer)
        predict(pixelBuffer: buffer,resizer: resizer)
    }
    func predict(pixelBuffer: CVPixelBuffer,resizer:YOLOResizer) {
        
        // Measure how long it takes to predict a single video frame.
        let startTime = CACurrentMediaTime()
        
        // Resize the input with Core Image.
        guard let resizedPixelBuffer = resizedPixelBuffer else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let sx = CGFloat(416) / CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let sy = CGFloat(416) / CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let scaleTransform = CGAffineTransform(scaleX: sx, y: sy)
        //let rotateTransform=CGAffineTransform(rotationAngle: CGFloat.pi/2*3)
        let scaledImage = ciImage.transformed(by: scaleTransform)
        //let finalImage=scaledImage.transformed(by: rotateTransform)
        ciContext.render(scaledImage, to: resizedPixelBuffer)
        
        if let boundingBoxes = try? yolo.predict(image: resizer.resizeBuffer(buffer: pixelBuffer)) {
            let elapsed = CACurrentMediaTime() - startTime
            let resizedBbox=resizer.resizeResults(initialResults:boundingBoxes)
            showOnMainThread(resizedBbox, elapsed)
        }
//        if let boundingBoxes = try? yolo.predict(image: resizedPixelBuffer) {
//            let elapsed = CACurrentMediaTime() - startTime
//            showOnMainThread(boundingBoxes, elapsed)
//        }
    }
    
    
    func showOnMainThread(_ boundingBoxes: [Prediction], _ elapsed: CFTimeInterval) {
        DispatchQueue.main.async { [weak self] in
            // For debugging, to make sure the resized CVPixelBuffer is correct.
            //var debugImage: CGImage?
            //VTCreateCGImageFromCVPixelBuffer(resizedPixelBuffer, nil, &debugImage)
            //self.debugImageView.image = UIImage(cgImage: debugImage!)
            
            self?.show(predictions: boundingBoxes)
        }
    }
    
    func show(predictions: [Prediction]){
        //var centers:[CGPoint]=[CGPoint]()
        var ODAnchors=[DetectedObjectAnchor]()
        for i in 0..<boundingBoxes.count {
            if i < predictions.count {
                let prediction = predictions[i]
                
//                let width = view.bounds.height/1920*1440
//                let height = view.bounds.height
//                let scaleX = width
//                let scaleY = height
//                let left = (width - view.bounds.width) / 2
//
//                // Translate and scale the rectangle to our own coordinate system.
                var rect = prediction.rect
//                let temp1=rect.origin.x
//                rect.origin.x=1-rect.origin.y-rect.size.height
//                rect.origin.y=temp1
//
//                rect.origin.x *= scaleX
//                rect.origin.y *= scaleY
//                rect.origin.x -= left
//
//                let temp2=rect.size.width
//                rect.size.width=rect.size.height
//                rect.size.height=temp2
//
//                rect.size.width *= scaleX
//                rect.size.height *= scaleY
//
                // Show the bounding box.
                let label = String(format: "%@ %.1f", yolo.names[prediction.classIndex] ?? "<unknown>", prediction.score)
                let color = colors[prediction.classIndex]
                if showBbox{
                    print("showing result")
                    print(label)
                    print(rect.origin)
                    print(rect.size)
                    boundingBoxes[i].show(frame: rect, label: label, color: color)
                }
                //Conduct raycast to find 3D pos of item
                if Settings.instance.raycastEnabled == false{
                    return
                }
                //let center=CGPoint(x: rect.origin.x/view.bounds.width, y: rect.origin.y/view.bounds.height)
                let center=CGPoint(x: rect.origin.x+rect.size.width/2, y: rect.origin.y+rect.size.height/2)
                //let session=roomCaptureSession!.arSession
//                let cameraTransform=roomCaptureView.captureSession.arSession.currentFrame?.camera.transform
//                let cameraPosition = SIMD3(x: cameraTransform!.columns.3.x, y: cameraTransform!.columns.3.y, z: cameraTransform!.columns.3.z)
//                let query=session.currentFrame?.raycastQuery(from: center, allowing: .estimatedPlane, alignment:.any)
//                print(query?.origin)
//                print(cameraPosition)
                //Only cast for centered points
                if center.x>50 && center.x<378 && center.y>50 && center.y<876
                {
                    if let cast=arView.raycast(from: center, allowing: .estimatedPlane, alignment: .any).first{
                        //print("A successful cast")
                        let resultAnchor = ARAnchor(transform:  cast.worldTransform)
                        let resultTransform=cast.worldTransform
                        let name=yolo.names[prediction.classIndex]
                        let prob=prediction.score
                        let odAnchor=DetectedObjectAnchor(anchor: resultAnchor, rect:rect,cat: name!, identifier: UUID.init())
                        if odAnchor.category != nil{
                            ODAnchors.append(odAnchor)
                        }
                        //replicator.addODAnchor(anchor:odAnchor)
    //                    session.add(anchor: odAnchor)
                        //let resultAnchor = AnchorEntity(world: cast.worldTransform)
                        //resultAnchor.addChild(sphere(radius: 0.05, color: .lightGray))
                        //arView.scene.addAnchor(resultAnchor)
                    }
                }
                //centers.append(CGPoint(x: rect.origin.x, y: rect.origin.y))
                
            } else {
                boundingBoxes[i].hide()
            }
        }
        replicator.addODAnchor(anchors: ODAnchors)
    }
    

    
    func sphere(radius: Float, color: UIColor) -> ModelEntity {
        let sphere = ModelEntity(mesh: MeshResource.generateSphere(radius: radius), materials: [SimpleMaterial(color: color, isMetallic: false)])
        // Move sphere up by half its diameter so that it does not intersect with the mesh
        sphere.position.y = radius
        return sphere
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesBegan(touches, with: event)

        if let touch = touches.first{
            let view = self.view!
            let touchLocation = touch.location(in: view)
            let locationInView = view.convert(touchLocation, to: nil)
            //let transformedLocation=CGPoint(x: locationInView.x-214, y: locationInView.y-463)
            if let sublayers = detectionOverlay.sublayers{
                for layer in sublayers{
                    if layer.contains(locationInView){
                        if layer is IssueLayer{
                            let issueLayer = layer as! IssueLayer
                            //This is where we used to add popping up layer. Now cancel this to use as cancel issue
                            //rootLayer.addSublayer( issueLayer.getExtendedLayer())
                            issueLayer.issue.cancel()
                            //print("Trying to add another layer")
                        }
                    }
                    else{
                        //print("Layer doesn't contain click")
                    }
                }
            }
        }
    }
}

extension ViewController: RoomCaptureSessionDelegate {

    func captureSession(_ session: RoomCaptureSession, didAdd room: CapturedRoom) {
        replicator.anchor(objects: room.objects,surfaces: room.walls+room.doors+room.openings+room.windows , in: session)
    }

    func captureSession(_ session: RoomCaptureSession, didChange room: CapturedRoom) {
        replicator.anchor(objects: room.objects, surfaces: room.walls+room.doors+room.openings+room.windows ,in: session)
    }

    func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
        replicator.anchor(objects: room.objects, surfaces: room.walls+room.doors+room.openings+room.windows ,in: session)
    }

    func captureSession(_ session: RoomCaptureSession, didRemove room: CapturedRoom) {
        
        replicator.anchor(objects: room.objects,surfaces: room.walls+room.doors+room.openings+room.windows ,in: session)
    }
    func captureSession(_ session: RoomCaptureSession, didStartWith configuration: RoomCaptureSession.Configuration) {
        arView.session.pause()
        arView.session = session.arSession
        arView.session.delegate = self
    }
}

extension ViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        //        for a in anchors{
        //            //session.add(anchor: a)
        //            //arView.scene.addAnchor(NotifyingEntity(anchor:a))
        //
        //            let mesh = MeshResource.generateSphere(radius: 0.3)
        //            let material = SimpleMaterial(color: .systemRed, roughness: 0.27, isMetallic: false)
        //            let model = ModelEntity(mesh: mesh, materials: [material])
        //            let anchorEntity = AnchorEntity(anchor: a)
        //            anchorEntity.anchor?.addChild(model)
        //            arView.scene.addAnchor(anchorEntity)
        //}
        //arView.scene.addRoomObjectEntities(for: anchors)
        
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        //arView.scene.updateRoomObjectEntities(for: anchors)
        
    }
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        detectionOverlay.sublayers=nil
        
        // Do something with the new transform
        let allIssues=replicator.getAllIssuesToBePresented()
        for issue in allIssues{
            if issue.cancelled{
                continue
            }
            let source=issue.getSource()
            //let anchor=issue.getAnchor()
            var trans:simd_float4x4?
            if source.SourceDetectedObject != nil{
                //TODO: get the transformation of od objects
                trans=source.SourceDetectedObject?.transform
                //Xia's Note: Cancel the pop-up for detected object since there are already yolo box and red ball
                continue
            }
            else if source.SourceRoomplanObject != nil{
                trans=source.SourceRoomplanObject?.transform
            }
            else{
                trans=source.SourceRoomplanSurface?.transform
            }
            if trans != nil{
                let position = SIMD3(x: trans!.columns.3.x, y: trans!.columns.3.y, z: trans!.columns.3.z)
                //let pos=session.currentFrame?.camera.projectPoint(position, orientation: .portrait, viewportSize: CGSize(width: 1920, height: 1440))
                //let cameraTrans=session.currentFrame?.camera.transform
                //let cameraPos=SIMD3(x: cameraTrans!.columns.3.x, y: cameraTrans!.columns.3.y, z: cameraTrans!.columns.3.z)
                //                let angle=session.currentFrame?.camera.eulerAngles
                //                let angle2=session.currentFrame?.camera.transform
                //let vector=SIMD3(x: position.x-cameraPos.x, y: position.y-cameraPos.y, z: position.z-cameraPos.z)
                //                let dot=simd_dot(angle!,vector)
                //                print("camera angle and issue vector")
                //                print(angle)
                //                print(vector)
                //                print(dot)
                //if simd_length(vector)<2.5{
                    let pos=session.currentFrame?.camera.projectPoint(position, orientation: .portrait, viewportSize: CGSize(width: 428, height: 926))
                    if pos != nil{
                        //TODO: create a new class for the preview layer
                        let shapeLayer=IssueLayer(issue: issue, position: pos!)
                        detectionOverlay.addSublayer(shapeLayer)
                    }
                    //                }
                    
                //}
                
            }
            //        print(session.currentFrame?.anchors)
            //Use UI layer to visualize DetectedObjectAnchor
            //        for a in session.currentFrame!.anchors{
            //            if a is DetectedObjectAnchor{
            //                let trans=a.transform
            //                let position = SIMD3(x: trans.columns.3.x, y: trans.columns.3.y, z: trans.columns.3.z)
            //                let pos=session.currentFrame?.camera.projectPoint(position, orientation: .portrait, viewportSize: CGSize(width: 1920, height: 1440))
            //                if pos != nil{
            //                    //TODO: create a new class for the preview layer
            //                    let layer=CALayer()
            //                    layer.position = CGPoint(x: pos!.x, y: pos!.y)
            //                    layer.bounds = CGRect(x: pos!.x, y: pos!.y, width:50, height: 50)
            //                    layer.frame=CGRect(x: pos!.x, y: pos!.y, width:50, height: 50)
            //                    layer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.1, 0.1, 1.0, 0.4])
            //                    layer.cornerRadius = 7
            //                    detectionOverlay.addSublayer(layer)
            //                }
            //            }
            //        }
            //        for a in replicator.getAllIssuesToBePresented(){
            //            var position = SIMD3(x: a.transform.columns.3.x, y: a.transform.columns.3.y, z: a.transform.columns.3.z)
            //            let rotation=simd_float3x3(columns: (SIMD3(x: a.transform.columns.0.x, y: a.transform.columns.0.y, z: a.transform.columns.0.z),
            //                                                 SIMD3(x: a.transform.columns.1.x, y: a.transform.columns.1.y, z: a.transform.columns.1.z),
            //                                                 SIMD3(x: a.transform.columns.2.x, y: a.transform.columns.2.y, z: a.transform.columns.2.z)))
            //            //position+=simd_mul(rotation,a.dimensions/2)
            //            let bounds=view.bounds.size.width
            //            let boundsh=view.bounds.size.height
            //            let pos=session.currentFrame?.camera.projectPoint(position, orientation: .portrait, viewportSize: CGSize(width: 1920, height: 1440))
            //            //Add an icon onto UI layer
            //            print(a.getCategoryName())
            //            print(pos)
            //            if pos != nil{
            //                //TODO: create a new class for the preview layer
            //                let shapeLayer=createPreviewLayerWithPosition(pos!,a.getCategoryName())
            //                detectionOverlay.addSublayer(shapeLayer)
            //            }
            //        }
        }
    }
}
