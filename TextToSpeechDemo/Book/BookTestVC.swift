//
//  BookTestVC.swift
//  TextToSpeechDemo
//
//  Created by Mac-0006 on 25/08/23.
//

import UIKit
import Vision
import SwiftSoup
import PDFKit
import AVFoundation
import AVKit

enum SpeechControls {
    case none
    case forwards
    case backwards
}

/*
class SpeechController: NSObject, AVSpeechSynthesizerDelegate {
    
    struct SpeechSegment {
        var text: String
        var range: NSRange // Position in the original content
    }
    
    private var synthesizer = AVSpeechSynthesizer()
    private var segments: [SpeechSegment] = []
    private var currentSegmentIndex: Int = 0
    private var isNavigationAction = false

    var onHighlightSegment: ((NSRange) -> Void)? // Callback to update UI
    
    init(content: String) {
        super.init()
        // For simplicity, breaking by sentences. You can adjust as needed.
        let sentences = content.components(separatedBy: ". ")
        var position = 0
        for sentence in sentences {
            let range = NSRange(location: position, length: sentence.count)
            segments.append(SpeechSegment(text: sentence, range: range))
            position += sentence.count + 2 // +2 accounts for ". "
        }
        self.synthesizer.delegate = self
    }
    
    func play() {
        if currentSegmentIndex >= 0 && currentSegmentIndex < segments.count {
            let segment = segments[currentSegmentIndex]
            let utterance = AVSpeechUtterance(string: segment.text)
            onHighlightSegment?(segment.range)
            synthesizer.speak(utterance)
        }
    }
    
    func fastForward() {
        if synthesizer.isSpeaking {
            isNavigationAction = true
            synthesizer.stopSpeaking(at: .immediate)
        }
        if currentSegmentIndex < segments.count - 1 {
            currentSegmentIndex += 1
            play()
        } else {
            print("Reached Last!!")
        }
    }
    
    func rewind() {
        if synthesizer.isSpeaking {
            isNavigationAction = true
            synthesizer.stopSpeaking(at: .immediate)
        }
        if currentSegmentIndex > 0 {
            currentSegmentIndex -= 1
            play()
        } else {
            print("Reached Last!!")
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if !isNavigationAction {
            // Automatically play the next segment
            currentSegmentIndex += 1
            play()
        } else {
            isNavigationAction = false
        }
    }
}
*/


enum SourceType {
    case scanPages
    case copyPaste
    case insertWebsiteLink
    case importICloudLink
}

struct WordSegment {
    var text: String
    var range: NSRange // Position within the parent segment/sentence
}

struct SpeechSegment {
    var text: String
    var range: NSRange // Position in the original content
    var words: [WordSegment]
}

extension String {
    func ranges(of substring: String, options: CompareOptions = [], locale: Locale? = nil) -> [Range<Index>] {
        var ranges: [Range<Index>] = []
        while ranges.last.map({ $0.upperBound < self.endIndex }) ?? true,
              let range = self.range(of: substring, options: options, range: (ranges.last?.upperBound ?? self.startIndex)..<self.endIndex, locale: locale)
        {
            ranges.append(range)
        }
        return ranges
    }
}
class BookTestVC: UIViewController {

    @IBOutlet weak var txtVBook: GrowingTextView!
    @IBOutlet weak var btnSpeed: UIButton!

    var image = UIImage(named: "book")
    var websiteURL = URL(string: "https://www.rakiyaworld.com/blog/dummy-text")!
    var pdfURL: URL?

    var sourceType: SourceType = .scanPages
    
    let speechSynthesizer = AVSpeechSynthesizer()
    var arrVoices: [Voice] = []
    var index: Int = 0
    
    // set the speaking speed
    var utteranceRate = 0.5
    var setting: Setting?
    var lastSpokenWordEndPosition: Int = 0
    var speechManager: SpeechManager = SpeechManager(delay: 0.0)
    
    var speechController: SpeechController?

    var isPlay = false

    private var synthesizer = AVSpeechSynthesizer()
    private var sentences: [String] = []
    private var currentSentenceIndex: Int = 0
    

    private var arrSpeeds: [String] = [
        "0.1", "0.2", "0.3", "0.4", "0.5", "0.6", "0.7", "0.8", "0.9", "1.0"
    ]
    private var highlightedSentenceRange: NSRange?
    private var highlightedWordRange: NSRange?

