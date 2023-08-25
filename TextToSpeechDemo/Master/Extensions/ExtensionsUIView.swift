//
//  ExtensionsUIView.swift
//  Helponymous App
//
//  Created by mac-0002 on 27/05/19.
//  Copyright © 2022 Appcano LLC. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    @IBInspectable fileprivate var cornerRadius: CGFloat {
        
        get {
            return self.layer.cornerRadius
        } set {
            self.layer.cornerRadius = newValue
            self.layer.masksToBounds = true
        }
    }
    @IBInspectable fileprivate var borderColorApp: UIColor? {

        get {
            guard let borderColor = self.layer.borderColor else {
                return nil
            }
            return UIColor(cgColor: borderColor)
        } set {
            self.layer.borderColor = newValue?.cgColor
        }
    }
    
    @IBInspectable fileprivate var borderWidth:CGFloat {
        
        get {
            return self.layer.borderWidth
        } set {
            self.layer.borderWidth = newValue
        }
    }
    
    /// This method is used to giving the round shape to any UIView
    func roundView() {
        self.layer.cornerRadius = (self.CViewHeight/2.0)
        self.layer.masksToBounds = true
    }
}

// MARK: - Extension of UIView For draw a shadowView of it.
extension UIView {
    
    /// This method is used to draw a shadowView for perticular UIView.
    ///
    /// - Parameters:
    ///   - color: Pass the UIColor that you want to see as shadowColor.
    ///   - shadowOffset: Pass the CGSize value for how much far you want shadowView from parentView.
    ///   - shadowRadius: Pass the CGFloat value for how much length(Blur Spreadness) you want in shadowView.
    ///   - shadowOpacity: Pass the Float value for how much opacity you want in shadowView.
    func shadow(color: UIColor, shadowOffset: CGSize, shadowRadius: CGFloat, shadowOpacity: Float) {
        self.layer.masksToBounds = false
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOffset = shadowOffset
        self.layer.shadowRadius = shadowRadius
        self.layer.shadowOpacity = shadowOpacity
    }
    
    func removeShadow() {
        
        self.layer.shadowColor = UIColor.clear.cgColor
        self.layer.shadowOffset = .zero
        self.layer.shadowRadius = 0.0
        self.layer.shadowOpacity = 0.0
    }
}

extension UIView {
    
    var snapshotImage: UIImage? {
        var snapShotImage: UIImage?
        UIGraphicsBeginImageContext(self.CViewSize)
        if let context = UIGraphicsGetCurrentContext() {
            self.layer.render(in: context)
            if let image = UIGraphicsGetImageFromCurrentImageContext() {
                UIGraphicsEndImageContext()
                snapShotImage = image
            }
        }
        return snapShotImage
    }
}

extension UIView {
    
    /// This static Computed property is used to getting any UIView from XIB. This Computed property returns UIView? , it means this method return nil value also , while using this method please use if let. If you are not using if let and if this method returns nil and when you are trying to unwrapped this value("UIView!") then application will crash.
    static var viewFromXib: UIView? {
        return self.viewWithNibName(strViewName: "\(self)")
    }
    
    /// This static method is used to getting any UIView with specific name.
    ///
    /// - Parameter strViewName: A String Value of UIView.
    /// - Returns: This Method returns UIView? , it means this method return nil value also , while using this method please use if let. If you are not using if let and if this method returns nil and when you are trying to unwrapped this value("UIView!") then application will crash.
    static func viewWithNibName(strViewName: String) -> UIView? {
        guard let view = CMainBundle.loadNibNamed(strViewName, owner: self, options: nil)?[0] as? UIView else { return nil }
        return view
    }
}

extension UIView {
    
    var CViewSize: CGSize {
        return self.frame.size
    }
    var CViewOrigin: CGPoint {
        return self.frame.origin
    }
    var CViewWidth: CGFloat {
        return self.CViewSize.width
    }
    var CViewHeight: CGFloat {
        return self.CViewSize.height
    }
    var CViewX: CGFloat {
        return self.CViewOrigin.x
    }
    var CViewY: CGFloat {
        return self.CViewOrigin.y
    }
    var CViewCenter: CGPoint {
        return CGPoint(x: self.CViewWidth/2.0, y: self.CViewHeight/2.0)
    }
    var CViewCenterX: CGFloat {
        return CViewCenter.x
    }
    var CViewCenterY: CGFloat {
        return CViewCenter.y
    }
}

extension UIView {
    
    func CViewSetSize(width: CGFloat, height: CGFloat) {
        CViewSetWidth(width: width)
        CViewSetHeight(height: height)
    }
    
    func CViewSetOrigin(x: CGFloat, y: CGFloat) {
        CViewSetX(x: x)
        CViewSetY(y: y)
    }
    
    func CViewSetWidth(width: CGFloat) {
        self.frame.size.width = width
    }
    
    func CViewSetHeight(height: CGFloat) {
        self.frame.size.height = height
    }
    
    func CViewSetX(x: CGFloat) {
        self.frame.origin.x = x
    }
    
    func CViewSetY(y: CGFloat) {
        self.frame.origin.y = y
    }
    
    func CViewSetCenter(x: CGFloat, y: CGFloat) {
        CViewSetCenterX(x: x)
        CViewSetCenterY(y: y)
    }
    
    func CViewSetCenterX(x: CGFloat) {
        self.center.x = x
    }
    
    func CViewSetCenterY(y: CGFloat) {
        self.center.y = y
    }
}

extension UIView {
    
    func alternateCorners(_ corners: CACornerMask, radius: CGFloat) {
        
        if #available(iOS 11, *) {
            
            self.layer.cornerRadius = radius
            self.layer.maskedCorners = corners
            
        } else {
            
            var cornerMask = UIRectCorner()
            
            if(corners.contains(.layerMinXMinYCorner)){
                cornerMask.insert(.topLeft)
            }
            if(corners.contains(.layerMaxXMinYCorner)){
                cornerMask.insert(.topRight)
            }
            if(corners.contains(.layerMinXMaxYCorner)){
                cornerMask.insert(.bottomLeft)
            }
            if(corners.contains(.layerMaxXMaxYCorner)){
                cornerMask.insert(.bottomRight)
            }
            
            let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: cornerMask, cornerRadii: CGSize(width: radius, height: radius))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            
            self.layer.mask = mask
        }
    }
}

extension UIView {
   func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}
extension  UITableViewHeaderFooterView {

    static var nib: UINib {
        return UINib(nibName: identifier, bundle: nil)
    }

    static var identifier: String {
        return String(describing: self)
    }
}

extension UIView {

    // Using a function since `var image` might conflict with an existing variable
    // (like on `UIImageView`)
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
