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
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        print(Settings.instance.community)
//        captureSession = RoomCaptureSession()
//        captureSession?.delegate = self
//        captureSession?.run(configuration: .init())
        setupRoomCaptureView()
        setupLayers()
        //self.timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { _ in
            //self.updateOD()
            //self.drawVisionRequestResults(self.ODResults)
            //self.updateObjectLabelWithODResult(self.ODResults)
        //})
        
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
    }
    func updateOD(){
        //try to add od here
        guard let currentFrame = roomCaptureView.captureSession.arSession.currentFrame else {
            return
        }
        let buffer = currentFrame.capturedImage
        visionRequest(buffer)
    }
    private func visionRequest( _ buffer : CVPixelBuffer) {
        let modelURL = Bundle.main.url(forResource: "YOLOv3Tiny", withExtension: "mlmodelc")
        let visionModel = try! VNCoreMLModel(for: MLModel(contentsOf: modelURL!))
        let request = VNCoreMLRequest(model: visionModel) { request, error in
            if error != nil{
                print("Error happend in OD request")
                return
            }
            guard let observations = request.results ,
                  let observation = observations.first as? VNClassificationObservation else {
                //print("No results")
                return
            }
            print("Object Name: \(observation.identifier) , \(observation.confidence * 100)")
            DispatchQueue.main.async {
                //self.createText("\(String(describing: observation.identifier))\n%\(observation.confidence * 100)")
                print("\(String(describing: observation.identifier))\n%\(observation.confidence * 100)");
            }
            
        }
        request.imageCropAndScaleOption = .centerCrop
        requests = [request]
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: buffer,
                                                        orientation: .right,
                                                        options: [:])
        
        DispatchQueue.global().async {
            try! imageRequestHandler.perform(self.requests)
            guard let observations = request.results ,
                  let observation = observations.first as? VNRecognizedObjectObservation else {
                print("No results")
                return
            }
            let topLabelObservation = observation.labels[0]
            //let objectBounds = VNImageRectForNormalizedRect(observation.boundingBox, bufferSize.width,bufferSize.height)
            print("Detected ",topLabelObservation.identifier," with confidence of ",topLabelObservation.confidence)
            if let results = request.results {
                //self.drawVisionRequestResults(results)
                self.ODResults=results
                //Get bbox center point and cast ray
                //self.updateObjectLabelWithODResult(results)
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
            let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
            
            let textLayer = self.createTextSubLayerInBounds(objectBounds,identifier: topLabelObservation.identifier,confidence: topLabelObservation.confidence)
            shapeLayer.addSublayer(textLayer)
            detectionOverlay.addSublayer(shapeLayer)
            
        }
        self.updateLayerGeometry()
        CATransaction.commit()
    }
    func updateLayerGeometry() {
        let bounds = rootLayer.bounds
        var scale: CGFloat
        
        let xScale: CGFloat = bounds.size.width / bufferSize.height
        let yScale: CGFloat = bounds.size.height / bufferSize.width
        
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // rotate the layer into screen orientation and scale and mirror
        //detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
        // center the layer
        detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        CATransaction.commit()
        
    }
    func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        let formattedString = NSMutableAttributedString(string: String(format: "\(identifier)\nConfidence:  %.2f", confidence))
        let largeFont = UIFont(name: "Helvetica", size: 24.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: identifier.count))
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height - 10, height: bounds.size.width - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        textLayer.contentsScale = 2.0 // retina rendering
        // rotate the layer into screen orientation and scale and mirror
        //textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        return textLayer
    }
    
    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Found Object"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.4])
        shapeLayer.cornerRadius = 7
        return shapeLayer
    }
    func createPreviewLayerWithPosition(_ pos: CGPoint,_ category:String) -> CALayer {
        var x=pos.x*926/1440-403.333-214
        var y=pos.y*926/1440-463
        //var x=214
        //var y=463
        let shapeLayer = CALayer()
        shapeLayer.bounds = CGRect(x: x, y: y, width:200, height: 100)
        shapeLayer.position = CGPoint(x: x, y: y)
        shapeLayer.name = "Issue Preview"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.4])
        shapeLayer.cornerRadius = 7
        
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        let formattedString = NSMutableAttributedString(string: category)
        let largeFont = UIFont(name: "Helvetica", size: 24.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: category.count))
        textLayer.string = category
        textLayer.bounds = CGRect(x: 0, y: 0, width: 150, height: 50)
        textLayer.position = CGPoint(x:x+100, y: y+50)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        textLayer.contentsScale = 2.0 // retina rendering
        
        shapeLayer.addSublayer(textLayer)
        return shapeLayer
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

//        if let touch = touches.first, let touchedLayer = self.layerFor(touch)
//        {
//            //Here you will have the layer as "touchedLayer"
//            if touchedLayer is IssueLayer{
//                let issueLayer=touchedLayer as! IssueLayer
//                issueLayer.getExtendedLayer()
//            }
//        }
        if let touch = touches.first{
            let view = self.view!
            let touchLocation = touch.location(in: view)
            let locationInView = view.convert(touchLocation, to: nil)
            //let transformedLocation=CGPoint(x: locationInView.x-214, y: locationInView.y-463)
            if let sublayers = detectionOverlay.sublayers{
                for layer in sublayers{
//                    let click=layer.hitTest(locationInView)
//                    if click == nil{
//                        print("Null click result")
//                    }
//                    if click == layer{
//                        if click is IssueLayer{
//                            let issueLayer=click as! IssueLayer
//                            issueLayer.getExtendedLayer()
//                        }
//                    }
                    //print(layer.bounds)
                    //print(locationInView)
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
        // Do something with the new transform
        detectionOverlay.sublayers=nil
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
