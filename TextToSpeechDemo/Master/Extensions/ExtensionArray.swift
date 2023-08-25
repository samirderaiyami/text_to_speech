//
//  ExtentionArray.swift
//  supportal
//
//  Created by Mind on 12/08/21.
//  Copyright © 2022 Appcano LLC. All rights reserved.
//

import Foundation

extension Array {
    /// Picks `n` random elements (partial Fisher-Yates shuffle approach)
    subscript (randomPick n: Int) -> [Element] {
        var copy = self
        for i in stride(from: count - 1, to: count - n - 1, by: -1) {
            copy.swapAt(i, Int(arc4random_uniform(UInt32(i + 1))))
        }
        return Array(copy.suffix(n))
    }
}

extension Array where Element: Equatable {

    func reorder(by preferredOrder: [Element]) -> [Element] {

        return self.sorted { (a, b) -> Bool in
            guard let first = preferredOrder.firstIndex(of: a) else {
                return false
            }

            guard let second = preferredOrder.firstIndex(of: b) else {
                return true
            }

            return first < second
        }
    }
}
