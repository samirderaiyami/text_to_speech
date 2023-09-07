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

class SpeechController: NSObject, AVSpeechSynthesizerDelegate {
    
    struct WordSegment {
        var text: String
        var range: NSRange // Position within the parent segment/sentence
    }
    
    struct SpeechSegment {
        var text: String
        var range: NSRange // Position in the original content
        var words: [WordSegment]
    }
    
    private var synthesizer = AVSpeechSynthesizer()
    private var segments: [SpeechSegment] = []
    private var currentSegmentIndex: Int = 0
    private var currentWordIndex: Int = 0
    private var isNavigationAction = false
    
    var onHighlightSegment: ((NSRange) -> Void)? // Callback to update UI for sentence
    var onHighlightWord: ((NSRange) -> Void)? // Callback to highlight the current word
    
    init(content: String) {
        super.init()
        // Breaking by sentences.
        let sentences = content.components(separatedBy: ". ")
        var position = 0
        for sentence in sentences {
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
        self.synthesizer.delegate = self
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
    
    func playNextWord() {
        if currentSegmentIndex < segments.count {
            let segment = segments[currentSegmentIndex]
            onHighlightSegment?(segment.range)
            
            if currentWordIndex < segment.words.count {
                let word = segment.words[currentWordIndex]
                let utterance = AVSpeechUtterance(string: word.text)
                
                // Adjust the range to map to the original content
                let adjustedRange = NSRange(location: segment.range.location + word.range.location, length: word.range.length)
                onHighlightWord?(adjustedRange)
                
                synthesizer.speak(utterance)
            } else {
                currentSegmentIndex += 1
                currentWordIndex = 0
                playNextWord()
            }
        }
    }
    
    func play() {
        playNextWord()
    }
    
    //... Rest of your fastForward, rewind, and delegate functions but make sure to reset currentWordIndex when needed.
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if !isNavigationAction {
            currentWordIndex += 1
            playNextWord()
        } else {
            isNavigationAction = false
        }
    }
}

class BookVC: UIViewController {

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
            txtVBook.text = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
            

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
        
        
        
        
        //prepareSpeech(from: txtVBook.text!)
        
//        speechController = SpeechController(content: txtVBook.text!)
//
//        speechController?.onHighlightSegment = { range in
//            // Update your UI to highlight the text within 'range'
//            // For example, if you're using a UITextView, you can set a background color for the text in this range
//            print(range)
//            // Color for highlighting the current spoken word
//
//            let mutableAttributedString = NSMutableAttributedString(string: self.txtVBook.text!)
//
//            let wordHighlightColor = UIColor.red//UIColor.hexStringToUIColor(hex: "007BFF").withAlphaComponent(0.4)
//            mutableAttributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: wordHighlightColor, range: range)
//
//            self.txtVBook.attributedText = mutableAttributedString
//        }
//
//        speechController?.onHighlightWord = { range in
//            print(range)
//            // Color for highlighting the current spoken word
//
//            let mutableAttributedString = NSMutableAttributedString(string: self.txtVBook.text!)
//
//            let wordHighlightColor = UIColor.blue//UIColor.hexStringToUIColor(hex: "007BFF").withAlphaComponent(0.2)
//            mutableAttributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: wordHighlightColor, range: range)
//
//            self.txtVBook.attributedText = mutableAttributedString
//
//        }
//
//        speechController?.play()
    }
    
    func updateTextViewHighlighting() {
        // Create a mutable attributed string from your text view's text
        let mutableAttributedString = NSMutableAttributedString(string: txtVBook.text!)
        
        // Apply sentence highlighting
        if let sentenceRange = highlightedSentenceRange {
            let sentenceHighlightColor = UIColor.red
            mutableAttributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: sentenceHighlightColor, range: sentenceRange)
        }
        
        // Apply word highlighting
        if let wordRange = highlightedWordRange {
            let wordHighlightColor = UIColor.blue
            mutableAttributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: wordHighlightColor, range: wordRange)
        }
        
        // Update your text view's attributed text
        txtVBook.attributedText = mutableAttributedString
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.speechSynthesizer.stopSpeaking(at: .immediate)
        self.speechManager.stop()
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

    func speak(text: String) {
        let speechUtterance = AVSpeechUtterance(string: text)
        speechUtterance.voice = AVSpeechSynthesisVoice(identifier: self.setting?.voice?.identifier ?? "com.apple.voice.compact.en-IN.Rishi")
        speechUtterance.rate = Float(setting?.rate ?? utteranceRate)
        speechSynthesizer.speak(speechUtterance)
    }
    
//    private func tokenizeSentences(from text: String) -> [String] {
//        let linguisticTagger = NSLinguisticTagger(tagSchemes: [.tokenType], options: 0)
//        linguisticTagger.string = text
//
//        let range = NSRange(location: 0, length: text.utf16.count)
//        var sentences = [String]()
//
//        linguisticTagger.enumerateTags(in: range, unit: .sentence, scheme: .tokenType, options: []) { _, tokenRange, _ in
//            let sentence = (text as NSString).substring(with: tokenRange)
//            sentences.append(sentence)
//        }
//
//        return sentences
//    }
//
//
//    func prepareSpeech(from text: String) {
//        self.sentences = tokenizeSentences(from: text)
//        currentSentenceIndex = 0
//    }
    
    func play() {
        guard currentSentenceIndex >= 0 && currentSentenceIndex < sentences.count else {
            return
        }
        let utterance = AVSpeechUtterance(string: sentences[currentSentenceIndex])
        synthesizer.speak(utterance)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    func fastForward() {
        stop()
        currentSentenceIndex = min(currentSentenceIndex + 1, sentences.count - 1)
        play()
    }
    
    func rewind() {
        stop()
        currentSentenceIndex = max(currentSentenceIndex - 1, 0)
        play()
    }


}

//MARK:- IBActions

extension BookVC {
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
    
    @IBAction func btnBackward(_ sender: UIButton) {
        speechController?.rewind()
        rewind()
    }
    
    @IBAction func btnForward(_ sender: UIButton) {
        speechController?.fastForward()
    }
    
    @IBAction func btnSpeed(_ sender: Any) {
        showPickerInAlertController()
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
        
//        print("===========================================")
//        print(entireText.substring(with: sentenceRange))
//        print("===========================================")
        
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
    func voiceSelected(selectedMainVoice: AVSpeechSynthesisVoice, voice: Voice) {
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

extension BookVC {
    
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

extension BookVC: UIPickerViewDelegate, UIPickerViewDataSource {
    
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
