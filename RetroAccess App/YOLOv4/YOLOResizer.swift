//
//  YOLOResizer.swift
//  RetroAccess App
//
//  Created by Xia Su on 9/23/22.
//

import Foundation
import ARKit
import UIKit
import RealityKit
enum CropPosition{
    case middle,left,right,up,bottom,topleft,topright,bottomleft,bottomright
}

class YOLOResizer{
    private var fullBufferSize:CGSize
    private var fullScreenSize:CGSize
    private var croppedBufferSize:CGSize
    private var croppingPosition:CropPosition
    private var rotateAngle:CGImagePropertyOrientation
    private var resizedPixelBuffer:CVPixelBuffer?
    var upperleftX:CGFloat=CGFloat(0)
    var upperleftY:CGFloat=CGFloat(0)
    var ciContext = CIContext()
    public init(fullBufferSize: CGSize, fullScreenSize: CGSize, croppedBufferSize: CGSize, croppingPosition:CropPosition,rotate:CGImagePropertyOrientation) {
        self.fullBufferSize = fullBufferSize
        self.fullScreenSize = fullScreenSize
        self.croppedBufferSize = croppedBufferSize
        self.croppingPosition=croppingPosition
        self.rotateAngle=rotate
        let status = CVPixelBufferCreate(nil, 416, 416,
                                         kCVPixelFormatType_32BGRA, nil,
                                         &resizedPixelBuffer)
        if status != kCVReturnSuccess {
            print("Error: could not create resized pixel buffer", status)
        }
        calculatePosition()
    }
    public init(fullBufferSize: CGSize, fullScreenSize: CGSize,croppingPosition:CropPosition,croppingRatio:Float,rotate:CGImagePropertyOrientation){
        self.fullBufferSize = fullBufferSize
        self.fullScreenSize = fullScreenSize
        self.croppingPosition=croppingPosition
        self.croppedBufferSize=CGSize(width:CGFloat(Float(fullBufferSize.width)*croppingRatio), height: CGFloat(Float(fullBufferSize.height)*croppingRatio))
        self.rotateAngle=rotate
        let status = CVPixelBufferCreate(nil, 416, 416,
                                         kCVPixelFormatType_32BGRA, nil,
                                         &resizedPixelBuffer)
        if status != kCVReturnSuccess {
            print("Error: could not create resized pixel buffer", status)
        }
        calculatePosition()
    }
    private func calculatePosition(){
        switch croppingPosition {
        case .middle:
            upperleftX=fullBufferSize.width/2-croppedBufferSize.width/2
            upperleftY=fullBufferSize.height/2-croppedBufferSize.height/2
        case .left:
            upperleftY=fullBufferSize.height/2-croppedBufferSize.height/2
        case .right:
            upperleftX=fullBufferSize.width-croppedBufferSize.width/2
            upperleftY=fullBufferSize.height/2-croppedBufferSize.height/2
        case .up:
            upperleftX=fullBufferSize.width/2-croppedBufferSize.width/2
        case .bottom:
            upperleftX=fullBufferSize.width/2-croppedBufferSize.width/2
            upperleftY=fullBufferSize.height-croppedBufferSize.height/2
        case .topleft:
            break
        case .topright:
            upperleftX=fullBufferSize.width-croppedBufferSize.width/2
        case .bottomleft:
            upperleftX=fullBufferSize.width-croppedBufferSize.width/2
        case .bottomright:
            upperleftX=fullBufferSize.width-croppedBufferSize.width/2
            upperleftY=fullBufferSize.height-croppedBufferSize.height/2
        }
    }
    public func resizeBuffer(buffer:CVPixelBuffer)->CVPixelBuffer{
        // Resize the input with Core Image.
        guard let resizedPixelBuffer = resizedPixelBuffer else { fatalError("Error when creating null buffer") }
        let ciImage = CIImage(cvPixelBuffer: buffer)
        //First rotate the image to right to make it same as view
        let rotatedImage=ciImage.oriented(.right)
        var croppedImage:CIImage
        //First crop
        let rect=CGRect(x: upperleftX, y: upperleftY, width: croppedBufferSize.width, height: croppedBufferSize.height)
        //let rect=CGRect(x: 400, y: 400, width: 416, height: 416)
        croppedImage=rotatedImage.cropped(to: rect)
        let sx = CGFloat(416) / CGFloat( croppedBufferSize.width)
        let sy = CGFloat(416) / CGFloat( croppedBufferSize.height)
        let scaleTransform = CGAffineTransform(scaleX: sx, y: sy)
        var scaledImage = croppedImage.transformed(by: scaleTransform)
        //ciContext.render(scaledImage, to: resizedPixelBuffer)
        let orientedImage=scaledImage.oriented(rotateAngle)
        let origin=orientedImage.extent.origin
        let translate=CGAffineTransform.identity
        //translate.translatedBy(x: -origin.x, y: -origin.y)
        let movedImage=orientedImage.transformed(by: translate.translatedBy(x: -origin.x, y: -origin.y))
        //ciContext.render(scaledImage, to: resizedPixelBuffer)
        ciContext.render(movedImage, to: resizedPixelBuffer)
        let resultRef=resizedPixelBuffer
        let cropImg=CIImage(cvImageBuffer: resizedPixelBuffer)
        return resizedPixelBuffer
    }
    public func resizeResults(initialResults:[Prediction])->[Prediction]{
        //Resize the results in cropped frame into the screen
        for result in initialResults{
            //var rect=result.rect
            //First rotate
            switch rotateAngle{
            case .left:
                break
            case .right:
                break
            case .up:
                break
            default:
                break
            }
            //Then scale and position
            let scaleX=croppedBufferSize.width/fullBufferSize.height*fullScreenSize.height
            let scaleY=croppedBufferSize.height/fullBufferSize.height*fullScreenSize.height
            let leftX=(fullBufferSize.width/fullBufferSize.height*fullScreenSize.height-fullScreenSize.width)/2
            result.rect.origin.x *= scaleX
            result.rect.origin.y *= scaleY
            result.rect.size.width *= scaleX
            result.rect.size.height *= scaleY
            //Move the rect
            result.rect.origin.x+=upperleftX/fullBufferSize.height*fullScreenSize.height-leftX
            result.rect.origin.y+=upperleftY/fullBufferSize.height*fullScreenSize.height
        }
        return initialResults
    }
    public func getNotifyingFrame()->CALayer{
//        let layer=CALayer()
        let leftX=(fullBufferSize.width/fullBufferSize.height*fullScreenSize.height-fullScreenSize.width)/2
        let screenUpperleftX=upperleftX/fullBufferSize.height*fullScreenSize.height-leftX
        let screenUpperleftY=upperleftY/fullBufferSize.height*fullScreenSize.height
        let scaleX=croppedBufferSize.width/fullBufferSize.height*fullScreenSize.height
        let scaleY=croppedBufferSize.height/fullBufferSize.height*fullScreenSize.height
//        layer.bounds=CGRect(x: screenUpperleftX, y: screenUpperleftY, width: scaleX, height: scaleY)
//        layer.position=CGPoint(x: screenUpperleftX+scaleX/2, y: screenUpperleftY+scaleY/2)
//        //layer.position=CGPoint()
//        layer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.9, 0.9, 0.9, 0.1])
        let path = UIBezierPath()
        path.move(to: CGPoint(x: screenUpperleftX, y: screenUpperleftY))
        path.addLine(to: CGPoint(x: screenUpperleftX+scaleX, y: screenUpperleftY))
        path.addLine(to: CGPoint(x: screenUpperleftX+scaleX, y: screenUpperleftY+scaleY))
        path.addLine(to: CGPoint(x: screenUpperleftX, y: screenUpperleftY+scaleY))
        path.addLine(to: CGPoint(x: screenUpperleftX, y: screenUpperleftY))
                
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.fillColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.9, 0.9, 0.9, 0.1])
        shapeLayer.lineWidth = 3
        return shapeLayer
    }
}
