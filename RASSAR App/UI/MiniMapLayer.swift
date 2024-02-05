//
//  MiniMapLayer.swift
//  RetroAccess App
//
//  Created by Xia Su on 1/15/23.
// This file is for a layer which replicates all detected objects in roomplan api and show them in a 2d view. The view goes around as user move and rotate.

import Foundation
import UIKit
import RoomPlan

public class MiniMapLayer:CALayer{
    public var replicator:RoomObjectReplicator
    public var session:RoomCaptureSession
    var rootLayer:CALayer
    var selfLayer:CALayer?
    var radius:Float
    var trans:Transform2D?
    var outlineLayer:CALayer?
    var xdir:Vector2D?
    var ydir:Vector2D?
    var xrange:Range2D?
    var yrange:Range2D?
    var outlineCenter:Vector2D?
    var longestWall:RoomSurfaceAnchor?
    
    init(replicator: RoomObjectReplicator, session: RoomCaptureSession,radius:Float,center:CGPoint) {
        self.replicator = replicator
        self.session = session
        self.radius=radius
        self.rootLayer=CALayer()
        self.rootLayer.bounds = CGRect(x: 0, y: 0, width:CGFloat(radius*2), height: CGFloat(radius*2))
        self.rootLayer.position = CGPoint(x: center.x, y: center.y)
        super.init()
        self.addSublayer(rootLayer)
        draw()
        //self.bounds = CGRect(x: 0, y: 0, width:CGFloat(radius*2), height: CGFloat(radius*2))
        //self.position = CGPoint(x: center.x, y: center.y)
        //self.backgroundColor=CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.9, 0.9, 0.9, 0.1])
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func draw(){
        //Draw this layer here. Only call this function when there are changes in detected results.
        self.rootLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        if replicator.trackedSurfaceAnchors.count==0{
            //Need at least one surface to start drawing
            return
        }
        generate_outline()
        draw_surfaces()
        draw_furnitures()
        draw_issues()
        draw_self()
    }
    func generate_outline(){
        //Generate the floor layer, which is a rectangular outline for all detected walls. Leave some reasonable edge
        xdir=get_x_of_coordinates()
        ydir=xdir!.get_vertical()
        xrange=Range2D()
        yrange=Range2D()
        for surface in replicator.trackedSurfaceAnchors{
            let centerCoordinatesOriginal=Vector2D(xvalue: surface.transform.columns.3.x, yvalue: surface.transform.columns.3.z)
            let dirOriginal=Vector2D(xvalue: surface.transform.columns.0.x, yvalue: surface.transform.columns.0.z)
            //First find the center point position
            let centerX=centerCoordinatesOriginal.dot(other: xdir!)
            let centerY=centerCoordinatesOriginal.dot(other: ydir!)
            let xdiff=surface.dimensions.x*dirOriginal.dot(other: xdir!)
            let ydiff=surface.dimensions.x*dirOriginal.dot(other: ydir!)
            xrange!.addValue(value: centerX+xdiff/2)
            xrange!.addValue(value: centerX-xdiff/2)
            yrange!.addValue(value: centerY+ydiff/2)
            yrange!.addValue(value: centerY-ydiff/2)
        }
        for object in replicator.trackedObjectAnchors{
            let centerCoordinatesOriginal=Vector2D(xvalue: object.transform.columns.3.x, yvalue: object.transform.columns.3.z)
            let dirOriginal=Vector2D(xvalue: object.transform.columns.0.x, yvalue: object.transform.columns.0.z)
            //First find the center point position
            let centerX=centerCoordinatesOriginal.dot(other: xdir!)
            let centerY=centerCoordinatesOriginal.dot(other: ydir!)
            let xxdiff=abs(object.dimensions.x*dirOriginal.dot(other: xdir!))
            let xydiff=abs(object.dimensions.x*dirOriginal.dot(other: ydir!))
            let yxdiff=abs(object.dimensions.z*dirOriginal.dot(other: xdir!))
            let yydiff=abs(object.dimensions.z*dirOriginal.dot(other: ydir!))
            xrange!.addValue(value: centerX+xxdiff/2+yxdiff/2)
            xrange!.addValue(value: centerX-xxdiff/2-yxdiff/2)
            yrange!.addValue(value: centerY+xydiff/2+yydiff/2)
            yrange!.addValue(value: centerY-xydiff/2-yydiff/2)
        }
        //Expand the ranges to make sure outline surrounds shapes
        xrange!.expand(value: 1)
        yrange!.expand(value: 1)
        //After this enumerating, now the xrange and y range are the outer bounding box of the scan results
        //Then calculate a transform to make sure all things are resized and middled
        var scale=2*radius/Vector2D(xvalue: xrange!.len(), yvalue: yrange!.len()).len()
        let centerCoordinates=Vector2D(xvalue: xrange!.mid(), yvalue: yrange!.mid())
        //Then transform this center to original coordinates and compare it with (0,0)
        let centerCoordinatesOriginal=Vector2D(xvalue: centerCoordinates.x*xdir!.x+centerCoordinates.y*ydir!.x, yvalue: centerCoordinates.y*ydir!.y+centerCoordinates.x*xdir!.y)
        outlineCenter=centerCoordinatesOriginal
        var translate=Vector2D(xvalue: -centerCoordinatesOriginal.x*scale+radius, yvalue: -centerCoordinatesOriginal.y*scale+radius)
        
        trans=Transform2D(rotation: 0, scale: scale, translate: translate)
        //Then use the calculated transform to draw the layer
        let outline=CALayer()
        outline.bounds = trans!.transform(bound:CGRect(x: CGFloat(xrange!.mid()), y: CGFloat(yrange!.mid()), width: CGFloat(xrange!.len()), height: CGFloat(yrange!.len())))
        outline.backgroundColor=CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.9, 0.9, 0.9, 1])
        outline.position=CGPoint(x: CGFloat(radius),y: CGFloat(radius))
        outline.cornerRadius=2
        let angle=get_angle_of_vector(a: xdir!.x,b: xdir!.y)
        let rotation = CATransform3DMakeRotation(CGFloat(angle), 0, 0, 1)
        outline.transform = rotation
        self.rootLayer.addSublayer(outline)
        outlineLayer=outline
    }
    func get_x_of_coordinates()->Vector2D{
        //Calculate an approx xy direction with wall orientation. The optimal solution might be too complex, so just use the longest wall.
        //The returned value is the cos and sin value of the wall direction. Or you can also use it as a normalized vector indicating the direction.
        var wall:RoomSurfaceAnchor?=nil
        var length:Float=0.0
        for surface in replicator.trackedSurfaceAnchors{ //There is at least one surface!
            if surface.dimensions.x>length{
                wall=surface
                length=surface.dimensions.x
            }
        }
        longestWall=wall
        //Then just use the longest wall to mark the x and y
        //var x=longest_wall?.transform.
        return Vector2D(xvalue: wall!.transform.columns.0.x,yvalue: wall!.transform.columns.0.z)
    }
    func calculate_transform(){
        //Calculate how to transform the shapes to match the max radius
        
    }
    func draw_surfaces(){
        //Use line in differrent colors to draw wall, opening and window
        for surf in replicator.trackedSurfaceAnchors{
            //Draw wall first
            if surf.category != .wall{
                continue
            }
            let layer=CALayer()
            layer.bounds=CGRect(x: 0, y: 0, width: CGFloat(surf.dimensions.x*trans!.scale), height:CGFloat( 2.5))
            
            layer.position=trans!.transform(pos:  CGPoint(x: CGFloat(surf.transform.columns.3.x), y: CGFloat(surf.transform.columns.3.z)))
            layer.backgroundColor=CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0, 0, 0, 1])
            //layer.position=CGPoint(x: CGFloat(radius),y: CGFloat(radius))
            let angle=get_angle_of_vector(a: surf.transform.columns.0.x,b: surf.transform.columns.0.z)
            //print("Calculated angle for a wall, which is \(angle)")
            let rotation = CATransform3DMakeRotation(CGFloat(angle), 0, 0, 1)
            layer.transform = rotation
            self.rootLayer.addSublayer(layer)
        }
        for surf in replicator.trackedSurfaceAnchors{
            //Draw windows
            if surf.category != .window{
                continue
            }
            let layer=CALayer()
            layer.bounds=CGRect(x: 0, y: 0, width: CGFloat(surf.dimensions.x*trans!.scale), height:CGFloat( 3))
            layer.backgroundColor=CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0, 0.81, 0.93, 1])
            layer.position=trans!.transform(pos:  CGPoint(x: CGFloat(surf.transform.columns.3.x), y: CGFloat(surf.transform.columns.3.z)))
            let angle=get_angle_of_vector(a: surf.transform.columns.0.x,b: surf.transform.columns.0.z)
            //print("Calculated angle for a window, which is \(angle)")
            let rotation = CATransform3DMakeRotation(CGFloat(angle), 0, 0, 1)
            layer.transform = rotation
            self.rootLayer.addSublayer(layer)
        }
        for surf in replicator.trackedSurfaceAnchors{
            //Draw door/opening
            if surf.category != .opening && surf.category != .door(isOpen: true) && surf.category != .door(isOpen: false){
                continue
            }
            let layer=CALayer()
            layer.bounds=CGRect(x: 0, y: 0, width: CGFloat(surf.dimensions.x*trans!.scale), height:CGFloat( 3))
            layer.backgroundColor=CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.91, 0.77, 0, 1])
            layer.position=trans!.transform(pos:  CGPoint(x: CGFloat(surf.transform.columns.3.x), y: CGFloat(surf.transform.columns.3.z)))
            let angle=get_angle_of_vector(a: surf.transform.columns.0.x,b: surf.transform.columns.0.z)
            //print("Calculated angle for a opening, which is \(angle)")
            let rotation = CATransform3DMakeRotation(CGFloat(angle), 0, 0, 1)
            layer.transform = rotation
            self.rootLayer.addSublayer(layer)
        }
        
    }
    func draw_furnitures(){
        for furniture in replicator.trackedObjectAnchors{
            let layer=CALayer()
            layer.bounds=CGRect(x: 0, y: 0, width: CGFloat(furniture.dimensions.x*trans!.scale), height:CGFloat(furniture.dimensions.z*trans!.scale))
            layer.backgroundColor=CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.7, 0.7, 0.7, 1])
            layer.position=trans!.transform(pos:  CGPoint(x: CGFloat(furniture.transform.columns.3.x), y: CGFloat(furniture.transform.columns.3.z)))
            layer.cornerRadius=1
            let angle=get_angle_of_vector(a: furniture.transform.columns.0.x,b: furniture.transform.columns.0.z)
            //print("Calculated angle for a \(furniture.getCategoryName()), which is \(angle)")
            let rotation = CATransform3DMakeRotation(CGFloat(angle), 0, 0, 1)
            layer.transform = rotation
            self.rootLayer.addSublayer(layer)
        }
    }
    func draw_issues(){
        for issue in replicator.getAllIssuesToBePresented(){
            //continue
            if !issue.hasPosition(){
                continue
            }
            if issue.cancelled{
                continue
            }
            let circleLayer = CAShapeLayer()
            let radius: CGFloat = 2
            circleLayer.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 2.0 * radius, height: 2.0 * radius), cornerRadius: radius).cgPath
            circleLayer.position = trans!.transform(pos:  CGPoint(x: CGFloat(issue.getPosition().x), y: CGFloat(issue.getPosition().z)))
            circleLayer.fillColor = UIColor.red.cgColor
            self.rootLayer.addSublayer(circleLayer)
        }
    }
    func draw_self(){
        //Draw a little triangle showing the position of scanner and its facing direction
        let triangleLayer=CAShapeLayer()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 6, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -4))
        path.addLine(to: CGPoint(x: -6, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.position = trans!.transform(pos:  CGPoint(x: CGFloat(session.arSession.currentFrame!.camera.transform.columns.3.x), y: CGFloat(session.arSession.currentFrame!.camera.transform.columns.3.z)))
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.orange.cgColor
        
        self.rootLayer.addSublayer(shapeLayer)
        selfLayer=shapeLayer
    }
    public func update(){
        draw()
    }
    public func isDrawn()->Bool{
        if let layers=self.rootLayer.sublayers{
            if layers.count>1{
                return true
            }
        }
        return false
    }
    public func set_rotation(angle:Float){
        let rotation = CATransform3DMakeRotation(CGFloat(angle), 0, 0, 1)
        let rotation_self = CATransform3DMakeRotation(CGFloat(-angle), 0, 0, 1)
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        rootLayer.transform=rotation
        if let selfIndicator=selfLayer{
            selfIndicator.transform=rotation_self
        }
        CATransaction.commit()
    }
}

