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
//import Speech
public class ViewController: UIViewController,RoomCaptureViewDelegate {
    
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
    
    var detector:ObjectDetection=ObjectDetection()
    var boundingBoxes = [BoundingBox]()
    var colors: [UIColor] = []
    let maxBoundingBoxes = 10
    let ciContext = CIContext()
    var resizedPixelBuffer: CVPixelBuffer?
    var showBbox:Bool=false
    var minimap:MiniMapLayer?
    var resizers:[YOLOResizer]=[YOLOResizer]()
    let roombuilder=RoomBuilder(options: [.beautifyObjects])
    var manager = FileManager.default
    let screenSize: CGRect = UIScreen.main.bounds
    var extendedViewIsOut:Bool=false{
        didSet{
            if extendedViewIsOut{
                minimap?.isHidden=true
            }
            else{
                minimap?.isHidden=false
            }
        }
    }
    private var bboxOverlay: CALayer! = nil
    
    var voiceSynthesizer:AVSpeechSynthesizer?
    var assistiveVoice:AVSpeechSynthesisVoice?
    //let speechRecognizer = SFSpeechRecognizer()
    let audioEngine = AVAudioEngine()
    //var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    //var recognitionTask: SFSpeechRecognitionTask?
    var speechAuthorized:Bool=false
    var audioQueue = [AudioFeedback]()
    
    public override func viewDidLoad() {
        Settings.instance.viewcontroller=self
        UIApplication.shared.isIdleTimerDisabled=true
        replicator.setView(view:arView)
        Settings.instance.setReplicator(rep: replicator)
        showBbox=true
        super.viewDidLoad()
        print(Settings.instance.community)
        setupRoomCapture()
        setupLayers()
        
        setUpBoundingBoxes()
        setUpCoreImage()
        setUpYOLOResizers()
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true, block: { _ in
            for resizer in self.resizers{
                self.updateOD(resizer: resizer)
            }
            
            //self.drawVisionRequestResults(self.ODResults)
            //self.updateObjectLabelWithODResult(self.ODResults)
        })
        
        //Add button for ending scanning process and export pdf report
        let rect1 = CGRect(x: screenSize.width/4*3, y: 100, width: 56, height: 56)
        // STOP BUTTON
//        let stopButton = UIButton(frame: rect1)
//        stopButton.accessibilityLabel="Finish Scan"
//        //stopButton.setTitle("Export Results", for: .normal)
//        stopButton.addTarget(self, action: #selector(stop), for: .touchUpInside)
//        //stopButton.setTitleColor(.white, for: .normal)
//        //stopButton.backgroundColor = .blue
//        let buttonShapeView=UIView()
//        buttonShapeView.isUserInteractionEnabled=false
//        buttonShapeView.frame=CGRect(x: 0, y: 0, width: 56, height: 56)
//        let circleLayer = CAShapeLayer()
//        let radius: CGFloat = 28
//        circleLayer.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 2.0 * radius, height: 2.0 * radius), cornerRadius: radius).cgPath
//        circleLayer.frame=CGRect(x: 0, y: 0, width: 56, height: 56)
//        //circleLayer.fillColor = UIColor(red: 0.122, green: 0.216, blue: 0.267, alpha: 1).cgColor
//        circleLayer.fillColor = UIColor(red: 0.122, green: 0.216, blue: 0.267, alpha: 0).cgColor
//        buttonShapeView.layer.addSublayer(circleLayer)
//        let exportIcon=UIImage(named: "export")!.resizeImage(newSize: CGSize(width: 40, height: 40))
//        let iconView=UIImageView(image: exportIcon)
//        iconView.frame=CGRect(x: 8, y: 8, width: 40, height: 40)
//        buttonShapeView.addSubview(iconView)
//        stopButton.addSubview(buttonShapeView)
//        stopButton.isAccessibilityElement=true
//        self.arView.addSubview(stopButton)
        self.arView.isAccessibilityElement=true
        minimap=MiniMapLayer(replicator: replicator, session: roomCaptureSession!, radius: 100, center: CGPoint(x:screenSize.width/2,y:screenSize.height-200))
        rootLayer.addSublayer(minimap!)
        if Settings.instance.BLVAssistance{
            voiceSynthesizer=AVSpeechSynthesizer()
            assistiveVoice=AVSpeechSynthesisVoice(language: "en-GB")
            //speak(content: "Please point camera at top and bottom of wall to initialize.")
            enqueueAudio(audioFeedback: AudioFeedback(content: "Please point camera at top and bottom of wall to initialize..", type: .scanSuggestion, uploadTime: Date(), issue: nil))
            //requestSpeechAuthorization()
        }
        let customAction = UIAccessibilityCustomAction(name: "Stop Scan", target: self, selector: #selector(stop))
        arView.accessibilityCustomActions = [customAction]
    }
    @objc func stop(sender: UIButton!) {
        //Stop the scan, export result as file, and call the QL Preview
        Settings.instance.miniMap=minimap
        roomCaptureSession!.stop()
        speak(content: replicator.getIssueSummary())
        //Export scanned data
        //let jsonData = try! JSONEncoder().encode(replicator)
        //let jsonString = String(data: jsonData, encoding: .utf8)!
        //let data = jsonString.data(using: .utf8)!
        //print(jsonString)
    }
    
