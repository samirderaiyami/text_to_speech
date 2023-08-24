//
//  Extentions.swift
//  LEDDemo
//
//  Created by Mac-0006 on 28/07/23.
//

import Foundation
import UIKit
import ImageIO

typealias alertActionHandler = ((UIAlertAction) -> ())?
typealias alertTextFieldHandler = ((UITextField) -> ())

extension UIColor {
    
    func adjustBrightness(factor: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        
        if self.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return UIColor(hue: h, saturation: s, brightness: b * factor, alpha: a)
        }
        return self
    }
}

extension UILabel {
    
    func startBlink(withSpeed: Double,withDensity: Double) {
        UIView.animate(withDuration: withSpeed,
                       delay:0.2,
                       options:[.allowUserInteraction, .curveEaseInOut, .autoreverse, .repeat],
                       animations: { self.alpha = withDensity },
                       completion: nil)
    }
    
    func stopBlink() {
        layer.removeAllAnimations()
        alpha = 1
    }
}
extension UIView
{
    
    // Using a function since `var image` might conflict with an existing variable
    // (like on `UIImageView`)
    func convertViewToImage() -> UIImage {
        if #available(iOS 10.0, *) {
            let renderer = UIGraphicsImageRenderer(bounds: bounds)
            return renderer.image { rendererContext in
                layer.render(in: rendererContext.cgContext)
            }
        } else {
            UIGraphicsBeginImageContext(self.frame.size)
            self.layer.render(in:UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return UIImage(cgImage: image!.cgImage!)
        }
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}



extension UIImage {
    
    public class func gifImageWithData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("image doesn't exist")
            return nil
        }
        
        return UIImage.animatedImageWithSource(source)
    }
    
    public class func gifImageWithURL(_ gifUrl:String) -> UIImage? {
        guard let bundleURL:URL? = URL(string: gifUrl)
        else {
            print("image named \"\(gifUrl)\" doesn't exist")
            return nil
        }
        guard let imageData = try? Data(contentsOf: bundleURL!) else {
            print("image named \"\(gifUrl)\" into NSData")
            return nil
        }
        
        return gifImageWithData(imageData)
    }
    
    public class func gifImageWithName(_ name: String) -> UIImage? {
        guard let bundleURL = Bundle.main
            .url(forResource: name, withExtension: "gif") else {
            print("SwiftGif: This image named \"\(name)\" does not exist")
            return nil
        }
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            print("SwiftGif: Cannot turn image named \"\(name)\" into NSData")
            return nil
        }
        
        return gifImageWithData(imageData)
    }
    
    class func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double {
        var delay = 0.1
        
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifProperties: CFDictionary = unsafeBitCast(
            CFDictionaryGetValue(cfProperties,
                                 Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()),
            to: CFDictionary.self)
        
        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(gifProperties,
                                 Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
            to: AnyObject.self)
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                                                             Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }
        
        delay = delayObject as! Double
        
        if delay < 0.1 {
            delay = 0.1
        }
        
        return delay
    }
    
    class func gcdForPair(_ a: Int?, _ b: Int?) -> Int {
        var a = a
        var b = b
        if b == nil || a == nil {
            if b != nil {
                return b!
            } else if a != nil {
                return a!
            } else {
                return 0
            }
        }
        
        if a < b {
            let c = a
            a = b
            b = c
        }
        
        var rest: Int
        while true {
            rest = a! % b!
            
            if rest == 0 {
                return b!
            } else {
                a = b
                b = rest
            }
        }
    }
    
    class func gcdForArray(_ array: Array<Int>) -> Int {
        if array.isEmpty {
            return 1
        }
        
        var gcd = array[0]
        
        for val in array {
            gcd = UIImage.gcdForPair(val, gcd)
        }
        
        return gcd
    }
    
    class func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        var delays = [Int]()
        
        for i in 0..<count {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(image)
            }
            
            let delaySeconds = UIImage.delayForImageAtIndex(Int(i),
                                                            source: source)
            delays.append(Int(delaySeconds * 1000.0)) // Seconds to ms
        }
        
        let duration: Int = {
            var sum = 0
            
            for val: Int in delays {
                sum += val
            }
            
            return sum
        }()
        
        let gcd = gcdForArray(delays)
        var frames = [UIImage]()
        
        var frame: UIImage
        var frameCount: Int
        for i in 0..<count {
            frame = UIImage(cgImage: images[Int(i)])
            frameCount = Int(delays[Int(i)] / gcd)
            
            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }
        
        let animation = UIImage.animatedImage(with: frames,
                                              duration: Double(duration) / 1000.0)
        
        return animation
    }
}

