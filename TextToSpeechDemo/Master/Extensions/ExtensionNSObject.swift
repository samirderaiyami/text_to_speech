//
//  ExtensionNSObject.swift
//  DemoSwift
//
//  Created by mac-0002 on 13/08/19.
//  Copyright © 2022 Appcano LLC. All rights reserved.
//

import Foundation

extension NSObject {
    
    func set(object anObj: AnyObject?, forKey: UnsafeRawPointer) -> Void {
        objc_setAssociatedObject(self, forKey, anObj, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func object(forKey key: UnsafeRawPointer) -> AnyObject? {
        return objc_getAssociatedObject(self, key) as AnyObject
    }
}
