//
//  ExtensionUIResponder.swift
//  Swifty_Master
//
//  Created by mac-0002 on 27/05/19.
//  Copyright © 2022 Appcano LLC. All rights reserved.
//

import Foundation
import UIKit


// MARK: - Extension of UIResponder For getting the ParentViewController(UIViewController) of any UIView.
extension UIResponder {
    
    /// This Property is used to getting the ParentViewController(UIViewController) of any UIView.
    var viewController: UIViewController? {
        if self.next is UIViewController {
            return self.next as? UIViewController
        } else {
            guard self.next != nil else { return nil }
            return self.next?.viewController
        }
    }
    var tblVCell: UITableViewCell? {
        if self.next is UITableViewCell {
            return self.next as? UITableViewCell
        } else {
            guard self.next != nil else { return nil }
            return self.next?.tblVCell
        }
    }
    var collVCell: UICollectionViewCell? {
        if self.next is UICollectionViewCell {
            return self.next as? UICollectionViewCell
        } else {
            guard self.next != nil else { return nil }
            return self.next?.collVCell
        }
    }
}
