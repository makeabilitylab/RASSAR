//
//  PopupView.swift
//  RetroAccess App
//
//  Created by Xia Su on 3/10/23.
//

import Foundation
import SwiftUI


//class PopupView: UIView {
//  var shouldSetupConstraints = true
//    
//  var bannerView: UIImageView!
//  var profileView: UIImageView!
//  var segmentedControl: UISegmentedControl!
//    
//  let screenSize = UIScreen.main.bounds
//  
//    override init(frame:CGRect,parent:UIViewController,issue:AccessibilityIssue){
//    super.init(frame: frame)
//        
//    bannerView = UIImageView(frame: CGRect.zero)
//    bannerView.backgroundColor = UIColor.gray
//        
//    bannerView.autoSetDimension(screenSize.height, toSize: screenSize.width / 3)
//    
//    self.addSubview(bannerView)
//        
//    profileView = UIImageView(frame: CGRect.zero)
//    profileView.backgroundColor = UIColor.gray
//    profileView.layer.borderColor = UIColor.white.cgColor
//    profileView.layer.borderWidth = 1.0
//    profileView.layer.cornerRadius = 5.0
//        
//    profileView.autoSetDimension(.width, toSize: 124.0)
//    profileView.autoSetDimension(.height, toSize: 124.0)
//    
//    self.addSubview(profileView)
//        
//    segmentedControl = UISegmentedControl(items: ["Tweets", "Media", "Likes"])
//        
//    self.addSubview(segmentedControl)
//  }
