//
//  ViewController.swift
//  HEIC-editor
//
//  Created by Maysam Shahsavari on 7/29/19.
//  Copyright © 2019 Maysam Shahsavari. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var selectImageButton: UIButton!
    @IBOutlet weak var editImageButton: UIButton!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    
    let pickerController = UIImagePickerController()
    var asset: PHAsset?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .notDetermined  {
            PHPhotoLibrary.requestAuthorization({_ in})
        }
        
        imageView.contentMode = .scaleAspectFill
        infoLabel.numberOfLines = 0
        infoLabel.lineBreakMode = .byWordWrapping
        errorLabel.numberOfLines = 0
        errorLabel.lineBreakMode = .byWordWrapping
    }
    
    @IBAction func selectImage(_ sender: UIButton) {
        pickerController.delegate = self
        pickerController.allowsEditing = false
        pickerController.mediaTypes = ["public.image"]
        pickerController.sourceType = .photoLibrary
        present(pickerController, animated: true, completion: nil)
    }
    
    @IBAction func editImage(_ sender: UIButton) {
        if let _asset = self.asset {
            let dispatchQueue = DispatchQueue.main
            
            let options = PHContentEditingInputRequestOptions()
            options.isNetworkAccessAllowed = true
            _asset.requestContentEditingInput(with: options, completionHandler: { (contentEditingInput, info) in
                let fullURL: URL?
                fullURL = contentEditingInput!.fullSizeImageURL
                
                let output = PHContentEditingOutput(contentEditingInput:
                    contentEditingInput!)
                let archivedData = try? NSKeyedArchiver.archivedData(withRootObject: "HEICEditor", requiringSecureCoding: false)
                let adjustmentData =
                    PHAdjustmentData(formatIdentifier:
                        "HEICEditor.App",
                                     formatVersion: "1.0",
                                     data: archivedData!)
                
                output.adjustmentData = adjustmentData
                let imageData = UIImage.init(contentsOfFile: fullURL!.path)?.jpegData(compressionQuality: 0.5)
                
                do {
                    dispatchQueue.async {
                        self.infoLabel.text = "fullSizeImageURL: \(fullURL?.lastPathComponent ?? "N/A")\n" +
                        "renderedContentURL: \(output.renderedContentURL.lastPathComponent)"
                    }
                    try imageData!.write(to: output.renderedContentURL, options: .atomic)
                } catch let error {
                    print("error writing data:\(error)")
                }
                
                PHPhotoLibrary.shared().performChanges({
                    let request = PHAssetChangeRequest(for: _asset)
                    request.contentEditingOutput = output
                    
                }, completionHandler: { (result, error) in
                    dispatchQueue.async {
                        self.errorLabel.text = "result: \(result), error: \(String(describing: error))"
                    }
                    
                })
                
            })
            
        }
    }
    
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset {
            self.asset = asset
        }
        
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = pickedImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
