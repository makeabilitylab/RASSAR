//
//  SCNViewController.swift
//  RetroAccess App
//
//  Created by Xia Su on 12/16/22.
//

//import Foundation
//import SceneKit
//import SwiftUI
//
//struct PostHocView: View {
//    var body: some View {
//        VStack {
//            SceneView(scene: SCNScene(named: "3dObjects/lowpoly.scn"), options: [.autoenablesDefaultLighting, .allowsCameraControl])
//            View()
//            
//        }
//    }
//}
//
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
//
//class BoxNode: SCNNode {
//
//    override init() {
//        super.init()
//        self.geometry = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.0)
//        
//        self.geometry?.firstMaterial?.shininess = 50
//        
//        let action = SCNAction.rotate(by: 360 * CGFloat(Double.pi / 180), around: SCNVector3(x:0, y:1, z:0), duration: 8)
//        
//        let repeatAction = SCNAction.repeatForever(action)
//        
//        self.runAction(repeatAction)
//        
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
//class BallNode: SCNNode {
//
//    override init() {
//        super.init()
//        self.geometry = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.0)
//        
//        self.geometry?.firstMaterial?.shininess = 50
//        
//        let action = SCNAction.rotate(by: 360 * CGFloat(Double.pi / 180), around: SCNVector3(x:0, y:1, z:0), duration: 8)
//        
//        let repeatAction = SCNAction.repeatForever(action)
//        
//        self.runAction(repeatAction)
//        
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