// MARK: - Extension of UIViewController For AlertView with Different Numbers of Buttons
extension UIViewController {
    
    /// This Method is used to show AlertView with one Button.
    ///
    /// - Parameters:
    ///   - alertTitle: A String value that indicates the title of AlertView , it is Optional so you can pass nil if you don't want Alert Title.
    ///   - alertMessage: A String value that indicates the title of AlertView , it is Optional so you can pass nil if you don't want alert message.
    ///   - btnOneTitle: A String value - Title of button.
    ///   - btnOneTapped: Button Tapped Handler (Optional - you can pass nil if you don't want any action).
    func presentAlertViewWithOneButton(alertTitle: String?, alertMessage: String?, btnOneTitle: String, btnOneTapped: alertActionHandler) {
        
        let alertController = UIAlertController(title: alertTitle ?? "", message: alertMessage ?? "", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: btnOneTitle, style: .default, handler: btnOneTapped))
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds),0,0)
        self.present(alertController, animated: true, completion: nil)
    }
    
    /// This Method is used to show AlertView with two Buttons.
    ///
    /// - Parameters:
    ///   - alertTitle: A String value that indicates the title of AlertView , it is Optional so you can pass nil if you don't want Alert Title.
    ///   - alertMessage: A String value that indicates the title of AlertView , it is Optional so you can pass nil if you don't want alert message.
    ///   - btnOneTitle: A String value - Title of button one.
    ///   - btnOneTapped: Button One Tapped Handler (Optional - you can pass nil if you don't want any action).
    ///   - btnTwoTitle: A String value - Title of button two.
    ///   - btnTwoTapped: Button Two Tapped Handler (Optional - you can pass nil if you don't want any action).
    func presentAlertViewWithTwoButtons(alertTitle: String?, alertMessage: String?, btnOneTitle: String, btnOneTapped: alertActionHandler, btnTwoTitle: String, btnTwoTapped: alertActionHandler) {
        
        let alertController = UIAlertController(title: alertTitle ?? "", message: alertMessage ?? "", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: btnOneTitle, style: .default, handler: btnOneTapped))
        alertController.addAction(UIAlertAction(title: btnTwoTitle, style: .default, handler: btnTwoTapped))
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds),0,0)
        self.present(alertController, animated: true, completion: nil)
    }
    
    /// This Method is used to show AlertView with three Buttons.
    ///
    /// - Parameters:
    ///   - alertTitle: A String value that indicates the title of AlertView , it is Optional so you can pass nil if you don't want Alert Title.
    ///   - alertMessage: A String value that indicates the title of AlertView , it is Optional so you can pass nil if you don't want alert message.
    ///   - btnOneTitle: A String value - Title of button one.
    ///   - btnOneTapped: Button One Tapped Handler (Optional - you can pass nil if you don't want any action).
    ///   - btnTwoTitle: A String value - Title of button two.
    ///   - btnTwoTapped: Button Two Tapped Handler (Optional - you can pass nil if you don't want any action).
    ///   - btnThreeTitle: A String value - Title of button three.
    ///   - btnThreeTapped: Button Three Tapped Handler (Optional - you can pass nil if you don't want any action).
    func presentAlertViewWithThreeButtons(alertTitle: String?, alertMessage: String?, btnOneTitle: String, btnOneTapped: alertActionHandler, btnTwoTitle: String, btnTwoTapped: alertActionHandler, btnThreeTitle: String, btnThreeTapped: alertActionHandler) {
        
        let alertController = UIAlertController(title: alertTitle ?? "", message: alertMessage ?? "", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: btnOneTitle, style: .default, handler: btnOneTapped))
        alertController.addAction(UIAlertAction(title: btnTwoTitle, style: .default, handler: btnTwoTapped))
        alertController.addAction(UIAlertAction(title: btnThreeTitle, style: .default, handler: btnThreeTapped))
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds),0,0)
        self.present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Extension of UIViewController For AlertView with Different Numbers of UITextField and with Two Buttons.
