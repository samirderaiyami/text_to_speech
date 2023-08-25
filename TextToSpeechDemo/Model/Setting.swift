//
//  Setting.swift
//  TextToSpeechDemo
//
//  Created by Mac-0006 on 24/08/23.
//

import Foundation

class Setting {
    var voice: Voice?
    var rate: Double = 0.5
    var pitch: Double = 1.0
    var clearText: Bool = false
    var speakAsYouType: Bool = false
    var highlightText: Bool = false
    var delay: Double = 0.0
    var fontSize: Int = 17
    var recentPhrase: Bool = false
}

struct Fonts {
    
    //.. Used In App
    static let SFProRoundedBold = "SFProRounded-Bold"
    static let SFProRoundedSemibold = "SFProRounded-Semibold"
    static let SFProRoundedLight = "SFProRounded-Light"
    static let SFProRoundedRegular = "SFProRounded-Regular"
    static let SFProTextRegularItalic = "SFProText-RegularItalic"
}