    @IBAction func stopScan(_ sender: Any) {
        Settings.instance.miniMap=minimap
        roomCaptureSession!.stop()
        speak(content: replicator.getIssueSummary())
    }
    private func setupRoomCapture() {
        roomCaptureSession = RoomCaptureSession()
        roomCaptureSession?.delegate = self
        roomCaptureSession?.run(configuration: .init())
        rootLayer=view.layer
        bufferSize=CGSize(width: rootLayer.bounds.width, height: rootLayer.bounds.height)
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            self.replicator.updateAccessibilityIssue(in:self.roomCaptureSession!)
            //print("Successfully updated issues")
            //print(self.replicator.getAllIssuesToBePresented())
            
            self.minimap?.update()
        })
    }
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSession()
    }
    
    public override func viewWillDisappear(_ flag: Bool) {
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
            let boxes = self.boundingBoxes
            guard let videoLayer  = self.bboxOverlay else {return}
            for box in boxes {
                box.addToLayer(videoLayer)
            }
        }
    }
    
    func setUpCoreImage() {
        let status = CVPixelBufferCreate(nil, Settings.instance.yoloInputWidth, Settings.instance.yoloInputHeight,
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
        let middleResizer=YOLOResizer(fullBufferSize: CGSize(width:1440,height:1920), fullScreenSize: CGSize(width:screenSize.width,height:screenSize.height), croppedBufferSize: CGSize(width: 700, height: 700), croppingPosition: .middle, rotate: .up)
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
        let observations = detector.detectAndProcess(image: resizer.resizeImage(buffer: pixelBuffer))
        let elapsed = CACurrentMediaTime() - startTime
        let resizedBbox=resizer.resizeResults(initialResults:observations)
        showOnMainThread(resizedBbox, elapsed)
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
                
                var rect = prediction.rect
                // Show the bounding box.
                let label = String(format: "%@ %.1f", detector.names[prediction.classIndex] ?? "<unknown>", prediction.score)
                let color = colors[prediction.classIndex]
                if showBbox && !extendedViewIsOut{
                    //print("showing result")
                    //print(label)
                    //print(rect.origin)
                    //print(rect.size)
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
                        let name=detector.names[prediction.classIndex]
                        let prob=prediction.score
                        let odAnchor=DetectedObjectAnchor(anchor: resultAnchor, rect:rect,cat: name, identifier: UUID.init())
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
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesBegan(touches, with: event)
        if !extendedViewIsOut{
            if let touch = touches.first{
                let view = self.view!
                let touchLocation = touch.location(in: view)
                let locationInView = view.convert(touchLocation, to: nil)
                //print(locationInView)
                let transformedLocation=CGPoint(x: locationInView.x+35, y: locationInView.y+35)
                if let sublayers = detectionOverlay.sublayers{
                    for layer in sublayers{
                        if layer.contains(transformedLocation){
                            if layer is IssueLayer{
                                let issueLayer = layer as! IssueLayer
                                //This is where we used to add popping up layer. Now cancel this to use as cancel issue
                                //rootLayer.addSublayer(issueLayer.getExtendedLayer())
                                //let issueView=PopupView(issue: issueLayer.issue,controller:self)
                                //self.view.addSubview(issueView)
                                self.arView.addSubview(issueLayer.getExtendedView(parent: self))
                                extendedViewIsOut=true
                                //issueLayer.issue.cancel()
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
    
    
}

extension ViewController: RoomCaptureSessionDelegate {

    public func captureSession(_ session: RoomCaptureSession, didAdd room: CapturedRoom) {
        replicator.anchor(objects: room.objects,surfaces: room.walls+room.doors+room.openings+room.windows , in: session)
        minimap?.update()
    }

    public func captureSession(_ session: RoomCaptureSession, didChange room: CapturedRoom) {
        replicator.anchor(objects: room.objects, surfaces: room.walls+room.doors+room.openings+room.windows ,in: session)
        minimap?.update()
    }

    public func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
        replicator.anchor(objects: room.objects, surfaces: room.walls+room.doors+room.openings+room.windows ,in: session)
        minimap?.update()
    }

    public func captureSession(_ session: RoomCaptureSession, didRemove room: CapturedRoom) {
        
        replicator.anchor(objects: room.objects,surfaces: room.walls+room.doors+room.openings+room.windows ,in: session)
        minimap?.update()
    }
    public func captureSession(_ session: RoomCaptureSession, didStartWith configuration: RoomCaptureSession.Configuration) {
        arView.session.pause()
        arView.session = session.arSession
        arView.session.delegate = self
    }
    public func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
        print("Stop callback called")
        DispatchQueue.main.async {
            // UIView usage
            let storyboard = self.storyboard
            let posthoc = storyboard!.instantiateViewController(identifier: "PostHocView")
            posthoc.isModalInPresentation=true
            self.show(posthoc, sender: self)
        }
        
    }
    public func captureSession(_ session: RoomCaptureSession, didProvide instruction: RoomCaptureSession.Instruction) {
        switch instruction{
        case .moveCloseToWall:
            //speak(content: "Please move closer to wall")
            enqueueAudio(audioFeedback: AudioFeedback(content: "Please move closer to wall.", type: .scanSuggestion, uploadTime: Date(), issue: nil))
            //print("Please move closer to wall")
        case .moveAwayFromWall:
            //speak(content: "Please move away from wall")
            enqueueAudio(audioFeedback: AudioFeedback(content: "Please move away from wall.", type: .scanSuggestion, uploadTime: Date(), issue: nil))
            //print("Please move away from wall")
        case .slowDown:
            //speak(content: "Please slow down")
            enqueueAudio(audioFeedback: AudioFeedback(content: "Please slow down.", type: .scanSuggestion, uploadTime: Date(), issue: nil))
            //print("Please slow down")
        case .turnOnLight:
            //speak(content: "Please turn on the light")
            enqueueAudio(audioFeedback: AudioFeedback(content: "Please turn on the light.", type: .scanSuggestion, uploadTime: Date(), issue: nil))
            //print("Please turn on the light")
        case .normal:
            print("Normal")
        case .lowTexture:
            //speak(content: "Failed to detect edge of wall. Please try to include edge of walls.")
            enqueueAudio(audioFeedback: AudioFeedback(content: "Failed to detect edge of wall. Please try to include edge of walls.", type: .scanSuggestion, uploadTime: Date(), issue: nil))
        @unknown default:
            print("Default")
        }
    }
}

extension ViewController: ARSessionDelegate {
    
    public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
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
    
    public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        //arView.scene.updateRoomObjectEntities(for: anchors)
        
    }
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        detectionOverlay.sublayers=nil
        // Show issue layers
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
                //continue
            }
            else if source.SourceRoomplanObject != nil{
                trans=source.SourceRoomplanObject?.transform
            }
            else{
                trans=source.SourceRoomplanSurface?.transform
            }
            if trans != nil{
                let position = SIMD3(x: trans!.columns.3.x, y: trans!.columns.3.y, z: trans!.columns.3.z)
                let position4 = simd_float4(x: position.x, y: position.y, z: position.z, w: 1)
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
                //TODO: tell if this cast is from the back!
                let projectionMatrix = frame.camera.projectionMatrix(for: .portrait, viewportSize: CGSize(width: 428, height: 926), zNear: 0.001, zFar: 1000.0)
                let viewMatrix = frame.camera.viewMatrix(for: .portrait)
                let clipSpacePosition = projectionMatrix * viewMatrix * position4
                //print("Clip Space Position is \(clipSpacePosition)")
                if pos != nil && clipSpacePosition.z > 0 && clipSpacePosition.w > 0 && !extendedViewIsOut{
                        //TODO: create a new class for the preview layer
                        let shapeLayer=IssueLayer(issue: issue, position: pos!)
                        detectionOverlay.addSublayer(shapeLayer)
                    }
                    //                }
                    
                //}
                
            }
        }
        //Rotate the minimap with the real-time camera orientation
        let cameraTrans=session.currentFrame?.camera.eulerAngles
        if let trans=cameraTrans {
            var angle=trans.y
            if angle<0{
                angle += .pi*2
            }
            //let rotation = CATransform3DMakeRotation(CGFloat(angle), 0, 0, 1)
            if let map=minimap{
                if map.isDrawn(){
                    //print("Rotating minimap with angle \(angle)")
                    map.set_rotation(angle:angle)
                }
            }
        }
    }
}
