//
//  TextToSpeechVC.swift
//  ChatGPTDemo
//
//  Created by Mac-0006 on 03/05/23.
//

import UIKit
import AVFoundation
import AVKit

class TextToSpeechVC: UIViewController {

    @IBOutlet weak var txtViewEnterText: GrowingTextView!
    
    let speechSynthesizer = AVSpeechSynthesizer()
    var arrVoices: [Voice] = []
    var index: Int = 0

    // set the speaking speed
    var utteranceRate = 0.5
    var setting: Setting?
    var lastSpokenWordEndPosition: Int = 0
    var speechManager: SpeechManager = SpeechManager(delay: 0.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        speechSynthesizer.delegate = self
        setting = Setting()
            
        self.title = "Text To Speech"
        
        txtViewEnterText.text = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
        txtViewEnterText.font = UIFont.systemFont(ofSize: 18.0)
        // Do any additional setup after loading the view.
        AVSpeechSynthesisVoice.speechVoices()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.speechSynthesizer.stopSpeaking(at: .immediate)
        self.speechManager.stop()
    }

    

    @IBAction func btnSettings(sender: UIButton) {
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "SettingsVC") as? SettingsVC
        vc?.delegate = self
        vc?.setting = self.setting
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
    @IBAction func btnPlay(sender: UIButton) {
        self.speechSynthesizer.stopSpeaking(at: .immediate)
        self.speechManager.stop()

        if txtViewEnterText.text?.isEmpty == false {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                if (self.setting?.delay ?? 0.0) > 0.0 {
                    self.speechManager = SpeechManager(delay: self.setting?.delay ?? 0.0) // 1-second delay between sentences
                    self.speechManager.speakWithDelay(self.txtViewEnterText.text!, setting: self.setting)
                } else {
                    self.speak(text: self.txtViewEnterText.text!)
                }
            })
        } else {
            self.presentAlertViewWithOneButton(alertTitle: nil, alertMessage: "Please enter text", btnOneTitle: "Okay", btnOneTapped: nil)
        }

    }
    
    func speak(text: String, withDelay: Bool = false) {
        let speechUtterance = AVSpeechUtterance(string: text)
        speechUtterance.voice = AVSpeechSynthesisVoice(identifier: self.setting?.voice?.identifier ?? "com.apple.voice.compact.en-IN.Rishi")
        speechUtterance.rate = Float(setting?.rate ?? utteranceRate)
        speechUtterance.pitchMultiplier = Float(setting?.pitch ?? 1.0)
        speechUtterance.postUtteranceDelay = 1.0
        speechSynthesizer.speak(speechUtterance)
    }
    
    func splitSentences(from text: String) -> [String] {
        let linguisticTagger = NSLinguisticTagger(tagSchemes: [.tokenType], options: 0)
        linguisticTagger.string = text
        
        var sentences: [String] = []
        var sentence: String = ""
        
        linguisticTagger.enumerateTags(in: NSRange(location: 0, length: text.utf16.count), scheme: .tokenType, options: [.omitWhitespace, .omitOther, .joinNames]) { tag, tokenRange, _, _ in
            if let tag = tag, tag == .sentenceTerminator, let range = Range(tokenRange, in: text) {
                sentence.append(contentsOf: text[range])
                sentences.append(sentence.trimmingCharacters(in: .whitespacesAndNewlines))
                sentence = ""
            } else if let range = Range(tokenRange, in: text) {
                sentence.append(contentsOf: text[range])
            }
        }
        
        // Add remaining content as the last sentence if not empty
        if !sentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sentences.append(sentence.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        return sentences
    }


//    func speakSentencesWithDelay(_ text: String) {
//        let sentences = splitSentences(from: text)
//        for sentence in sentences {
//            let utterance = AVSpeechUtterance(string: sentence)
//            utterance.postUtteranceDelay = 1.0 // Adjust this value as per your requirement
//            synthesizer.speak(utterance)
//        }
//    }
    
}

extension TextToSpeechVC: AVSpeechSynthesizerDelegate {
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
        if setting?.clearText ?? false {
            txtViewEnterText.text = ""
        }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           willSpeakRangeOfSpeechString characterRange: NSRange,
                           utterance: AVSpeechUtterance) {
        
        if setting?.highlightText ?? false {
            let mutableAttributedString = NSMutableAttributedString(string: utterance.speechString)
            mutableAttributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.yellow, range: characterRange)
            
            // Check if the font exists, then add the font attribute
            mutableAttributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: CGFloat(Int(setting?.fontSize ?? 18))), range: NSRange(location: 0, length: utterance.speechString.utf16.count))
            txtViewEnterText.attributedText = mutableAttributedString
        }
    }

}

extension TextToSpeechVC: GrowingTextViewDelegate {
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

extension TextToSpeechVC: SettingsDelegate {
    func settingChanged(setting: Setting?) {
        self.setting = setting
        self.txtViewEnterText.font = UIFont.systemFont(ofSize: CGFloat(setting?.fontSize ?? 18))
    }
}

class SpeechManager: NSObject, AVSpeechSynthesizerDelegate {
    
    private let synthesizer = AVSpeechSynthesizer()
    private var sentenceQueue: [String] = []
    private let delay: TimeInterval
    private var setting: Setting?

    init(delay: TimeInterval) {
        self.delay = delay
        super.init()
        synthesizer.delegate = self
    }
    
    // Include the splitSentences function here
    private func splitSentences(from text: String) -> [String] {
        return text.components(separatedBy: CharacterSet(charactersIn: ".!?")).filter { !$0.isEmpty }
    }
    
    func speakWithDelay(_ text: String, setting: Setting?) {
        self.setting = setting
        sentenceQueue = splitSentences(from: text)
        speakNextSentence(setting: setting)
    }
    
    func speak(_ text: String, setting: Setting?) {
        self.setting = setting
        speakFullSentence(text,setting: setting)
    }
    
    func stop() {
        DispatchQueue.main.async {
            self.synthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    private func speakNextSentence(setting: Setting?) {
        if let nextSentence = sentenceQueue.first {
            let utterance = AVSpeechUtterance(string: nextSentence.trimmingCharacters(in: .whitespaces))
            utterance.voice = AVSpeechSynthesisVoice(identifier: setting?.voice?.identifier ?? "com.apple.voice.compact.en-IN.Rishi")
            utterance.rate = Float(setting?.rate ?? 0.5)
            utterance.pitchMultiplier = Float(setting?.pitch ?? 1.0)
            synthesizer.speak(utterance)
        }
    }
    
    private func speakFullSentence(_ text: String, setting: Setting?) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: self.setting?.voice?.identifier ?? "com.apple.voice.compact.en-IN.Rishi")
        utterance.rate = Float(setting?.rate ?? 0.5)
        utterance.pitchMultiplier = Float(setting?.pitch ?? 1.0)
        utterance.postUtteranceDelay = 1.0
        synthesizer.speak(utterance)
    }
    
    // MARK: AVSpeechSynthesizerDelegate methods
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        sentenceQueue.removeFirst()
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.speakNextSentence(setting: self.setting)
        }
    }
}
