//
//  ExtensionUITextField.swift
//  supportal
//
//  Created by mac-0002 on 23/07/19.
//  Copyright © 2022 Appcano LLC. All rights reserved.
//

import UIKit

// MARK: - Extension of UITextField For UITextField's placeholder Color.
extension UITextField {
    
    /// Placeholder Color of UITextField , as it is @IBInspectable so you can directlly set placeholder color of UITextField From Interface Builder , No need to write any number of Lines.
    @IBInspectable var placeholderColor: UIColor? {
        get  {
            return self.placeholderColor
        } set {
            if let newValue = newValue {
                self.attributedPlaceholder = NSAttributedString(string: self.placeholder ?? "" , attributes: [.foregroundColor:newValue])
            }
        }
    }
}