extension UIViewController {
    
    /// This Method is used to show AlertView with one TextField and with Two Buttons.
    ///
    /// - Parameters:
    ///   - alertTitle: A String value that indicates the title of AlertView , it is Optional so you can pass nil if you don't want Alert Title.
    ///   - alertMessage: A String value that indicates the title of AlertView , it is Optional so you can pass nil if you don't want alert message.
    ///   - alertFirstTextFieldHandler: TextField Handler , you can directlly get the object of UITextField.
    ///   - btnOneTitle: A String value - Title of button one.
    ///   - btnOneTapped: Button One Tapped Handler (Optional - you can pass nil if you don't want any action).
    ///   - btnTwoTitle: A String value - Title of button two.
    ///   - btnTwoTapped: Button Two Tapped Handler (Optional - you can pass nil if you don't want any action).
    func presentAlertViewWithOneTextField(alertTitle: String?, alertMessage: String?, alertFirstTextFieldHandler: @escaping alertTextFieldHandler, btnOneTitle: String, btnOneTapped: alertActionHandler, btnTwoTitle: String, btnTwoTapped: alertActionHandler) {
        
        let alertController = UIAlertController(title: alertTitle ?? "", message: alertMessage ?? "", preferredStyle: .alert)
        alertController.addTextField { (alertTextField) in
            alertFirstTextFieldHandler(alertTextField)
        }
        alertController.addAction(UIAlertAction(title: btnOneTitle, style: .default, handler: btnOneTapped))
        alertController.addAction(UIAlertAction(title: btnTwoTitle, style: .default, handler: btnTwoTapped))
        alertController.popoverPresentationController?.sourceView = self.view
        self.present(alertController, animated: true, completion: nil)
    }
    
    /// This Method is used to show AlertView with two TextField and with Two Buttons.
    ///
    /// - Parameters:
    ///   - alertTitle: A String value that indicates the title of AlertView , it is Optional so you can pass nil if you don't want Alert Title.
    ///   - alertMessage: A String value that indicates the title of AlertView , it is Optional so you can pass nil if you don't want alert message.
    ///   - alertFirstTextFieldHandler: First TextField Handeler , you can directlly get the object of First UITextField.
    ///   - alertSecondTextFieldHandler: Second TextField Handeler , you can directlly get the object of Second UITextField.
    ///   - btnOneTitle: A String value - Title of button one.
    ///   - btnOneTapped: Button One Tapped Handler (Optional - you can pass nil if you don't want any action).
    ///   - btnTwoTitle: A String value - Title of button two.
    ///   - btnTwoTapped: Button Two Tapped Handler (Optional - you can pass nil if you don't want any action).
    func presentAlertViewWithTwoTextFields(alertTitle: String?, alertMessage: String?, alertFirstTextFieldHandler: @escaping alertTextFieldHandler, alertSecondTextFieldHandler: @escaping alertTextFieldHandler, btnOneTitle: String, btnOneTapped: alertActionHandler, btnTwoTitle: String, btnTwoTapped: alertActionHandler) {
        
        let alertController = UIAlertController(title: alertTitle ?? "", message: alertMessage ?? "", preferredStyle: .alert)
        
        alertController.addTextField { (alertFirstTextField) in
            alertFirstTextFieldHandler(alertFirstTextField)
        }
        alertController.addTextField { (alertSecondTextField) in
            alertSecondTextFieldHandler(alertSecondTextField)
        }
        alertController.addAction(UIAlertAction(title: btnOneTitle, style: .default, handler: btnOneTapped))
        alertController.addAction(UIAlertAction(title: btnTwoTitle, style: .default, handler: btnTwoTapped))
        alertController.popoverPresentationController?.sourceView = self.view
        self.present(alertController, animated: true, completion: nil)
    }
    
