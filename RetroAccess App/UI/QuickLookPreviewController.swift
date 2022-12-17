//
//  QuickLookPreviewController.swift
//  RetroAccess App
//
//  Created by Xia Su on 10/5/22.
//

import Foundation
import QuickLook

public class QuickLookPreviewController:QLPreviewController, QLPreviewControllerDataSource{
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        //guard let url = Bundle.main.url(forResource: "SavedModel", withExtension: "usdz") else {
                //fatalError("Could not load model")
            //}
        let url=Settings.instance.modelURL
            return url! as QLPreviewItem
    }
    
    //let previewController = QLPreviewController()
    
    override public func viewDidLoad() {
        
        //guard let url = Bundle.main.url(forResource: "SavedModel", withExtension: "usdz") else {
                //fatalError("Could not load model file")
            //}
        super.viewDidLoad()
        dataSource=self
        //previewController.dataSource = self
        //present(previewController, animated: true)
        //previewController.
        //previewController.currentPreviewItem = url as QLPreviewItem
    }
}
 
