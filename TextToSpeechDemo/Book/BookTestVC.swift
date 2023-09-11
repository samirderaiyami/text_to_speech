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
import NaturalLanguage

enum SpeechControls {
    case none
    case forwards
    case backwards
    case continuePlaying
}

enum SourceType {
    case scanPages
    case copyPaste
    case insertWebsiteLink
    case importICloudLink
}

enum PickerType {
    case none
    case voice
    case speed
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
    @IBOutlet weak var btnPlay: UIButton!
    
    var image = UIImage(named: "book")
    var websiteURL = URL(string: "https://www.rakiyaworld.com/blog/dummy-text")!
    var pdfURL: URL?
    var ranges: [Range<String.Index>] = []
    var sourceType: SourceType = .scanPages
    var currentPlayingSentenceIndex = 0
    
    var speechSynthesizer: AVSpeechSynthesizer?
    var arrVoices: [Voice] = []
    var index: Int = 0
    
    // set the speaking speed
    var utteranceRate = 0.5
    var setting: Setting?
    var lastSpokenWordEndPosition: Int = 0
    
    var speechManager: SpeechManager = SpeechManager(delay: 0.0)
    
    var speechController: SpeechController?
    var isPlay = false
    private var sentences: [String] = []
    private var currentSentenceIndex: Int = 0
    
    
    private var arrSpeeds: [String] = [
        "0.1", "0.2", "0.3", "0.4", "0.5", "0.6", "0.7", "0.8", "0.9", "1.0"
    ]
    private var highlightedSentenceRange: NSRange?
    private var highlightedWordRange: NSRange?
    
    var segments: [SpeechSegment] = []
    var totalLengthOfPreviousSentences = 0
    var speechControls: SpeechControls = .continuePlaying
    var pickerType: PickerType = .none
    
    var speechUtterance = AVSpeechUtterance()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getTheVoicesList()
        txtVBook.font = UIFont(name: Fonts.SFProRoundedRegular, size: CGFloat(Int(setting?.fontSize ?? 17)))!
        
        self.speechSynthesizer = AVSpeechSynthesizer()
        self.speechSynthesizer?.delegate = self
        
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
            txtVBook.text = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged."
            
