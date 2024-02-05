//
//  OnboardViewController.swift
//  RetroAccess App
//
//  Created by Xia Su on 7/26/22.
//
import UIKit
class OnboardViewController: UIViewController {
//This VC includes buttons and options for user to customize their scan experience.
    //@IBOutlet var communityPicker:UIPickerView!
    var CB_WheelChair: CheckBox!
    var CB_BLV: CheckBox!
    var CB_Senior: CheckBox!
    var CB_Children: CheckBox!
    var selected:String="null"
    @IBOutlet weak var BLVAssistanceToggle: UISwitch!
    let communities=["Please select one community","Blind or Low Vision People","Children","Older Adults","Wheelchair Users"]
    let screenSize: CGRect = UIScreen.main.bounds
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled=true
        //Add the 4 checkboxes to view
//        var view = CALayer()
//        view.frame = CGRect(x:  (screenSize.width-230)/2, y: 376, width: 230, height: 340)
//        //view.backgroundColor=UIColor.gray
//        //view.layer.position=CGPoint(x: (screenSize.width-230)/2, y: 376)
//        //view.backgroundColor = .white
        var parent = self.view!
//        parent.layer.addSublayer(view)
//        view.translatesAutoresizingMaskIntoConstraints = false
//        view.widthAnchor.constraint(equalToConstant: 230).isActive = true
//        view.heightAnchor.constraint(equalToConstant: 340).isActive = true
//        view.centerXAnchor.constraint(equalTo: parent.centerXAnchor, constant: 0).isActive = true
//        view.topAnchor.constraint(equalTo: parent.topAnchor, constant: 376).isActive = true
        //view.isUserInteractionEnabled=false
        CB_BLV=CheckBox()
        CB_Senior=CheckBox()
        CB_Children=CheckBox()
        CB_WheelChair=CheckBox()
        
        
        CB_WheelChair.setContent(name:"Wheelchair User",img_name: "Wheelchair",position: CGPoint(x: (screenSize.width-230)/2, y:376 + 24))
        CB_BLV.setContent(name:"Blind/Low Vision",img_name: "BLV",position: CGPoint(x: (screenSize.width-230)/2, y: 376 + 108))
        CB_Senior.setContent(name:"Older Adults",img_name: "Senior",position: CGPoint(x: (screenSize.width-230)/2, y: 376+192))
        CB_Children.setContent(name:"Children",img_name: "Children",position: CGPoint(x: (screenSize.width-230)/2, y: 376+276))
        //view.addSubview(CB_BLV)
        //view.addSubview(CB_Senior)
        //view.addSubview(CB_Children)
        //view.addSubview(CB_WheelChair)
        //communityPicker.dataSource=self
        //communityPicker.delegate=self
        //self.view.addSubview(view)
        self.view.addSubview(CB_WheelChair)
        self.view.addSubview(CB_BLV)
        self.view.addSubview(CB_Senior)
        self.view.addSubview(CB_Children)
        // Button
        var button = UIButton(frame:CGRect(x: (screenSize.width-171)/2, y: (screenSize.height-100), width: 171, height: 55))
        //button.layer.position=CGPoint(x: (screenSize.width-230)/2, y: 788)
        
        //button.backgroundColor = .gray
        var shadows = UIView()
        shadows.frame = CGRect(x: 0, y: 0, width: 171, height: 55)
        shadows.clipsToBounds = false
        shadows.isUserInteractionEnabled=false
        button.addSubview(shadows)
        let shadowPath0 = UIBezierPath(roundedRect: shadows.bounds, cornerRadius: 72)
        let layer0 = CALayer()
        layer0.shadowPath = shadowPath0.cgPath
        layer0.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2).cgColor
        layer0.shadowOpacity = 1
        layer0.shadowRadius = 40
        layer0.shadowOffset = CGSize(width: 0, height: 16)
        layer0.frame = CGRect(x: 0, y: 0, width: 171, height: 55)
        //layer0.position = CGPoint(x: 0, y: 0)
        shadows.layer.addSublayer(layer0)

        var shapes = UIView()
        shapes.frame = CGRect(x: 0, y: 0, width: 171, height: 55)
        shapes.clipsToBounds = true
        button.addSubview(shapes)

        let layer1 = CALayer()
        layer1.backgroundColor = UIColor(red: 0.122, green: 0.216, blue: 0.267, alpha: 1).cgColor
        layer1.bounds = shapes.bounds
        layer1.position = shapes.center
        shapes.layer.addSublayer(layer1)
        shapes.layer.cornerRadius = 27
        button.setTitle("Start Scanning", for: .normal)
        button.accessibilityLabel="Start Scanning"
        shapes.isUserInteractionEnabled=false
        self.view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 171).isActive = true
        button.heightAnchor.constraint(equalToConstant: 55).isActive = true
        button.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: (screenSize.width-171)/2).isActive = true
        button.topAnchor.constraint(equalTo: parent.topAnchor, constant: (screenSize.height-100)).isActive = true
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
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
        //if selected=="null"{
        if CB_WheelChair.isChecked == false && CB_BLV.isChecked == false && CB_Senior.isChecked == false && CB_Children.isChecked == false{
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
            Settings.instance.community=[]
            if CB_WheelChair.isChecked{
                Settings.instance.community.append(.wheelchair)
            }
            if CB_BLV.isChecked{
                Settings.instance.community.append(.BLV)
            }
            if CB_Senior.isChecked{
                Settings.instance.community.append(.elder)
            }
            if CB_Children.isChecked{
                Settings.instance.community.append(.children)
            }
            if BLVAssistanceToggle.isOn{
                Settings.instance.BLVAssistance=true
            }
            viewController.modalPresentationStyle = .fullScreen
            present(viewController, animated: true)
        }
    }
}
//extension OnboardViewController:UIPickerViewDataSource{
//    func numberOfComponents(in pickerView: UIPickerView) -> Int {
//        return 1
//    }
//
//    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//        return communities.count
//    }
//
//
//}
//extension OnboardViewController:UIPickerViewDelegate{
//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        return communities[row]
//    }
//    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        if row==0{
//            selected="null"
//        }
//        else
//        {selected=communities[row]}
//        //TODO: add some extra input UI here to get children height information, if Children selected
//    }
//}