    var segments: [SpeechSegment] = []
    var totalLengthOfPreviousSentences = 0
    var speechControls: SpeechControls = .none
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtVBook.font = UIFont(name: Fonts.SFProRoundedRegular, size: CGFloat(Int(setting?.fontSize ?? 17)))!
        speechSynthesizer.delegate = self

        setting = Setting()

        txtVBook.placeholder = "Paste here or start typing..."
        txtVBook.text = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
        
        self.sentences = txtVBook.text.components(separatedBy: ". ")
        var position = 0
        for sentence in self.sentences {
            let words = sentence.components(separatedBy: " ").enumerated().map { (index, word) -> WordSegment in
                let start = sentence.range(of: word)?.lowerBound
                let end = sentence.range(of: word)?.upperBound
                let range = NSRange(location: sentence.distance(from: sentence.startIndex, to: start!), length: word.count)
                return WordSegment(text: word, range: range)
            }
            let range = NSRange(location: position, length: sentence.count)
            segments.append(SpeechSegment(text: sentence, range: range, words: words))
            position += sentence.count + 2 // +2 accounts for ". "
        }
        
        print("-=-=--=-=-=--=-=--=-=-=-=-=-=-")
        print(segments)
        print(segments.count)
        print("-=-=--=-=-=--=-=--=-=-=-=-=-=-")
        //makeSentenceHighlited (sentence: sentences[currentSentenceIndex])
    }
    
    
    func makeSentenceHighlited(sentence: String) {
        
        let range = (txtVBook.text! as NSString).range(of: sentence)
        
        let mutableAttributedString = NSMutableAttributedString.init(string: txtVBook.text!)
        
        let sentenceHighlightColor = UIColor.hexStringToUIColor(hex: "007BFF").withAlphaComponent(0.2)
        mutableAttributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: sentenceHighlightColor, range: range)
        
        txtVBook.attributedText = mutableAttributedString
    }
  
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.speechSynthesizer.stopSpeaking(at: .immediate)
        self.speechManager.stop()
    }
    
    func speak(text: String) {
        let speechUtterance = AVSpeechUtterance(string: text)
        speechUtterance.voice = AVSpeechSynthesisVoice(identifier: self.setting?.voice?.identifier ?? "com.apple.voice.compact.en-IN.Rishi")
        speechUtterance.rate = Float(setting?.rate ?? utteranceRate)
        speechSynthesizer.speak(speechUtterance)
    }
  
}

//MARK:- IBActions

extension BookTestVC {
    @IBAction func btnPlay(_ sender: UIButton) {
        
        isPlay = !isPlay
        
        if isPlay {
            sender.setNormalTitle(normalTitle: "􀊆")
            self.speechSynthesizer.stopSpeaking(at: .immediate)
            self.speechManager.stop()
            self.speak(text: sentences[currentSentenceIndex])
        } else {
            sender.setNormalTitle(normalTitle: "􀊄")
            self.speechSynthesizer.pauseSpeaking(at: .immediate)
        }
    }
    
    @IBAction func btnVoiceClicks(_ sender: UIButton) {
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "VoicesVC") as? VoicesVC
        vc?.delegate = self
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
    @IBAction func btnBackward(_ sender: UIButton) {
//        speechController?.rewind()
//        rewind()
        
//        if currentSentenceIndex > 0  {
//            currentSentenceIndex -= 1
        speechControls = .backwards
            self.speechSynthesizer.stopSpeaking(at: .immediate)
            self.speechManager.stop()
//            self.speak(text: sentences[currentSentenceIndex])
//        }
    }
    
    @IBAction func btnForward(_ sender: UIButton) {
//        if currentSentenceIndex  < sentences.count - 1 {
//            currentSentenceIndex += 1
            speechControls = .forwards
            self.speechSynthesizer.stopSpeaking(at: .immediate)
            self.speechManager.stop()
//            CGCDMainThread.asyncAfter(deadline: .now() + 1, execute: {
//                self.speak(text: self.sentences[self.currentSentenceIndex])
//            })
            
//        }
    }
    
    @IBAction func btnSpeed(_ sender: Any) {
        showPickerInAlertController()
    }
}
extension BookTestVC: AVSpeechSynthesizerDelegate {
    // Functions to highlight text
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        print("didPause")
        print(utterance.speechString)
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        print("didContinue")
        print(utterance.speechString)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("didFinish")
//        if currentSentenceIndex  < sentences.count - 1 {
//            currentSentenceIndex += 1
//            self.speechSynthesizer.stopSpeaking(at: .immediate)
//            self.speechManager.stop()
//            self.speak(text: sentences[currentSentenceIndex])
//        }
        
