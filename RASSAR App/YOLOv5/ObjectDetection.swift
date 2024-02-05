//
//  ObjectDetection.swift
//  RetroAccess App
//
//  Created by Xia Su on 1/28/23.
//

import AVFoundation
import Vision
import CoreImage

class ObjectDetection{
    var detectionRequest:VNCoreMLRequest!
    var ready = false
    var names=[" ","Door Handle", "Electric Socket", "Grab Bar","Knife", "Medication","Rug", "Scissors", "Smoke Alarm","Switch"]
    init(){
        Task { self.initDetection() }
    }
    
    func initDetection(){
        do {
            let model = try VNCoreMLModel(for: yolov5_Medium(configuration: MLModelConfiguration()).model)
            print("YOLOV5 loaded!")
            self.detectionRequest = VNCoreMLRequest(model: model)
            
            self.ready = true
            
        } catch let error {
            fatalError("failed to setup model: \(error)")
        }
    }
    
    func detectAndProcess(image:CIImage)-> [ProcessedObservation]{
        
        let observations = self.detect(image: image)
        
        let processedObservations = self.processObservation(observations: observations, viewSize: image.extent.size)
        //print("Detect results contains\(processedObservations.count)")
        return processedObservations
    }
    
    
    func detect(image:CIImage) -> [VNObservation]{
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do{
            if self.detectionRequest != nil
            {
                try handler.perform([self.detectionRequest])
                let observations = self.detectionRequest.results!
                
                return observations
            }
            else{
                return []
            }
            
        }catch let error{
            //fatalError("failed to detect: \(error)")
            return []
        }
        
    }
    
    
    func processObservation(observations:[VNObservation], viewSize:CGSize) -> [ProcessedObservation]{
       
        var processedObservations:[ProcessedObservation] = []
        
        for observation in observations where observation is VNRecognizedObjectObservation {
            
            let objectObservation = observation as! VNRecognizedObjectObservation
            
            let conf=objectObservation.confidence
            
            if Float(conf)<Settings.instance.yoloConfidenceThreshold{
                continue
            }
            
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(viewSize.width), Int(viewSize.height))
            
            let flippedBox = CGRect(x: objectBounds.minX, y: viewSize.height - objectBounds.maxY, width: objectBounds.maxX - objectBounds.minX, height: objectBounds.maxY - objectBounds.minY)
            
            let label = objectObservation.labels.first!.identifier
            
            let processedOD = ProcessedObservation(label: label, confidence: objectObservation.confidence, boundingBox: flippedBox)
            
            processedObservations.append(processedOD)
        }
        
        return processedObservations
        
    }
    
}

struct ProcessedObservation{
    var label: String
    var confidence: Float
    var boundingBox: CGRect
}

@objc class Prediction : NSObject {
    @objc let classIndex: Int
    @objc let score: Float
    @objc var rect: CGRect
    
    public init(classIndex: Int,
     score: Float,
     rect: CGRect) {
        self.classIndex = classIndex
        self.score = score
        self.rect = rect
    }
}

