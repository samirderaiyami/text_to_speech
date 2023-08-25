//
//  VoicesVC.swift
//  ChatGPTDemo
//
//  Created by Mac-0006 on 03/05/23.
//

import UIKit
import AVFoundation
import AVKit

struct Voice {
    var identifier: String
    var language: String
    var name: String
    var quality: Int
}

protocol VoiceDelegate {
    func voiceSelected(voice: Voice)
}
class VoicesVC: UIViewController {
    
    @IBOutlet weak var tblVoices: UITableView!
    let speechSynthesizer = AVSpeechSynthesizer()
    var arrVoices: [Voice] = []
    var index: Int = 0
    
    // set the speaking speed
    var utteranceRate = 0.5
    
    // set the speaking speed
    var utterancePitch = 1

    var delegate: VoiceDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        speechSynthesizer.delegate = self
        self.title = "Voices"
        // Do any additional setup after loading the view.
        AVSpeechSynthesisVoice.speechVoices()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        listVoices()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.speechSynthesizer.stopSpeaking(at: .immediate)
    }
    
    func textToSpeech(text: String, id: String) {
        let speechUtterance = AVSpeechUtterance(string: text)
        speechUtterance.voice = AVSpeechSynthesisVoice(identifier: id)
        speechUtterance.rate = Float(utteranceRate)
        
        //        speechUtterance.pitchMultiplier = 1.0
        //        speechUtterance.preUtteranceDelay = 0.3
        speechSynthesizer.speak(speechUtterance)
    }
    
    func listVoices() {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        for voice in voices {
            arrVoices.append(Voice(identifier: voice.identifier, language: voice.language, name: voice.name, quality: voice.quality.rawValue))
            print("\(debugPrint(voice))")
            
            print("Voice identifier: \(voice.identifier), Language: \(voice.language), Name: \(voice.name), Quality: \(voice.quality.rawValue)")
        }
        print(self.arrVoices.count)
        tblVoices.reloadData()
    }
    
    @IBAction func btnSettings(sender: UIButton) {
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "SettingsVC") as? SettingsVC
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
    @objc func play(sender:UIButton) {
        index = sender.tag
        self.speechSynthesizer.stopSpeaking(at: .immediate)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.textToSpeech(text: "Hi I am your voice assistant \(self.arrVoices[self.index].name). How are you doing today?", id: self.arrVoices[self.index].identifier)
        })

    }
}
extension VoicesVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrVoices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextToSpeechTblCell", for: indexPath) as! TextToSpeechTblCell
        
        cell.lblLanguage.text = arrVoices[indexPath.row].language
        cell.lblNameVoiceAssistant.text = arrVoices[indexPath.row].name
        cell.lblText.text = "Hi I am your voice assistant \(self.arrVoices[indexPath.row].name). How are you doing today?"
        cell.btnPlay.tag = indexPath.row
        cell.btnPlay.addTarget(self, action: #selector(self.play(sender:)), for: .touchUpInside)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.voiceSelected(voice: arrVoices[indexPath.row])
        self.navigationController?.popViewController(animated: true)
    }
    
}

extension VoicesVC: AVSpeechSynthesizerDelegate {
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
        print("didContinue")
        if let cell = self.tblVoices.cellForRow(at: IndexPath(row: index, section: 0)) as? TextToSpeechTblCell {
            cell.lblText.attributedText = NSAttributedString(string: utterance.speechString)
        }
    }
    //   func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           willSpeakRangeOfSpeechString characterRange: NSRange,
                           utterance: AVSpeechUtterance){
        
        let mutableAttributedString = NSMutableAttributedString(string: utterance.speechString)
        mutableAttributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.lightGray, range: characterRange)
        
        if let cell = self.tblVoices.cellForRow(at: IndexPath(row: index, section: 0)) as? TextToSpeechTblCell {
            cell.lblText.attributedText = mutableAttributedString
        }
        
        let subString = (utterance.speechString as NSString).substring(with: characterRange)
        print("AVSpeechSynthesizerDelegate: willSpeakRangeOfSpeechString with \(characterRange); text: \(subString)")
        
        
    }
    
}