        // Update the total length of previously spoken sentences
        totalLengthOfPreviousSentences += utterance.speechString.count
        
        
        if speechControls == .none || speechControls == .forwards {
            if currentSentenceIndex  < sentences.count - 1 {
                currentSentenceIndex += 1
            }
        } else {
            if currentSentenceIndex > 0  {
                currentSentenceIndex -= 1
            }
        }
        
        self.speak(text: sentences[currentSentenceIndex])
        
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("-=-=-=-=-==-==-=-=--===-==-=-=-=-==")
        print(utterance.speechString)
        print("-=-=-=-=-==-==-=-=--===-==-=-=-=-==")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("-=-=-=-=-==-==-=-=--===-==-=-=-=-==")
        print("DID CANCEL")
        print("-=-=-=-=-==-==-=-=--===-==-=-=-=-==")
    }
    
    //..FINAL:
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           willSpeakRangeOfSpeechString characterRange: NSRange,
                           utterance: AVSpeechUtterance) {
        
//        let wordDelimiterSet = CharacterSet.alphanumerics.inverted
//        let entireText = utterance.speechString as NSString
//
//        // Find the start of the word
//        let startOfWord = entireText.rangeOfCharacter(from: wordDelimiterSet, options: .backwards, range: NSRange(location: 0, length: characterRange.location)).location
//
//        // Find the end of the word
//        let endOfWord = entireText.rangeOfCharacter(from: wordDelimiterSet, options: .regularExpression, range: NSRange(location: characterRange.location, length: entireText.length - characterRange.location)).location
//
//        let wordRange: NSRange
//        if startOfWord == NSNotFound {
//            wordRange = NSRange(location: 0, length: (endOfWord == NSNotFound) ? characterRange.location + characterRange.length : endOfWord)
//        } else {
//            wordRange = NSRange(location: startOfWord + 1, length: ((endOfWord == NSNotFound) ? characterRange.location + characterRange.length : endOfWord) - startOfWord - 1)
//        }
//
//        print("===========================================")
//        print(utterance.speechString)
//        print(entireText.substring(with: wordRange))
//        print("===========================================")
//        print("===========================================")
        
//        let entireText1 = txtVBook.text!//"Lorem Ipsum is simply dummy text of the printing and typesetting industry. The industry is since 1995 and its doing great right now."
//        let targetWord = entireText.substring(with: wordRange)//"dummy"
//        let attributedString1 = NSMutableAttributedString(string: entireText1)
//
//        // Set the background color for the entire string to light green
//        let entireRange = NSRange(entireText1.startIndex..<entireText1.endIndex, in: entireText1)
//        attributedString1.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.white, range: entireRange)
//
//        // Find the range of the first sentence and set its background color to yellow
//        if let endOfSentenceLocation = entireText1.firstIndex(of: ".") {
//            let firstSentenceRange = entireText1.startIndex...endOfSentenceLocation
//            let nsFirstSentenceRange = NSRange(firstSentenceRange, in: entireText1)
//            attributedString1.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.hexStringToUIColor(hex: "007BFF").withAlphaComponent(0.2), range: nsFirstSentenceRange)
//        }
//
//        // Set background color for "dummy" to red
//        if let range = entireText1.range(of: targetWord) {
//            let nsRange = NSRange(range, in: entireText1)
//            attributedString1.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.hexStringToUIColor(hex: "007BFF").withAlphaComponent(0.4), range: nsRange)
//        }
//
//        txtVBook.attributedText = attributedString1
        
        let entireText = utterance.speechString as NSString
        let wordDelimiterSet = CharacterSet.alphanumerics.inverted
        
        let startOfWord = entireText.rangeOfCharacter(from: wordDelimiterSet, options: .backwards, range: NSRange(location: 0, length: characterRange.location)).location
        let endOfWord = entireText.rangeOfCharacter(from: wordDelimiterSet, options: .regularExpression, range: NSRange(location: characterRange.location, length: entireText.length - characterRange.location)).location
        let wordRange: NSRange
        if startOfWord == NSNotFound {
            wordRange = NSRange(location: 0, length: (endOfWord == NSNotFound) ? characterRange.location + characterRange.length : endOfWord)
        } else {
            wordRange = NSRange(location: startOfWord + 1, length: ((endOfWord == NSNotFound) ? characterRange.location + characterRange.length : endOfWord) - startOfWord - 1)
        }
        
        let entireText1 = txtVBook.text!
        let currentSentence = utterance.speechString
        let attributedString1 = NSMutableAttributedString(string: entireText1)
        
        // Find the range of the current sentence in the full text
        if let sentenceRangeInFullText = entireText1.range(of: currentSentence) {
            // Adjust the characterRange for the full text
            let adjustedRangeLocation = entireText1.distance(from: entireText1.startIndex, to: sentenceRangeInFullText.lowerBound) + characterRange.location
            let adjustedRange = NSRange(location: adjustedRangeLocation, length: characterRange.length)
            
            // Highlight the entire sentence
            let nsSentenceRange = NSRange(sentenceRangeInFullText, in: entireText1)
            attributedString1.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.yellow, range: nsSentenceRange)
            
            // Highlight the current word
            attributedString1.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.red, range: adjustedRange)
        }
        
        txtVBook.attributedText = attributedString1

 
    }
     
}

