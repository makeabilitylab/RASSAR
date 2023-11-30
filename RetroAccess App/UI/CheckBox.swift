//
//  CheckBox.swift
//  RetroAccess App
//
//  Created by Xia Su on 10/4/22.
//

import UIKit

class CheckBox: UIButton {
    var name:String=""
    var img_name:String=""
    var position:CGPoint=CGPoint(x: 0, y: 0)
    // Bool property
    var isChecked: Bool = false {
        didSet {
            //if isChecked == true {
                //self.layer.borderColor=UIColor.white.cgColor
                //self.layer.borderWidth=4
            //} else {
                //self.layer.borderColor=UIColor.gray.cgColor
                //self.layer.borderWidth=1
            //}
            show()
        }
    }
    override func awakeFromNib() {
        //self.addTarget(self, action:#selector(buttonClicked), for: UIControl.Event.touchUpInside)
        self.isChecked = false
        //self.layer.cornerRadius=5
        //self.layer.borderColor=UIColor.gray.cgColor
        //self.layer.borderWidth=1
        //self.frame = CGRect(x: 0, y: 0, width: 230, height: 64)

        //setContent()


    }
    private func show(){
        self.frame=CGRect(x: self.position.x, y: self.position.y, width: 230, height: 64)
        self.addTarget(self, action:#selector(buttonClicked), for: UIControl.Event.touchUpInside)
        //self.backgroundColor = .gray
        self.subviews.forEach({ $0.removeFromSuperview() })
        var shadows = UIView()
        shadows.frame = CGRect(x: 0, y: 0, width: 230, height: 64)
        shadows.clipsToBounds = false
        shadows.isUserInteractionEnabled=false
        self.addSubview(shadows)
        let shadowPath0 = UIBezierPath(roundedRect: shadows.bounds, cornerRadius: 16)
        let layer0 = CALayer()
        layer0.shadowPath = shadowPath0.cgPath
        layer0.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2).cgColor
        layer0.shadowOpacity = 1
        layer0.shadowRadius = 40
        layer0.shadowOffset = CGSize(width: 0, height: 16)
        layer0.bounds = shadows.bounds
        layer0.position = shadows.center
        shadows.layer.addSublayer(layer0)

        var shapes = UIView()
        shapes.frame = CGRect(x: 0, y: 0, width: 230, height: 64)
        shapes.clipsToBounds = true
        shapes.backgroundColor = .red
        shapes.isUserInteractionEnabled=false
        self.addSubview(shapes)

        let layer1 = CALayer()
        if isChecked{
            layer1.backgroundColor = UIColor(red: 0.123, green: 0.215, blue: 0.267, alpha: 1).cgColor
        }
        else{
            layer1.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        }
        layer1.frame = CGRect(x: 0, y: 0, width: 230, height: 64)
        shapes.layer.addSublayer(layer1)
        shapes.layer.cornerRadius = 16

        self.widthAnchor.constraint(equalToConstant: 230).isActive = true
        self.heightAnchor.constraint(equalToConstant: 64).isActive = true

        var text = UILabel()
        text.isUserInteractionEnabled=false
        text.frame = CGRect(x: 8, y: 16, width: 214, height: 30)
        if isChecked{
            text.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        }
        else{
            text.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        }
        //text.font = UIFont(name: "HalyardDisplay-Regular", size: 24)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 0.85
        text.textAlignment = .center
        let formattedString=NSMutableAttributedString(string: self.name, attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle,NSAttributedString.Key.font:UIFont.systemFont(ofSize: 22, weight: .bold)])
        let imageAttachment = NSTextAttachment()
        if isChecked{
            imageAttachment.image = UIImage(named: img_name)!.resizeImage(newSize: CGSize(width: 24, height: 24))
        }
        else{
            imageAttachment.image = UIImage(named: img_name)!.inverseImage(cgResult: true)!.resizeImage(newSize: CGSize(width: 24, height: 24))
        }
        let completeImageString = NSAttributedString(attachment: imageAttachment)
        formattedString.append(NSAttributedString(string: " "))
        formattedString.append(completeImageString)
        text.attributedText = formattedString
        text.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        shapes.addSubview(text)
        text.widthAnchor.constraint(equalToConstant: 214).isActive = true
        text.heightAnchor.constraint(equalToConstant: 28).isActive = true
        text.textAlignment = .center
    }
        
    @IBAction func buttonClicked() {
        //if sender == self {
            isChecked = !isChecked
        //}
        //print("Click")
    }
    public func setContent(name:String,img_name:String,position:CGPoint){
        //self.setImage(UIImage(named: img_name)! as UIImage, for: UIControl.State.normal)
        self.name=name
        self.img_name=img_name
        self.position=position
        self.accessibilityLabel=name
        show()
        //parent.addSubview(self)
        self.isUserInteractionEnabled=true
        //print(self.frame)
    }
}
extension UIImage{
    func resizeImage(newSize: CGSize) -> UIImage {
        // Guard newSize is different
        guard self.size != newSize else { return self }

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}
extension UIImage {
func inverseImage(cgResult: Bool) -> UIImage? {
    let coreImage = UIKit.CIImage(image: self)
    guard let filter = CIFilter(name: "CIColorInvert") else { return nil }
    filter.setValue(coreImage, forKey: kCIInputImageKey)
    guard let result = filter.value(forKey: kCIOutputImageKey) as? UIKit.CIImage else { return nil }
    if cgResult { // I've found that UIImage's that are based on CIImages don't work with a lot of calls properly
        return UIImage(cgImage: CIContext(options: nil).createCGImage(result, from: result.extent)!)
    }
    return UIImage(ciImage: result)
  }
}
