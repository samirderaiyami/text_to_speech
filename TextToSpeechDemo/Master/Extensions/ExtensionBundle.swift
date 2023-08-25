//
//  ExtensionBundle.swift
//  supportal
//
//  Created by Mindventory on 23/08/21.
//  Copyright © 2022 Appcano LLC. All rights reserved.
//

import Foundation

extension Bundle {

    static func loadView<T>(fromNib name: String, withType type: T.Type) -> T {
        if let view = Bundle.main.loadNibNamed(name, owner: nil, options: nil)?.first as? T {
            return view
        }

        fatalError("Could not load view with type " + String(describing: type))
    }
}
