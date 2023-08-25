//
//  ExtensionDouble.swift
//  Swifty_Master
//
//  Created by mac-0002 on 27/05/19.
//  Copyright © 2022 Appcano LLC. All rights reserved.
//

import Foundation
import UIKit

extension Double {
    
    var toInt: Int? {
        return Int(self)
    }
    var toFloat: Float? {
        return Float(self)
    }
    var toString: String {
        return "\(self)"
    }
}
