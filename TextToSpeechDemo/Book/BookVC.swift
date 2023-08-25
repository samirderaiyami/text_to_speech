//
//  BookVC.swift
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

enum SourceType {
    case scanPages
    case copyPaste
    case insertWebsiteLink
    case importICloudLink
}

class BookVC: UIViewController {

    @IBOutlet weak var txtVBook: GrowingTextView!
    
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
    
    var isPlay = false

    override func viewDidLoad() {
        super.viewDidLoad()
        txtVBook.font = UIFont(name: Fonts.SFProRoundedRegular, size: CGFloat(Int(setting?.fontSize ?? 17)))!
        
        speechSynthesizer.delegate = self
        setting = Setting()

        if sourceType == .scanPages {
            // converting image into CGImage
            guard let cgImage = image?.cgImage else {return}
            
            // creating request with cgImage
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            // Vision provides its text-recognition capabilities through VNRecognizeTextRequest, an image-based request type that finds and extracts text in images.
            let request = VNRecognizeTextRequest { request, error in
                
                if let results = request.results as? [VNRecognizedTextObservation] {
                    let text = results.compactMap({
                        $0.topCandidates(1).first?.string
                    }).joined(separator: ", ")
                    print(text) // text we get from image
                    self.txtVBook.text = text
                }
                
            }
            
            request.recognitionLevel = VNRequestTextRecognitionLevel.accurate
            
            if #available(iOS 16.0, *) {
                request.automaticallyDetectsLanguage = true
            } else {
                request.recognitionLanguages = ["en-us"]
                // Fallback on earlier versions
            }
            
            do {
                try handler.perform([request])
            } catch {
                print(error.localizedDescription)
            }
        } else if sourceType == .copyPaste {
            txtVBook.placeholder = "Paste here or start typing..."
        } else if sourceType == .insertWebsiteLink {
                        
            fetchWebsiteContent(url: websiteURL.absoluteString) { html, error in
                if let html = html {
                    let extractedText = self.extractTextFromHTML(html: html)
                    DispatchQueue.main.async {
                        self.txtVBook.text = extractedText?.trimmingCharacters(in: .whitespaces)
                        print(extractedText ?? "Couldn't extract text.")
                    }
                } else {
                    print("Error fetching content: \(error?.localizedDescription ?? "Unknown error")")
                }
            }

            
        } else if sourceType == .importICloudLink {
            let pdf = PDFDocument(url: self.pdfURL!)
            self.txtVBook.text = pdf!.string!
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.speechSynthesizer.stopSpeaking(at: .immediate)
        self.speechManager.stop()
    }
    
    @IBAction func btnPlay(_ sender: UIButton) {
        
        isPlay = !isPlay
        
        if isPlay {
            sender.setNormalTitle(normalTitle: "􀊆")
            self.speechSynthesizer.stopSpeaking(at: .immediate)
            self.speechManager.stop()
            
            if self.txtVBook.text?.isEmpty == false {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    if (self.setting?.delay ?? 0.0) > 0.0 {
                        self.speechManager = SpeechManager(delay: self.setting?.delay ?? 0.0) // 1-second delay between sentences
                        self.speechManager.speakWithDelay(self.txtVBook.text!, setting: self.setting)
                    } else {
                        self.speak(text: self.txtVBook.text!)
                    }
                })
            } else {
                self.presentAlertViewWithOneButton(alertTitle: nil, alertMessage: "Please enter text", btnOneTitle: "Okay", btnOneTapped: nil)
            }

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
    
