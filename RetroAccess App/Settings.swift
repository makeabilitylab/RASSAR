//
//  Settings.swift
//  RetroAccess App
//
//  Created by Xia Su on 7/27/22.
//

import Foundation

class Settings{
    static let instance = Settings()
        
    private init() {
    }
        
    //creates the global variable
    var community:String="null"
    var height:Int=0
}