    /// This Method is used to show AlertView with three TextField and with Two Buttons.
    ///
    /// - Parameters:
    ///   - alertTitle: A String value that indicates the title of AlertView , it is Optional so you can pass nil if you don't want Alert Title.
    ///   - alertMessage: A String value that indicates the title of AlertView , it is Optional so you can pass nil if you don't want alert message.
    ///   - alertFirstTextFieldHandler: First TextField Handeler , you can directlly get the object of First UITextField.
    ///   - alertSecondTextFieldHandler: Second TextField Handeler , you can directlly get the object of Second UITextField.
    ///   - alertThirdTextFieldHandler: Third TextField Handeler , you can directlly get the object of Third UITextField.
    ///   - btnOneTitle:  A String value - Title of button one.
    ///   - btnOneTapped: Button One Tapped Handler (Optional - you can pass nil if you don't want any action).
    ///   - btnTwoTitle:  A String value - Title of button two.
    ///   - btnTwoTapped: Button Two Tapped Handler (Optional - you can pass nil if you don't want any action).
    func presentAlertViewWithThreeTextFields(alertTitle: String?, alertMessage: String?, alertFirstTextFieldHandler: @escaping alertTextFieldHandler, alertSecondTextFieldHandler: @escaping alertTextFieldHandler, alertThirdTextFieldHandler: @escaping alertTextFieldHandler, btnOneTitle: String, btnOneTapped: alertActionHandler, btnTwoTitle: String, btnTwoTapped: alertActionHandler) {
        
        let alertController = UIAlertController(title: alertTitle ?? "", message: alertMessage ?? "", preferredStyle: .alert)
        alertController.addTextField { (alertFirstTextField) in
            alertFirstTextFieldHandler(alertFirstTextField)
        }
        alertController.addTextField { (alertSecondTextField) in
            alertSecondTextFieldHandler(alertSecondTextField)
        }
        alertController.addTextField { (alertThirdTextField) in
            alertThirdTextFieldHandler(alertThirdTextField)
        }
        alertController.addAction(UIAlertAction(title: btnOneTitle, style: .default, handler: btnOneTapped))
        alertController.addAction(UIAlertAction(title: btnTwoTitle, style: .default, handler: btnTwoTapped))
        alertController.popoverPresentationController?.sourceView = self.view
        self.present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Extension of UIViewController For Actionsheet with Different Numbers of Buttons
extension UIViewController {
    
    /// This Method is used to show ActionSheet with One Button and with One(by Default) "Cancel Button" , While Using this method you don't need to add "Cancel Button" as its already there in ActionSheet.
    ///
    /// - Parameters:
    ///   - actionSheetTitle: A String value that indicates the title of ActionSheet , it is Optional so you can pass nil if you don't want ActionSheet Title.
    ///   - actionSheetMessage: A String value that indicates the ActionSheet message.
    
    ///   - btnOneTitle: A String value - Title of button one.
    ///   - btnOneStyle: A Enum value of "UIAlertActionStyle" , don't pass .cancel as it is already there in ActionSheet(By Default) , If you are passing this value as .cancel then application will crash
    ///   - btnOneTapped: Button One Tapped Handler (Optional - you can pass nil if you don't want any action).
    func presentActionsheetWithOneButton(actionSheetTitle: String?, actionSheetMessage: String?, btnOneTitle: String, btnOneStyle: UIAlertAction.Style, btnOneTapped: alertActionHandler) {
        
        let alertController = UIAlertController(title: actionSheetTitle, message: actionSheetMessage, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: btnOneTitle, style: btnOneStyle, handler: btnOneTapped))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds),0,0)
        self.present(alertController, animated: true, completion: nil)
    }
    
    /// This Method is used to show ActionSheet with Two Buttons and with One(by Default) "Cancel Button" , While Using this method you don't need to add "Cancel Button" as its already there in ActionSheet.
    ///
    /// - Parameters:
    ///   - actionSheetTitle: A String value that indicates the title of ActionSheet , it is Optional so you can pass nil if you don't want ActionSheet Title.
    ///   - actionSheetMessage: A String value that indicates the ActionSheet message.
    ///   - btnOneTitle: A String value - Title of button one.
    ///   - btnOneStyle: A Enum value of "UIAlertActionStyle" , don't pass .cancel as it is already there in ActionSheet(By Default) , If you are passing this value as .cancel then application will crash
    ///   - btnOneTapped: Button One Tapped Handler (Optional - you can pass nil if you don't want any action).
    ///   - btnTwoTitle: A String value - Title of button two.
    ///   - btnTwoStyle: A Enum value of "UIAlertActionStyle" , don't pass .cancel as it is already there in ActionSheet(By Default) , If you are passing this value as .cancel then application will crash
    ///   - btnTwoTapped: Button Two Tapped Handler (Optional - you can pass nil if you don't want any action).
    @discardableResult func presentActionsheetWithTwoButtons(actionSheetTitle: String?, actionSheetMessage: String?, btnOneTitle: String, btnOneStyle: UIAlertAction.Style, btnOneTapped: alertActionHandler, btnTwoTitle: String, btnTwoStyle: UIAlertAction.Style, btnTwoTapped: alertActionHandler) -> UIAlertController {
        
        let alertController = UIAlertController(title: actionSheetTitle, message: actionSheetMessage, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: btnOneTitle, style: btnOneStyle, handler: btnOneTapped))
        alertController.addAction(UIAlertAction(title: btnTwoTitle, style: btnTwoStyle, handler: btnTwoTapped))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds),0,0)
        self.present(alertController, animated: true, completion: nil)
        return alertController
    }
    
    /// This Method is used to show ActionSheet with Three Buttons and with One(by Default) "Cancel Button" , While Using this method you don't need to add "Cancel Button" as its already there in ActionSheet.
    ///
    /// - Parameters:
    ///   - actionSheetTitle: A String value that indicates the title of ActionSheet , it is Optional so you can pass nil if you don't want ActionSheet Title.
    ///   - actionSheetMessage: A String value that indicates the ActionSheet message.
    ///   - btnOneTitle: A String value - Title of button one.
    ///   - btnOneStyle: A Enum value of "UIAlertActionStyle" , don't pass .cancel as it is already there in ActionSheet(By Default) , If you are passing this value as .cancel then application will crash
    ///   - btnOneTapped: Button One Tapped Handler (Optional - you can pass nil if you don't want any action).
    ///   - btnTwoTitle: A String value - Title of button two.
    ///   - btnTwoStyle: A Enum value of "UIAlertActionStyle" , don't pass .cancel as it is already there in ActionSheet(By Default) , If you are passing this value as .cancel then application will crash
    ///   - btnTwoTapped: Button Two Tapped Handler (Optional - you can pass nil if you don't want any action).
    ///   - btnThreeTitle: A String value - Title of button three.
    ///   - btnThreeStyle: A Enum value of "UIAlertActionStyle" , don't pass .cancel as it is already there in ActionSheet(By Default) , If you are passing this value as .cancel then application will crash
    ///   - btnThreeTapped: Button Three Tapped Handler (Optional - you can pass nil if you don't want any action).
    func presentActionsheetWithThreeButton(actionSheetTitle: String?, actionSheetMessage: String?, btnOneTitle: String, btnOneStyle: UIAlertAction.Style, btnOneTapped: alertActionHandler, btnTwoTitle: String, btnTwoStyle: UIAlertAction.Style, btnTwoTapped: alertActionHandler, btnThreeTitle: String, btnThreeStyle: UIAlertAction.Style, btnThreeTapped: alertActionHandler) {
        
        let alertController = UIAlertController(title: actionSheetTitle, message: actionSheetMessage, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: btnOneTitle, style: btnOneStyle, handler: btnOneTapped))
        alertController.addAction(UIAlertAction(title: btnTwoTitle, style: btnTwoStyle, handler: btnTwoTapped))
        alertController.addAction(UIAlertAction(title: btnThreeTitle, style: btnThreeStyle, handler: btnThreeTapped))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds),0,0)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func presentActionsheetWithFourButton(actionSheetTitle: String?, actionSheetMessage: String?, btnOneTitle: String, btnOneStyle: UIAlertAction.Style, btnOneTapped: alertActionHandler, btnTwoTitle: String, btnTwoStyle: UIAlertAction.Style, btnTwoTapped: alertActionHandler, btnThreeTitle: String, btnThreeStyle: UIAlertAction.Style, btnThreeTapped: alertActionHandler, btnFourTitle: String, btnFourStyle: UIAlertAction.Style, btnFourTapped: alertActionHandler) {
        
        let alertController = UIAlertController(title: actionSheetTitle, message: actionSheetMessage, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: btnOneTitle, style: btnOneStyle, handler: btnOneTapped))
        alertController.addAction(UIAlertAction(title: btnTwoTitle, style: btnTwoStyle, handler: btnTwoTapped))
        alertController.addAction(UIAlertAction(title: btnThreeTitle, style: btnThreeStyle, handler: btnThreeTapped))
        alertController.addAction(UIAlertAction(title: btnFourTitle, style: btnFourStyle, handler: btnFourTapped))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds),0,0)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func presentActionsheetWithFiveButton(actionSheetTitle: String?, actionSheetMessage: String?, btnOneTitle: String, btnOneStyle: UIAlertAction.Style, btnOneTapped: alertActionHandler, btnTwoTitle: String, btnTwoStyle: UIAlertAction.Style, btnTwoTapped: alertActionHandler, btnThreeTitle: String, btnThreeStyle: UIAlertAction.Style, btnThreeTapped: alertActionHandler, btnFourTitle: String, btnFourStyle: UIAlertAction.Style, btnFourTapped: alertActionHandler, btnFiveTitle: String, btnFiveStyle: UIAlertAction.Style, btnFiveTapped: alertActionHandler) {
        
        let alertController = UIAlertController(title: actionSheetTitle, message: actionSheetMessage, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: btnOneTitle, style: btnOneStyle, handler: btnOneTapped))
        alertController.addAction(UIAlertAction(title: btnTwoTitle, style: btnTwoStyle, handler: btnTwoTapped))
        alertController.addAction(UIAlertAction(title: btnThreeTitle, style: btnThreeStyle, handler: btnThreeTapped))
        alertController.addAction(UIAlertAction(title: btnFourTitle, style: btnFourStyle, handler: btnFourTapped))
        alertController.addAction(UIAlertAction(title: btnFiveTitle, style: btnFiveStyle, handler: btnFiveTapped))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds),0,0)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func presentActionsheetWithSixButton(actionSheetTitle: String?, actionSheetMessage: String?, btnOneTitle: String, btnOneStyle: UIAlertAction.Style, btnOneTapped: alertActionHandler, btnTwoTitle: String, btnTwoStyle: UIAlertAction.Style, btnTwoTapped: alertActionHandler, btnThreeTitle: String, btnThreeStyle: UIAlertAction.Style, btnThreeTapped: alertActionHandler, btnFourTitle: String, btnFourStyle: UIAlertAction.Style, btnFourTapped: alertActionHandler, btnFiveTitle: String, btnFiveStyle: UIAlertAction.Style, btnFiveTapped: alertActionHandler, btnSixTitle: String, btnSixStyle: UIAlertAction.Style, btnSixTapped: alertActionHandler) {
        
        let alertController = UIAlertController(title: actionSheetTitle, message: actionSheetMessage, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: btnOneTitle, style: btnOneStyle, handler: btnOneTapped))
        alertController.addAction(UIAlertAction(title: btnTwoTitle, style: btnTwoStyle, handler: btnTwoTapped))
        alertController.addAction(UIAlertAction(title: btnThreeTitle, style: btnThreeStyle, handler: btnThreeTapped))
        alertController.addAction(UIAlertAction(title: btnFourTitle, style: btnFourStyle, handler: btnFourTapped))
        alertController.addAction(UIAlertAction(title: btnFiveTitle, style: btnFiveStyle, handler: btnFiveTapped))
        alertController.addAction(UIAlertAction(title: btnSixTitle, style: btnSixStyle, handler: btnSixTapped))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds),0,0)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func presentActionsheetWithSevenButton(actionSheetTitle: String?, actionSheetMessage: String?, btnOneTitle: String, btnOneStyle: UIAlertAction.Style, btnOneTapped: alertActionHandler, btnTwoTitle: String, btnTwoStyle: UIAlertAction.Style, btnTwoTapped: alertActionHandler, btnThreeTitle: String, btnThreeStyle: UIAlertAction.Style, btnThreeTapped: alertActionHandler, btnFourTitle: String, btnFourStyle: UIAlertAction.Style, btnFourTapped: alertActionHandler, btnFiveTitle: String, btnFiveStyle: UIAlertAction.Style, btnFiveTapped: alertActionHandler, btnSixTitle: String, btnSixStyle: UIAlertAction.Style, btnSixTapped: alertActionHandler, btnSevenTitle: String, btnSevenStyle: UIAlertAction.Style, btnSevenTapped: alertActionHandler) {
        
        let alertController = UIAlertController(title: actionSheetTitle, message: actionSheetMessage, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: btnOneTitle, style: btnOneStyle, handler: btnOneTapped))
        alertController.addAction(UIAlertAction(title: btnTwoTitle, style: btnTwoStyle, handler: btnTwoTapped))
        alertController.addAction(UIAlertAction(title: btnThreeTitle, style: btnThreeStyle, handler: btnThreeTapped))
        alertController.addAction(UIAlertAction(title: btnFourTitle, style: btnFourStyle, handler: btnFourTapped))
        alertController.addAction(UIAlertAction(title: btnFiveTitle, style: btnFiveStyle, handler: btnFiveTapped))
        alertController.addAction(UIAlertAction(title: btnSixTitle, style: btnSixStyle, handler: btnSixTapped))
        alertController.addAction(UIAlertAction(title: btnSevenTitle, style: btnSevenStyle, handler: btnSevenTapped))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds),0,0)
        self.present(alertController, animated: true, completion: nil)
    }
    
}
extension UIColor {
    