extension BookTestVC: GrowingTextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if setting?.speakAsYouType ?? false {
            if text == " " || text == "\n" || text == "." || text == "," || text == "!" || text == "?" {
                
                if lastSpokenWordEndPosition <= textView.text.count, range.location <= textView.text.count {
                    let startIndex = textView.text.index(textView.text.startIndex, offsetBy: lastSpokenWordEndPosition)
                    let endIndex = textView.text.index(textView.text.startIndex, offsetBy: range.location)
                    
                    let wordToSpeak = String(textView.text[startIndex..<endIndex])
                    
                    // Update the last spoken word's end position
                    lastSpokenWordEndPosition = range.location + 1 // +1 to account for the space or punctuation
                    
                    // Speak the word
                    speak(text: wordToSpeak)
                }
            }
        }
        
        return true
    }}

extension BookTestVC: SettingsDelegate {
    func settingChanged(setting: Setting?) {
        self.setting = setting
        self.txtVBook.font = UIFont(name: Fonts.SFProRoundedRegular, size: CGFloat(Int(setting?.fontSize ?? 17)))!
    }
}

extension BookTestVC: VoiceDelegate {
    func voiceSelected(voice: Voice) {
        setting?.voice = voice
    }
}



extension BookTestVC {
    
    func showPickerInAlertController() {
        
        // Create a UIAlertController with a custom content view
        let alertController = UIAlertController(title: "Playback Speed:", message: "\n\n\n\n\n\n\n", preferredStyle: .actionSheet)
        //uncomment for iPad Support
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds),0,0)
        
        // Add a UIPickerView to the custom content view
        let pickerView = UIPickerView()
        if !IS_iPad {
            pickerView.frame = CGRect(x: 0, y: 30, width: (view.window?.screen.bounds.width ?? 0.0) - 17.0, height: 162)
        } else {
            pickerView.frame = CGRect(x: 0, y: 30, width: 300, height: 162)
        }
        pickerView.backgroundColor = .clear
        pickerView.dataSource = self
        pickerView.delegate = self
        alertController.view.addSubview(pickerView)
        
        CGCDMainThread.asyncAfter(deadline: .now() + 0.5, execute: {
            if let index = self.arrSpeeds.firstIndex(where: {$0 == "0.5"}) {
                pickerView.selectRow(index, inComponent: 0, animated: true)
            }
        })
        
        alertController.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { _ in
            let value = pickerView.selectedRow(inComponent: 0)
            print("Feet: \(value)")
            let val = Double("0.\(value)") ?? 0.5
            self.setting?.rate = val
            self.btnSpeed.setNormalTitle(normalTitle: "\(val)x")
        }))
        
        // Add the cancel and confirm buttons
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // Present the UIAlertController
        self.present(alertController, animated: true, completion: nil)
    }
}

extension BookTestVC: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        let row = pickerView.selectedRow(inComponent: 0)
        print("this is the pickerView\(row)")
        return arrSpeeds.count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        let label = (view as? UILabel) ?? UILabel()
        
        label.textColor = .black
        label.textAlignment = .center
        label.font = UIFont(name: Fonts.SFProRoundedSemibold, size: 18)
        
        // where data is an Array of String
        label.text = "\(arrSpeeds[row])"

        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        100
    }
}