    func fetchWebsiteContent(url: String, completion: @escaping (String?, Error?) -> Void) {
        guard let url = URL(string: url) else {
            completion(nil, NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let html = String(data: data, encoding: .utf8) {
                completion(html, nil)
            } else {
                completion(nil, error)
            }
        }.resume()
    }
//    func extractTextFromHTML(html: String) -> String? {
//        do {
//            let document = try SwiftSoup.parse(html)
//            let elements = try document.getAllElements()
//
//            var lines: [String] = []
//
//            for element in elements {
//                let text = element.ownText().trimmingCharacters(in: .whitespacesAndNewlines)
//                if !text.isEmpty {
//                    lines.append(text)
//                }
//            }
//
//            return lines.joined(separator: "\n\n") // Two newline characters for an empty line between each line
//        } catch {
//            print("Error parsing HTML: \(error.localizedDescription)")
//            return nil
//        }
//    }

    func extractTextFromHTML(html: String) -> String? {
        do {
            let document = try SwiftSoup.parse(html)
            
            // Remove all img tags
            try document.select("img").remove()
            
            let elements = try document.getAllElements()
            
            var lines: [String] = []
            
            for element in elements {
                
                var text = element.ownText().trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Remove special symbols
                let characterset = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,!?")
                text = text.components(separatedBy: characterset.inverted).joined()
                
                if !text.isEmpty {
                    lines.append(text)
                }
            }
            
            return lines.joined(separator: "\n\n")
        } catch {
            print("Error parsing HTML: \(error.localizedDescription)")
            return nil
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


}
extension BookVC: AVSpeechSynthesizerDelegate {
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
            txtVBook.text = ""
        }
    }
    //..WORKING
//    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
//                           willSpeakRangeOfSpeechString characterRange: NSRange,
//                           utterance: AVSpeechUtterance) {
//
////        if setting?.highlightText ?? false {
//            let mutableAttributedString = NSMutableAttributedString(string: utterance.speechString)
//            let color = UIColor.hexStringToUIColor(hex: "007BFF").withAlphaComponent(0.4)
//            mutableAttributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: color, range: characterRange)
//
//            // Check if the font exists, then add the font attribute
//        let font = UIFont(name: Fonts.SFProRoundedRegular, size: CGFloat(Int(setting?.fontSize ?? 17)))!
//            mutableAttributedString.addAttribute(.font, value: font, range: NSRange(location: 0, length: utterance.speechString.utf16.count))
//            txtVBook.attributedText = mutableAttributedString
////        }
//    }
    
    //..FINAL:
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           willSpeakRangeOfSpeechString characterRange: NSRange,
                           utterance: AVSpeechUtterance) {
        
        let mutableAttributedString = NSMutableAttributedString(string: utterance.speechString)
        
        // Determine the range of the entire sentence that contains characterRange
        let sentenceDelimiterSet = CharacterSet(charactersIn: ".!?")
        let entireText = utterance.speechString as NSString
        let startOfSentence = entireText.rangeOfCharacter(from: sentenceDelimiterSet, options: .backwards, range: NSRange(location: 0, length: characterRange.location)).location
        let endOfSentence = entireText.rangeOfCharacter(from: sentenceDelimiterSet, options: .regularExpression, range: NSRange(location: characterRange.location, length: entireText.length - characterRange.location)).location
        
        let sentenceRange: NSRange
        if startOfSentence == NSNotFound {
            sentenceRange = NSRange(location: 0, length: (endOfSentence == NSNotFound) ? entireText.length : endOfSentence + 1)
        } else {
            sentenceRange = NSRange(location: startOfSentence + 1, length: ((endOfSentence == NSNotFound) ? entireText.length : endOfSentence) - startOfSentence)
        }
        
        // Color for highlighting the current spoken sentence
        let sentenceHighlightColor = UIColor.hexStringToUIColor(hex: "007BFF").withAlphaComponent(0.2)
        mutableAttributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: sentenceHighlightColor, range: sentenceRange)
        
