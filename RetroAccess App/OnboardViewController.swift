//
//  OnboardViewController.swift
//  RetroAccess App
//
//  Created by Xia Su on 7/26/22.
//

import UIKit

class OnboardViewController: UIViewController {

    @IBOutlet var communityPicker:UIPickerView!
    var selected:String="null"
    let communities=["Please select one community","Blind or Low Vision","Children","Elder People","Wheelchair"]
    override func viewDidLoad() {
        super.viewDidLoad()
        communityPicker.dataSource=self
        communityPicker.delegate=self
        // Do any additional setup after loading the view.
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func didTapButton(){
        if selected=="null"{
            var dialogMessage = UIAlertController(title: "Error", message: "Please select a community before scanning.", preferredStyle: .alert)
            
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
             })
            
            //Add OK button to a dialog message
            dialogMessage.addAction(ok)
            // Present Alert to
            self.present(dialogMessage, animated: true, completion: nil)
        }
        else if let viewController = self.storyboard?.instantiateViewController(
            withIdentifier: "MainView") {
            Settings.instance.community=selected
            viewController.modalPresentationStyle = .fullScreen
            present(viewController, animated: true)
        }
    
    }
}
extension OnboardViewController:UIPickerViewDataSource{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return communities.count
    }
    
    
}
extension OnboardViewController:UIPickerViewDelegate{
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return communities[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row==0{
            selected="null"
        }
        else
        {selected=communities[row]}
        //TODO: add some extra input UI here to get children height information, if Children selected
    }
}

