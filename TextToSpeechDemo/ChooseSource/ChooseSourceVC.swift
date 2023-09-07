//
//  ChooseSourceVC.swift
//  TextToSpeechDemo
//
//  Created by Mac-0006 on 25/08/23.
//

import UIKit
import UniformTypeIdentifiers
import MobileCoreServices

class ChooseSourceVC: UIViewController {
    
    var txtEnterWebsiteLink: UITextField?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func chooseSouceClick(_ sender: UIButton) {
        if sender.tag == 1 {
            //.. Scan Pages
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .camera
                imagePicker.allowsEditing = false
                self.present(imagePicker, animated: true, completion: nil)
            } else {
                print("Camera not available")
            }

        } else if sender.tag == 2 {
            //.. Copy, Paste or Write Text
            let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "BookTestVC") as! BookTestVC
            vc.sourceType = .copyPaste
            self.navigationController?.pushViewController(vc, animated: true)

        } else if sender.tag == 3 {
            //.. Insert Website Link
            self.presentAlertViewWithOneTextField(alertTitle: "Paste Website Link Here:", alertMessage: "Insert a website link to convert the text to audio.", alertFirstTextFieldHandler: { textField in
                self.txtEnterWebsiteLink = textField
                
            }, btnOneTitle: "Cancel", btnOneTapped: nil, btnTwoTitle: "Enter") { action in
                if self.verifyUrl(urlString: self.txtEnterWebsiteLink?.text!) {
                    if !(self.txtEnterWebsiteLink?.text?.isEmpty ?? false) {
                        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "BookVC") as! BookVC
                        vc.sourceType = .insertWebsiteLink
                        vc.websiteURL = URL(string: self.txtEnterWebsiteLink?.text ?? "")!
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                } else {
                    self.presentAlertViewWithOneButton(alertTitle: nil, alertMessage: "Please enter proper url", btnOneTitle: "Okay", btnOneTapped: nil)
                }
                
            }

        } else {
            selectFiles()
        }
    }
    
    func verifyUrl (urlString: String?) -> Bool {
        if let urlString = urlString {
            if let url = NSURL(string: urlString) {
                return UIApplication.shared.canOpenURL(url as URL)
            }
        }
        return false
    }
    
    func selectFiles() {
        let types: [UTType] = [UTType(filenameExtension: "pdf")! ]

        let documentPickerController = UIDocumentPickerViewController(
            forOpeningContentTypes: types)
        documentPickerController.delegate = self
        self.present(documentPickerController, animated: true, completion: nil)
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ChooseSourceVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        dismiss(animated:true, completion: {
            let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "BookVC") as! BookVC
            vc.image = info[.originalImage] as? UIImage
            vc.sourceType = .scanPages
            self.navigationController?.pushViewController(vc, animated: true)
        })

    }
}

extension ChooseSourceVC: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        guard let myURL = urls.first else {
            return
        }
        
        print("import result : \(myURL)")
        
        //.. Import iCloud File
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "BookVC") as! BookVC
        vc.sourceType = .importICloudLink
        vc.pdfURL = myURL
        self.navigationController?.pushViewController(vc, animated: true)

    }
    
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("view was cancelled")
        dismiss(animated: true, completion: nil)
    }
}

