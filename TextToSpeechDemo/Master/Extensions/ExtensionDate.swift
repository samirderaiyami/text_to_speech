//
//  ExtensionDate.swift
//  Swifty_Master
//
//  Created by Mind-0002 on 31/08/17.
//  Copyright © 2022 Appcano LLC. All rights reserved.
//

import Foundation
import UIKit

extension Date {
    
    var weekDay: Int {
        let component = Calendar.shared().dateComponents([.weekday], from: self)
        return component.weekday!
    }
    
    var day: Int {
        let component = Calendar.shared().dateComponents([.day], from: self)
        return component.day!
    }
    
    var month: Int {
        let component = Calendar.shared().dateComponents([.month], from: self)
        return component.month!
    }
    
    var year: Int {
        let component = Calendar.shared().dateComponents([.year], from: self)
        return component.year!
    }
    
    var hour: Int {
        let component = Calendar.shared().dateComponents([.hour], from: self)
        return component.hour!
    }
    
    var minute: Int {
        let component = Calendar.shared().dateComponents([.minute], from: self)
        return component.minute!
    }
    
    var second: Int {
        let component = Calendar.shared().dateComponents([.second], from: self)
        return component.second!
    }
    
    var yesterday: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    
    var tomorrow: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    
    var noon: Date {
        return Calendar.current.date(bySettingHour: hour, minute: minute, second: second, of: self)!
    }
    
    var hms: String {
        /// hh:mm:ss > 12:10:00 or 10:00
        if (self.hour > 0) {
            return String(format: "%2ld:%02ld:%02ld", self.hour, self.minute, self.second)
        } else {
            return String(format: "%02ld:%02ld", self.minute, self.second)
        }
    }
   
}

//MARK:-
//MARK:- Extension - Calendor Singleton
extension Calendar {
    private static var sharedInstance: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = NSTimeZone.system
        return calendar
    }()
    
    static func shared() -> Calendar {
        return sharedInstance
    }
}

//extension Calendar {
//    func isDateInCurrentWeek(date: Date) -> Bool? {
//        let currentComponents = Calendar.current.dateComponents([.weekOfYear], from: Date())
//        let dateComponents = Calendar.current.dateComponents([.weekOfYear], from: date)
//        guard let currentWeekOfYear = currentComponents.weekOfYear, let dateWeekOfYear = dateComponents.weekOfYear else { return nil }
//        return currentWeekOfYear == dateWeekOfYear
//    }
//}

extension Calendar {
    func isDateInCurrentWeek(date: Date) -> Bool? {
        let currentComponents = Calendar(identifier: .iso8601).dateComponents([.weekOfYear], from: Date())
        let dateComponents = Calendar(identifier: .iso8601).dateComponents([.weekOfYear], from: date)
        guard let currentWeekOfYear = currentComponents.weekOfYear, let dateWeekOfYear = dateComponents.weekOfYear else { return nil }
        return currentWeekOfYear == dateWeekOfYear
    }
}

