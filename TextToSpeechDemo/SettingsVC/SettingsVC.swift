//
//  SettingsVC.swift
//  TextToSpeechDemo
//
//  Created by Mac-0006 on 24/08/23.
//

import UIKit


protocol SettingsDelegate {
    func settingChanged(setting: Setting?)
}

class SettingsVC: UIViewController {
    
    //.. Voice
    @IBOutlet weak var sliderRate: UISlider!
    @IBOutlet weak var sliderPitch: UISlider!
    
    @IBOutlet weak var lblVoice: UILabel!

    var delegate: SettingsDelegate?
    var setting: Setting?

    //.. Settings
    @IBOutlet weak var switchClearText: UISwitch!
    @IBOutlet weak var switchSpeakAsYouType: UISwitch!
    @IBOutlet weak var switchHighlightSpokenText: UISwitch!
    @IBOutlet weak var switchRecentPhrase: UISwitch!

    
    @IBOutlet weak var sliderDelay: UISlider!
    @IBOutlet weak var sliderFontSize: UISlider!

    // set the speaking speed
    var utteranceRate = 0.5
    
    // set the speaking speed
    var utterancePitch = 1.0

    override func viewDidLoad() {
        super.viewDidLoad()
        setting = Setting()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func sliderRate(_ sender: UISlider) {
        let val = Double(sender.value)
        utteranceRate = val
        setting?.rate = val
        delegate?.settingChanged(setting: setting)
    }
    
    @IBAction func sliderPitch(_ sender: UISlider) {
        let val = Double(sender.value)
        utterancePitch = val
        setting?.pitch = val
        delegate?.settingChanged(setting: setting)
    }
    
    @IBAction func switchClearText(_ sender: UISwitch) {
        setting?.clearText = sender.isOn
        delegate?.settingChanged(setting: setting)
    }
    
    @IBAction func switchSpeakAsYouType(_ sender: UISwitch) {
        setting?.speakAsYouType = sender.isOn
        delegate?.settingChanged(setting: setting)
    }
    
    
    @IBAction func switchHighlightSpokenText(_ sender: UISwitch) {
        setting?.highlightText = sender.isOn
        delegate?.settingChanged(setting: setting)
    }
    
    
    @IBAction func switchRecentPhrase(_ sender: UISwitch) {
        setting?.recentPhrase = sender.isOn
        delegate?.settingChanged(setting: setting)
    }
    
    @IBAction func sliderDelay(_ sender: UISlider) {
        let val = Double(sender.value)
        setting?.delay = val
        delegate?.settingChanged(setting: setting)
    }
    
    @IBAction func sliderFontSize(_ sender: UISlider) {
        let val = Double(sender.value)
        setting?.fontSize = Int(val)
        delegate?.settingChanged(setting: setting)
    }

}

extension SettingsVC {
    @IBAction func btnVoiceClicks(sender: UIButton) {
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "VoicesVC") as? VoicesVC
        vc?.delegate = self
        self.navigationController?.pushViewController(vc!, animated: true)
    }
}

extension SettingsVC: VoiceDelegate {
    func voiceSelected(voice: Voice) {
        lblVoice.text = voice.name
        setting?.voice = voice
        delegate?.settingChanged(setting: setting)
        
    }
}