            self.sentences = txtVBook.text.components(separatedBy: ". ")
            self.addLineSpacingToTheText()
        } else if sourceType == .insertWebsiteLink {
            
            fetchWebsiteContent(url: websiteURL.absoluteString) { html, error in
                if let html = html {
                    let extractedText = self.extractTextFromHTML(html: html)
                    DispatchQueue.main.async {
                        self.txtVBook.text = extractedText?.trimmingCharacters(in: .whitespaces)
                        var sentencesArray: [String] = []
                        let tokenizer = NLTokenizer(unit: .sentence)
                        tokenizer.string = extractedText!
                        
                        tokenizer.enumerateTokens(in: extractedText!.startIndex..<extractedText!.endIndex) { (range, _) in
                            let sentence = String(extractedText![range])
                            if sentence != "\n" {
                                sentencesArray.append(sentence)
                            }
                            return true
                        }
                        
                        // Print the sentences
                        for sentence in sentencesArray {
                            print(sentence)
                        }
                        
                        
                        self.sentences = sentencesArray
                        self.addLineSpacingToTheText()
                    }
                } else {
                    print("Error fetching content: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
            
            
        } else if sourceType == .importICloudLink {
            let pdf = PDFDocument(url: self.pdfURL!)
            let finalStr = pdf!.string!.trim
            self.txtVBook.text = finalStr
            self.sentences = txtVBook.text.components(separatedBy: ". ")
            addLineSpacingToTheText()
        }
        
        
        var position = 0
        
        for sentence in self.sentences {
            let sentenceNsString = sentence as NSString
            var lastPosition = 0
            let words = sentence.components(separatedBy: " ").compactMap { word -> WordSegment? in
                let searchRange = NSRange(location: lastPosition, length: sentenceNsString.length - lastPosition)
                let range = sentenceNsString.range(of: word, options: [], range: searchRange)
                if range.location != NSNotFound {
                    lastPosition = range.location + range.length
                    return WordSegment(text: word, range: range)
                }
                return nil
            }
            let range = NSRange(location: position, length: sentence.count)
            segments.append(SpeechSegment(text: sentence, range: range, words: words))
            position += sentence.count + 2 // +2 accounts for ". "
        }
        
        
        print("-=-=--=-=-=--=-=--=-=-=-=-=-=-")
        print(segments)
        print(segments.count)
        print("-=-=--=-=-=--=-=--=-=-=-=-=-=-")
        
    }
    
    func getTheVoicesList() {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        for voice in voices {
            arrVoices.append(Voice(identifier: voice.identifier, language: voice.language, name: voice.name, quality: voice.quality.rawValue))
            print("\(debugPrint(voice))")
            
            print("Voice identifier: \(voice.identifier), Language: \(voice.language), Name: \(voice.name), Quality: \(voice.quality.rawValue)")
        }
    }
    
    func addLineSpacingToTheText() {
        let attributedString1 = NSMutableAttributedString(string: txtVBook.text!)
        
        attributedString1.addAttribute(NSAttributedString.Key.font, value: UIFont(name: Fonts.SFProRoundedRegular, size: 17)!, range: NSRange(location: 0, length: attributedString1.length))
        
        let paragraphStyle = NSMutableParagraphStyle()
        
        paragraphStyle.lineSpacing = 15
        
        attributedString1.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString1.length))
        
        txtVBook.attributedText = attributedString1
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
    
    func makeSentenceHighlited(sentence: String) {
        
        let range = (txtVBook.text! as NSString).range(of: sentence)
        
        let mutableAttributedString = NSMutableAttributedString.init(string: txtVBook.text!)
        
        let sentenceHighlightColor = UIColor.hexStringToUIColor(hex: "007BFF").withAlphaComponent(0.2)
        mutableAttributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: sentenceHighlightColor, range: range)
        
        txtVBook.attributedText = mutableAttributedString
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.speechSynthesizer?.stopSpeaking(at: .immediate)
        self.speechSynthesizer = nil
    }
    
    func speak(text: String) {
        speechUtterance = AVSpeechUtterance(string: text)
        speechUtterance.voice = AVSpeechSynthesisVoice(identifier: self.setting?.voice?.identifier ?? "com.apple.voice.compact.en-IN.Rishi")
        speechUtterance.rate = Float(setting?.rate ?? utteranceRate)
        speechSynthesizer?.speak(speechUtterance)
    }
    
}

//MARK:- IBActions

extension BookTestVC {
    @IBAction func btnPlay(_ sender: UIButton) {
        
        isPlay = !isPlay
        speechControls = .continuePlaying
        if isPlay {
            sender.setNormalTitle(normalTitle: "􀊆")
            if speechSynthesizer?.isSpeaking ?? false {
                speechSynthesizer?.continueSpeaking()
            } else {
                self.speechSynthesizer?.stopSpeaking(at: .immediate)
                self.speak(text: sentences[currentSentenceIndex])
            }
        } else {
            sender.setNormalTitle(normalTitle: "􀊄")
            self.speechSynthesizer?.pauseSpeaking(at: .immediate)
        }
        
        //        isPlay = !isPlay
        //
        //        if isPlay {
        //            sender.setNormalTitle(normalTitle: "􀊆")
        //            if speechSynthesizer.isSpeaking {
        //                speechSynthesizer.continueSpeaking()
        //            } else {
        //                self.speechSynthesizer.stopSpeaking(at: .immediate)
        //                self.speechManager.stop()
        //                self.speak(text: sentences[currentSentenceIndex])
        //            }
        //        } else {
        //            sender.setNormalTitle(normalTitle: "􀊄")
        //            self.speechSynthesizer.pauseSpeaking(at: .immediate)
        //        }
    }
    
