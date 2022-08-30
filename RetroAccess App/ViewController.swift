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

class ViewController: UIViewController,RoomCaptureViewDelegate {
    
    private var roomCaptureView: RoomCaptureView!
    private var roomCaptureSessionConfig: RoomCaptureSession.Configuration = RoomCaptureSession.Configuration()
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
    private var bboxOverlay: CALayer! = nil
    override func viewDidLoad() {
        showBbox=true
        super.viewDidLoad()
        print(Settings.instance.community)
        setupRoomCaptureView()
        setupLayers()
        
        //Load new OD framework
        Task { [weak self] in
            try! await self!.yolo.load(width: 416, height: 416, confidence: 0.4, nms: 0.6, maxBoundingBoxes: 10)//TODO: adjust cnfidence to filter away erronous resutls
            print("YOLO successfully loaded")
        }
        setUpBoundingBoxes()
        setUpCoreImage()
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { _ in
            self.updateOD()
            //self.drawVisionRequestResults(self.ODResults)
            //self.updateObjectLabelWithODResult(self.ODResults)
        })
        
    }
    private func setupRoomCaptureView() {
        roomCaptureView = RoomCaptureView(frame: view.bounds)
        roomCaptureView.captureSession.delegate = self
        roomCaptureView.delegate = self
        roomCaptureView.captureSession.arSession.delegate=self
        
        view.insertSubview(roomCaptureView, at: 0)
        rootLayer=view.layer
        bufferSize=CGSize(width: rootLayer.bounds.width, height: rootLayer.bounds.height)
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true, block: { _ in
            self.replicator.updateAccessibilityIssue(in:self.roomCaptureView.captureSession)
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
        roomCaptureView?.captureSession.run(configuration: roomCaptureSessionConfig)
    }
    
    private func stopSession() {
        isScanning = false
        roomCaptureView?.captureSession.stop()
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
    func updateOD(){
        //try to add od here
        guard let currentFrame = roomCaptureView.captureSession.arSession.currentFrame else {
            return
        }
        let buffer = currentFrame.capturedImage
        //visionRequest(buffer)
        predict(pixelBuffer: buffer)
    }
    func predict(pixelBuffer: CVPixelBuffer) {
        
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
        
        
        if let boundingBoxes = try? yolo.predict(image: resizedPixelBuffer) {
            let elapsed = CACurrentMediaTime() - startTime
            showOnMainThread(boundingBoxes, elapsed)
        }
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
        for i in 0..<boundingBoxes.count {
            if i < predictions.count {
                let prediction = predictions[i]
                
                let width = view.bounds.height/1920*1440
                let height = view.bounds.height
                let scaleX = width
                let scaleY = height
                let left = (width - view.bounds.width) / 2
                
                // Translate and scale the rectangle to our own coordinate system.
                var rect = prediction.rect
                let temp1=rect.origin.x
                rect.origin.x=1-rect.origin.y-rect.size.height
                rect.origin.y=temp1
                
                rect.origin.x *= scaleX
                rect.origin.y *= scaleY
                rect.origin.x -= left
                
                let temp2=rect.size.width
                rect.size.width=rect.size.height
                rect.size.height=temp2
                
                rect.size.width *= scaleX
                rect.size.height *= scaleY
                
                // Show the bounding box.
                let label = String(format: "%@ %.1f", yolo.names[prediction.classIndex] ?? "<unknown>", prediction.score)
                let color = colors[prediction.classIndex]
                if showBbox{
                    boundingBoxes[i].show(frame: rect, label: label, color: color)
                }
                //Conduct raycast to find 3D pos of item
//                let center=CGPoint(x: rect.origin.x, y: rect.origin.y)
//                let session=roomCaptureView.captureSession.arSession
//                //let cameraTransform=roomCaptureView.captureSession.arSession.currentFrame?.camera.transform
//                //let cameraPosition = SIMD3(x: cameraTransform!.columns.3.x, y: cameraTransform!.columns.3.y, z: cameraTransform!.columns.3.z)
//                let query=session.currentFrame?.raycastQuery(from: center, allowing: .estimatedPlane, alignment:.any)
//                if let cast=roomCaptureView.captureSession.arSession.raycast(query!).first{
//                    let resultAnchor = AnchorEntity(world: cast.worldTransform)
//                    resultAnchor.addChild(sphere(radius: 0.01, color: .lightGray))
//                    session.addAnchor(resultAnchor)
//
//                }
                //centers.append(CGPoint(x: rect.origin.x, y: rect.origin.y))
                
            } else {
                boundingBoxes[i].hide()
            }
        }
    }
    func drawVisionRequestResults(_ results: [Any])
    {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil // remove all the old recognized objects
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            // Select only the label with the highest confidence.
            let topLabelObservation = objectObservation.labels[0]
            var bbox=objectObservation.boundingBox
            var bbox_rotated=CGRect(x: 1-bbox.minY, y: bbox.maxX, width: bbox.height, height: bbox.width)
            var xscale:CGFloat=1440*1170/(1920*834)//1.0522
            var yscale:CGFloat=1/1.3333
            var bbox_flipped=CGRect(x: bbox.minX*xscale-(1-1/xscale)/2, y: (1-bbox.maxY)*yscale+0.125, width: bbox.width*xscale, height: bbox.height*yscale)
            var w:Int=Int(bufferSize.width)
            var h:Int=Int(bufferSize.height)
            //let objectBounds = VNImageRectForNormalizedRect(bbox_rotated, 600, 600)
            //let objectBoundsOffset=CGRect(x: objectBounds.minX-100, y: objectBounds.minY+100, width: objectBounds.width, height: objectBounds.height)
            let objectBounds = VNImageRectForNormalizedRect(bbox_flipped, w,h)
            let objectBoundsOffset=CGRect(x: objectBounds.minX, y: objectBounds.minY, width: objectBounds.width, height: objectBounds.height)
            //let objectBoundsOffset=CGRect(x: 410, y: 580, width: 60, height: 30)
            //let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
            
            //let textLayer = self.createTextSubLayerInBounds(objectBounds,identifier: topLabelObservation.identifier,confidence: topLabelObservation.confidence)
            //shapeLayer.addSublayer(textLayer)
            //detectionOverlay.addSublayer(shapeLayer)
            
        }
        //self.updateLayerGeometry()
        CATransaction.commit()
    }
    

    func updateObjectLabelWithODResult(_ results: [Any]) {
        //detectionOverlay.sublayers = nil // remove all the old recognized objects
        NSLog("Detected ",results.count,"objects");
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            // Select only the label with the highest confidence.
            let topLabelObservation = objectObservation.labels[0]
            NSLog(topLabelObservation.identifier);
            //Do some necessary transformation
            var bbox=objectObservation.boundingBox
            var bbox_rotated=CGRect(x: 1-bbox.minY, y: bbox.maxX, width: bbox.height, height: bbox.width)
            var xscale:CGFloat=1440*1170/(1920*834)//1.0522
            var yscale:CGFloat=1/1.3333
            var bbox_flipped=CGRect(x: bbox.minX*xscale-(1-1/xscale)/2, y: (1-bbox.maxY)*yscale+0.125, width: bbox.width*xscale, height: bbox.height*yscale)
            var w:Int=Int(bufferSize.width)
            var h:Int=Int(bufferSize.height)
            //let objectBounds = VNImageRectForNormalizedRect(bbox_rotated, 600, 600)
            //let objectBoundsOffset=CGRect(x: objectBounds.minX-100, y: objectBounds.minY+100, width: objectBounds.width, height: objectBounds.height)
            let objectBounds = VNImageRectForNormalizedRect(bbox_flipped, w,h)
            //let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))
            let centerPosition=CGPoint(x:objectBounds.midX*896/1170-112,y: objectBounds.midY*896/1170 )
            //cast ray
//            if let cast = arView.raycast(from: centerPosition, allowing: .estimatedPlane, alignment: .any).first {
//                let resultAnchor = AnchorEntity(world: cast.worldTransform)
//                resultAnchor.addChild(sphere(radius: 0.01, color: .lightGray))
//                self.arView.scene.addAnchor(resultAnchor)
//                var castedAnchor=cast.anchor
//                if(!(castedAnchor==nil)){
//                    if(!AnchorList.contains(castedAnchor!)){
//                        AnchorList.append(castedAnchor!)
//                    }
//                }
//            }
        }
        //self.updateLayerGeometry()
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
                            rootLayer.addSublayer( issueLayer.getExtendedLayer())
                            print("Trying to add another layer")
                        }
                    }
                    else{
                        print("Layer doesn't contain click")
                    }
                }
            }
        }
    }

    private func layerFor(_ touch: UITouch) -> CALayer?
    {
        let view = self.view!
        let touchLocation = touch.location(in: view)
        let locationInView = view.convert(touchLocation, to: nil)

        let hitPresentationLayer = detectionOverlay.presentation()?.hitTest(locationInView)
        return hitPresentationLayer?.model()
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
        //Draw od results if needed
        if showBbox{
            
            
        }
        
        // Do something with the new transform
        let allIssues=replicator.getAllIssuesToBePresented()
        for issue in allIssues{
            let source=issue.getSource()
            //let anchor=issue.getAnchor()
            var trans:simd_float4x4?
            if source.SourceDetectedObject != nil{
                //TODO: get the transformation of od objects
                trans=nil
            }
            else if source.SourceRoomplanObject != nil{
                trans=source.SourceRoomplanObject?.transform
            }
            else{
                trans=source.SourceRoomplanSurface?.transform
            }
            if trans != nil{
                let position = SIMD3(x: trans!.columns.3.x, y: trans!.columns.3.y, z: trans!.columns.3.z)
                let pos=session.currentFrame?.camera.projectPoint(position, orientation: .portrait, viewportSize: CGSize(width: 1920, height: 1440))
                if pos != nil{
                    //TODO: create a new class for the preview layer
                    let shapeLayer=IssueLayer(issue: issue, position: pos!)
                    detectionOverlay.addSublayer(shapeLayer)
                }
            }
            
        }
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
