//
//  MIKeyboardManager.swift
//  Swifty_Master
//
//  Created by mind-0002 on 15/11/17.
//  Copyright © 2022 Appcano LLC. All rights reserved.
//

import Foundation
import UIKit

@objc protocol MIKeyboardManagerDelegate : class {
    func keyboardWillShow(notification:Notification , keyboardHeight:CGFloat)
    func keyboardWillHide(notification:Notification)
    @objc optional func keyboardWillChangeFrame(notification:Notification , keyboardHeight:CGFloat)
}

class MIKeyboardManager  {
    
    private init() {}
    
    private static let miKeyboardManager:MIKeyboardManager = {
        let miKeyboardManager = MIKeyboardManager()
        return miKeyboardManager
    }()
    
    static var shared:MIKeyboardManager {
        return miKeyboardManager
    }
    
    weak var delegate:MIKeyboardManagerDelegate?
    
    func enableKeyboardNotification() {
        
        NotificationCenter.default.addObserver(MIKeyboardManager.shared, selector: #selector(self.keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(MIKeyboardManager.shared, selector: #selector(self.keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        NotificationCenter.default.addObserver(MIKeyboardManager.shared, selector: #selector(self.keyboardWillChangeFrame(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    func disableKeyboardNotification() {
        
        NotificationCenter.default.removeObserver(MIKeyboardManager.shared, name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.removeObserver(MIKeyboardManager.shared, name: UIResponder.keyboardWillHideNotification, object: nil)
        
        NotificationCenter.default.removeObserver(MIKeyboardManager.shared, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @objc  private func keyboardWillShow(notification:Notification) {
        
        if let info = notification.userInfo {
            
            if let keyboardRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                
                delegate?.keyboardWillShow(notification: notification, keyboardHeight: keyboardRect.height)
            }
        }
    }
    
    @objc private func keyboardWillHide(notification:Notification) {
        delegate?.keyboardWillHide(notification: notification)
    }
    
    @objc private func keyboardWillChangeFrame(notification:Notification) {
        
        if let info = notification.userInfo {
            
            if let keyboardRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                
                delegate?.keyboardWillChangeFrame?(notification: notification, keyboardHeight: keyboardRect.height)
            }
        }
    }
}