        // Color for highlighting the current spoken word
        let wordHighlightColor = UIColor.hexStringToUIColor(hex: "007BFF").withAlphaComponent(0.4)
        mutableAttributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: wordHighlightColor, range: characterRange)
        
        // Font attribute for the entire string
        let font = UIFont(name: Fonts.SFProRoundedRegular, size: CGFloat(Int(setting?.fontSize ?? 17)))!
        mutableAttributedString.addAttribute(.font, value: font, range: NSRange(location: 0, length: utterance.speechString.utf16.count))
        
        txtVBook.attributedText = mutableAttributedString
    }
     
    /*
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           willSpeakRangeOfSpeechString characterRange: NSRange,
                           utterance: AVSpeechUtterance) {
        
        let mutableAttributedString = NSMutableAttributedString(string: utterance.speechString)
        
        let font = UIFont(name: Fonts.SFProRoundedRegular, size: CGFloat(Int(setting?.fontSize ?? 17)))!
        
        // Replace the current word with its image representation
        if let wordImage = (utterance.speechString as NSString).substring(with: characterRange).imageWithRoundedBackground(color: .yellow, cornerRadius: 5, font: font) {
            let textAttachmentWord = NSTextAttachment()
            textAttachmentWord.image = wordImage
            let attributedStringWithWordImage = NSAttributedString(attachment: textAttachmentWord)
            mutableAttributedString.replaceCharacters(in: characterRange, with: attributedStringWithWordImage)
        }
        
        // Replace the current sentence with its image representation (if it includes the word being spoken)
        // Note: You might want to exclude this block if you don't want to double-process the current word
        let sentenceRange = findSentenceRange(containing: characterRange, in: utterance.speechString)

        if let sentenceImage = (utterance.speechString as NSString).substring(with: sentenceRange).imageWithRoundedBackground(color: .red, cornerRadius: 5, font: font) {
            let textAttachmentSentence = NSTextAttachment()
            textAttachmentSentence.image = sentenceImage
            let attributedStringWithSentenceImage = NSAttributedString(attachment: textAttachmentSentence)
            mutableAttributedString.replaceCharacters(in: sentenceRange, with: attributedStringWithSentenceImage)
        }
        
        txtVBook.attributedText = mutableAttributedString
    }
    
    func findSentenceRange(containing characterRange: NSRange, in text: String) -> NSRange {
        let sentenceDelimiterSet = CharacterSet(charactersIn: ".!?")
        let entireText = text as NSString
        let startOfSentence = entireText.rangeOfCharacter(from: sentenceDelimiterSet, options: .backwards, range: NSRange(location: 0, length: characterRange.location)).location
        let endOfSentence = entireText.rangeOfCharacter(from: sentenceDelimiterSet, options: .regularExpression, range: NSRange(location: characterRange.location, length: entireText.length - characterRange.location)).location
        
        if startOfSentence == NSNotFound {
            return NSRange(location: 0, length: (endOfSentence == NSNotFound) ? entireText.length : endOfSentence + 1)
        } else {
            return NSRange(location: startOfSentence + 1, length: ((endOfSentence == NSNotFound) ? entireText.length : endOfSentence) - startOfSentence)
        }
    }
     */

}

extension BookVC: GrowingTextViewDelegate {
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

extension BookVC: SettingsDelegate {
    func settingChanged(setting: Setting?) {
        self.setting = setting
        self.txtVBook.font = UIFont(name: Fonts.SFProRoundedRegular, size: CGFloat(Int(setting?.fontSize ?? 17)))!
    }
}

extension BookVC: VoiceDelegate {
    func voiceSelected(voice: Voice) {
        setting?.voice = voice
    }
}

class RoundedBackgroundLayoutManager: NSLayoutManager {
    
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
        
        textStorage?.enumerateAttributes(in: glyphsToShow, options: []) { (attributes, range, stop) in
            if let color = attributes[NSAttributedString.Key.backgroundColor] as? UIColor {
                let boundingRect = self.boundingRectForGlyphRange(range, in: textContainers.first!)
                let path = UIBezierPath(roundedRect: boundingRect, cornerRadius: 5) // Adjust cornerRadius as needed
                color.setFill()
                path.fill()
            }
        }
    }
    
    func boundingRectForGlyphRange(_ range: NSRange, in textContainer: NSTextContainer) -> CGRect {
        var glyphRange = NSRange()
        
        // Convert the range from character to glyph range
        glyphRange = characterRange(forGlyphRange: range, actualGlyphRange: nil)
        return boundingRect(forGlyphRange: glyphRange, in: textContainer)
    }
    
}


func attributedStringWithImage(from text: String, color: UIColor, font: UIFont) -> NSAttributedString {
    guard let image = text.imageWithRoundedBackground(color: color, cornerRadius: 5, font: font) else { return NSAttributedString(string: text) }
    
    let textAttachment = NSTextAttachment()
    textAttachment.image = image
    let attributedStringWithImage = NSAttributedString(attachment: textAttachment)
    return attributedStringWithImage
}
extension String {
    func imageWithRoundedBackground(color: UIColor, cornerRadius: CGFloat, font: UIFont) -> UIImage? {
        let string = NSAttributedString(string: self, attributes: [
            .font: font,
            .backgroundColor: color
        ])
        let size = string.size()
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.clear.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: cornerRadius)
        color.setFill()
        path.fill()
        string.draw(at: .zero)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
