//
//  TextToSpeechTblCell.swift
//  TextToSpeechDemo
//
//  Created by Mac-0006 on 23/08/23.
//

import UIKit

class TextToSpeechTblCell: UITableViewCell {
    
    @IBOutlet weak var lblLanguage: UILabel!
    @IBOutlet weak var lblNameVoiceAssistant: UILabel!
    @IBOutlet weak var lblText: UILabel!
    @IBOutlet weak var viewMain: UIView!
    @IBOutlet weak var btnPlay: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutSubviews() {
        viewMain.layer.cornerRadius = 10
        viewMain.layer.masksToBounds = true

    }

}