class Vector2D{
    var x:Float
    var y:Float
    init (xvalue:Float,yvalue:Float){
        x=xvalue
        y=yvalue
    }
    func dot(other:Vector2D)->Float{
        return x*other.x+y*other.y
    }
    func get_vertical()->Vector2D{
        return Vector2D(xvalue: -y,yvalue: x)
    }
    func len()->Float{
        return sqrtf(x*x+y*y)
    }
}
class Range2D{
    var max:Float
    var min:Float
    init(){
        max=0
        min=0
    }
    func addValue(value:Float){
        if value>max{
            max=value
        }
        if value<min{
            min=value
        }
    }
    func len()->Float{
        return max-min
    }
    func mid()->Float{
        return (max+min)/2
    }
    func expand(value:Float){
        self.max+=abs(value)
        self.min-=abs(value)
    }
}
class Transform2D{
    var rotation:Float
    var scale:Float
    var translate:Vector2D
    init(rotation: Float, scale: Float, translate: Vector2D) {
        self.rotation = rotation
        self.scale = scale
        self.translate = translate
    }
    func transform(bound:CGRect)->CGRect{
        //Return the transformed rectangle
        var transformed=CGRect(x: bound.origin.x*CGFloat(scale), y: bound.origin.y*CGFloat(scale), width: bound.width*CGFloat(scale), height: bound.height*CGFloat(scale))
        return transformed
    }
    func transform(pos:CGPoint)->CGPoint{
        var transformed=CGPoint(x: pos.x*CGFloat(scale)+CGFloat(self.translate.x), y: pos.y*CGFloat(scale)+CGFloat(self.translate.y))
        return transformed
    }
}
func get_angle_of_vector(a:Float,b:Float)->Float{
    //Get the angle of a normalized vector in randians!
    var angle = atan2f(b, a)
    if angle<0{
        angle += .pi*2
    }
    return angle
}

