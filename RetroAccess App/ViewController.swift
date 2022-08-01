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

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    var captureSession: RoomCaptureSession?
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
        captureSession = RoomCaptureSession()
        captureSession?.delegate = self
        //arView.session=captureSession!.arSession
        captureSession?.run(configuration: .init())
        
        bufferSize=arView.frame.size
        rootLayer=arView.layer
        setupLayers()
        //self.timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { _ in
            //self.updateOD()
            //self.drawVisionRequestResults(self.ODResults)
            //self.updateObjectLabelWithODResult(self.ODResults)
        //})
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            self.replicator.updateAccessibilityIssue(in:self.captureSession!)
        })
        // Load the "Box" scene from the "Experience" Reality File
        //let boxAnchor = try! Experience.loadBox()
        
        // Add the box anchor to the scene
        //arView.scene.anchors.append(boxAnchor)
    }
    func setupLayers() {
        detectionOverlay = CALayer() // container layer that has all the renderings of the observations
        detectionOverlay.name = "DetectionOverlay"
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: bufferSize.width,
                                         height: bufferSize.height)
        var bounds=rootLayer.bounds
        detectionOverlay.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)
        rootLayer.addSublayer(detectionOverlay)
    }
    func updateOD(){
        //try to add od here
        guard let currentFrame = arView.session.currentFrame else {
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
            if let cast = arView.raycast(from: centerPosition, allowing: .estimatedPlane, alignment: .any).first {
                let resultAnchor = AnchorEntity(world: cast.worldTransform)
                resultAnchor.addChild(sphere(radius: 0.01, color: .lightGray))
                self.arView.scene.addAnchor(resultAnchor)
                var castedAnchor=cast.anchor
                if(!(castedAnchor==nil)){
                    if(!AnchorList.contains(castedAnchor!)){
                        AnchorList.append(castedAnchor!)
                    }
                }
                
            }
        }
        //self.updateLayerGeometry()
    }
    func sphere(radius: Float, color: UIColor) -> ModelEntity {
        let sphere = ModelEntity(mesh: MeshResource.generateSphere(radius: radius), materials: [SimpleMaterial(color: color, isMetallic: false)])
        // Move sphere up by half its diameter so that it does not intersect with the mesh
        sphere.position.y = radius
        return sphere
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
        arView.scene.addRoomObjectEntities(for: anchors)
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        arView.scene.updateRoomObjectEntities(for: anchors)
    }

}
