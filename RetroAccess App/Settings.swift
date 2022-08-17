//
//  Settings.swift
//  RetroAccess App
//
//  Created by Xia Su on 7/27/22.
//

import Foundation

//This class stores all golbal settings, like all user selections done in thee onboarding view.
class Settings{
    static let instance = Settings()
        
    private init() {
    }
        
    //creates the global variable
    var community:String="null"
    var height:Int=0
    
    //Hyper parameters
    var dimension_tolerance=1
}
