//
//  ExtensionDictionary.swift
//  Swifty_Master
//
//  Created by mac-0002 on 27/05/19.
//  Copyright © 2022 Appcano LLC. All rights reserved.
//

import Foundation

// MARK: - Extension of Dictionary For getting the different types of values from it.
extension Dictionary {
    
    /// This method is used to get the string value from the dictionary.
    ///
    /// - Parameter key: Pass the key for which you want to get the value.
    /// - Returns: return String value according to passed key.
    func valueForString(key: String) -> String {
        if let dictionary = self as? [String: Any] {
            return "\(dictionary[key] ?? "")"
        } else {
            return ""
        }
    }
    
    /// This method is used to get the Int value from the dictionary.
    ///
    /// - Parameter key: Pass the key for which you want to get the value.
    /// - Returns: This Method returns Int? , it means this method return nil value also , while using this method please use if let. If you are not using if let and if this method returns nil and when you are trying to unwrapped this value("Int!") then application will crash.
    func valueForInt(key: String) -> Int? {
        return self.valueForString(key: key).toInt
    }
    
    func valueForDouble(key: String) -> Double? {
        return self.valueForString(key: key).toDouble
    }
    
    func valueForFloat(key: String) -> Float? {
        return self.valueForString(key: key).toFloat
    }
    
    /// This method is used to get the Any value from the dictionary.
    ///
    /// - Parameter key: Pass the key for which you want to get the value.
    /// - Returns: This Method returns Any? , it means this method return nil value also , while using this method please use if let. If you are not using if let and if this method returns nil and when you are trying to unwrapped this value("Any!") then application will crash.
    func valueForJSON(key: String) -> Any? {
        if let dictionary = self as? [String: Any] {
            return dictionary[key] ?? nil
        } else {
            return nil
        }
    }
    
    func valueForBool(key: String) -> Bool {
        
        if let dictionary = self as? [String: Any] {
            return (dictionary[key] as? Bool ?? false)
        } else {
            return false
        }
    }
}