    func getRGB() -> (r:CGFloat , g:CGFloat , b:CGFloat , a:CGFloat)? {
        
        var red:CGFloat = 0.0
        var green:CGFloat = 0.0
        var blue:CGFloat = 0.0
        var alpha:CGFloat = 0.0
        
        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        
        return (red , green , blue , alpha)
    }
    
    func lightColor(byPercentage:CGFloat) -> UIColor? {
        return adjustColor(byPercentage: abs(byPercentage))
    }
    
    func darkColor(byPercentage:CGFloat) -> UIColor? {
        return adjustColor(byPercentage: (-1 * abs(byPercentage)))
    }
    
    private func adjustColor(byPercentage:CGFloat) -> UIColor? {
        
        guard let RGB = self.getRGB() else { return nil }
        
        return UIColor(red: min(RGB.r + byPercentage/100.0, 1.0), green: min(RGB.g + byPercentage/100.0, 1.0), blue: min(RGB.b + byPercentage/100.0, 1.0), alpha: RGB.a)
    }
    
    func hexStringFromColor() -> String {
        let components = self.cgColor.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0
        
        let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        return hexString
    }
    var hexString: String? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        let multiplier = CGFloat(255.999999)
        
        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        
        if alpha == 1.0 {
            return String(
                format: "#%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier)
            )
        }
        else {
            return String(
                format: "#%02lX%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier),
                Int(alpha * multiplier)
            )
        }
    }
    static func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
