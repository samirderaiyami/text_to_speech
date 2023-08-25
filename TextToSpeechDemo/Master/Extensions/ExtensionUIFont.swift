//
//  ExtensionUIFont.swift
//  Food Ordering App
//
//  Created by mac-0002 on 27/05/19.
//  Copyright © 2022 Appcano LLC. All rights reserved.
//

import Foundation
import UIKit

extension UIFont {
    
    func setUpAppropriateFont() -> UIFont? {
        if IS_iPhone_5 {
            return UIFont(name: self.fontName, size: self.pointSize - 3.0)
        } else if IS_iPhone_6_Plus || IS_iPhone_XR {
            return UIFont(name: self.fontName, size: self.pointSize + 2.0)
        } else {
            return UIFont(name: self.fontName, size: self.pointSize)
        }
    }
}