    @IBAction func btnVoiceClicks(_ sender: UIButton) {
        isPlay = false
        speechControls = .none
        btnPlay.setNormalTitle(normalTitle: "􀊄")
        currentSentenceIndex = 0
        self.speechSynthesizer?.stopSpeaking(at: .immediate)
        pickerType = .voice
        showPickerInAlertController(type: .voice)
        //        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "VoicesVC") as? VoicesVC
        //        vc?.delegate = self
        //        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
    @IBAction func btnBackward(_ sender: UIButton) {
        speechControls = .backwards
        self.speechSynthesizer?.stopSpeaking(at: .immediate)
        self.speechManager.stop()
    }
    
    @IBAction func btnForward(_ sender: UIButton) {
        speechControls = .forwards
        self.speechSynthesizer?.stopSpeaking(at: .immediate)
        self.speechManager.stop()
    }
    
    @IBAction func btnSpeed(_ sender: Any) {
        pickerType = .speed
        showPickerInAlertController(type: .speed)
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
        
        // Update the total length of previously spoken sentences
        totalLengthOfPreviousSentences += utterance.speechString.count
        
        
        if speechControls == .forwards || speechControls == .continuePlaying {
            if currentSentenceIndex  < sentences.count - 1 {
                currentSentenceIndex += 1
            } else {
                self.speechSynthesizer?.stopSpeaking(at: .immediate)
            }
            isPlay = true
            self.btnPlay.setNormalTitle(normalTitle: "􀊆")
            self.speak(text: sentences[currentSentenceIndex])
        } else if speechControls == .backwards {
            if currentSentenceIndex > 0  {
                currentSentenceIndex -= 1
                
            }
            self.isPlay = true
            self.btnPlay.setNormalTitle(normalTitle: "􀊆")
            self.speak(text: sentences[currentSentenceIndex])
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
        //        synthesizer.stopSpeaking(at: .immediate)
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
            attributedString1.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.hexStringToUIColor(hex: "007BFF").withAlphaComponent(0.2), range: nsSentenceRange)
            DispatchQueue.main.async {
                self.txtVBook.scrollRangeToVisible(nsSentenceRange)
                self.view.layoutIfNeeded()
            }
            // Highlight the current word
            attributedString1.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.hexStringToUIColor(hex: "007BFF").withAlphaComponent(0.4), range: adjustedRange)
        }
        
        attributedString1.addAttribute(NSAttributedString.Key.font, value: UIFont(name: Fonts.SFProRoundedRegular, size: 17)!, range: NSRange(location: 0, length: attributedString1.length))
        
        let paragraphStyle = NSMutableParagraphStyle()
        
        paragraphStyle.lineSpacing = 15 // Whatever line spacing you want in points
        
        attributedString1.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString1.length))
        
        DispatchQueue.main.async {
            self.txtVBook.attributedText = attributedString1
        }
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
    func voiceSelected(selectedMainVoice: AVSpeechSynthesisVoice, voice: Voice) {
        speechSynthesizer = AVSpeechSynthesizer()
        setting?.voice = voice
    }
    
}



extension BookTestVC {
    
    func showPickerInAlertController(type: PickerType) {
        
        // Create a UIAlertController with a custom content view
        let alertController = UIAlertController(title: type == .speed ? "Playback Speed:" : "Select voice", message: "\n\n\n\n\n\n\n", preferredStyle: .actionSheet)
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
            if type == .speed {
                if let index = self.arrSpeeds.firstIndex(where: {$0 == "\(self.setting?.rate ?? 0.5)"}) {
                    pickerView.selectRow(index, inComponent: 0, animated: true)
                }
            } else {
                if let index = self.arrVoices.firstIndex(where: {$0.name == self.setting?.voice?.name}) {
                    pickerView.selectRow(index, inComponent: 0, animated: true)
                }
            }
            
        })
        
        alertController.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { _ in
            let value = pickerView.selectedRow(inComponent: 0)
            if type == .speed {
                print("Feet: \(value)")
                let val = Double("0.\(value)") ?? 0.5
                self.setting?.rate = val
                self.btnSpeed.setNormalTitle(normalTitle: "\(val)x")
            } else {
                self.setting?.voice = self.arrVoices[value]
            }
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
        return pickerType == .speed ? arrSpeeds.count : arrVoices.count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        let label = (view as? UILabel) ?? UILabel()
        
        label.textColor = .black
        label.textAlignment = .center
        label.font = UIFont(name: Fonts.SFProRoundedSemibold, size: 18)
        
        // where data is an Array of String
        if pickerType == .voice {
            let objVoice = arrVoices[row]
            label.text = "\(objVoice.name)"
        } else {
            label.text = "\(arrSpeeds[row])"
        }
        
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        100
    }
}
