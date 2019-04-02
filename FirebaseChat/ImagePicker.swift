//
//  ImagePicker.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 27/02/2019.
//  Copyright © 2019 Curly Bracers. All rights reserved.
//

import UIKit
import Foundation
import AssetsLibrary
import Photos

class ImagePicker: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    static let shared = ImagePicker()
    
    fileprivate var completion: ((_ image: UIImage)->Void)?
    fileprivate var urlCompletion: ((_ fileURL: URL, _ referenceURL: URL)->Void)?
    fileprivate weak var viewController: UIViewController?
    
    func pickImage (_ sender: UIViewController?, completion: ((_ image: UIImage)->Void)? = nil, urlCompletion: ((_ fileURL: URL, _ referenceURL: URL)->Void)? = nil) {
        
        self.completion = completion
        self.urlCompletion = urlCompletion
        viewController = sender
        
        weak var weakself = self
        
        let alertController = UIAlertController(title: "Pick the Picture", message: nil, preferredStyle: .actionSheet)
        
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)) {
            let takePhoto = UIAlertAction(title: "Take Photo", style: .default, handler: { (action) -> Void in
                weakself?.takePhoto()
            })
            alertController.addAction(takePhoto)
        }
        
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary)) {
            let gallery = UIAlertAction(title: "Select from Gallery", style: .default, handler: { (action) -> Void in
                weakself?.selectPhoto()
            })
            alertController.addAction(gallery)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
            
        })
        alertController.addAction(cancel)
        
        sender?.navigationController?.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Actions
    
    fileprivate func takePhoto() {
        askForCameraPermission { [weak self] (success) in
            if success {
                DispatchQueue.main.async {
                    let picker: UIImagePickerController = UIImagePickerController()
                    picker.delegate = self
                    picker.allowsEditing = true
                    picker.sourceType = .camera
                    self?.viewController?.present(picker, animated: true, completion: nil)
                }
            }
        }
    }
    
    fileprivate func selectPhoto() {
        askForPhotosPermission { [weak self] (success) in
            if success {
                DispatchQueue.main.async {
                    let picker: UIImagePickerController = UIImagePickerController()
                    picker.delegate = self
                    picker.allowsEditing = true
                    picker.sourceType = .photoLibrary
                    self?.viewController?.present(picker, animated: true, completion: nil)
                }
            }
        }
    }
    
    
    func askForCameraPermission(completion: ((_ success: Bool)->Void)? = nil) {
        // Camera
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { success in
            completion?(success)
        })
    }
    
    
    func askForPhotosPermission(completion: ((_ success: Bool)->Void)? = nil) {
        // Photos
        let photos = PHPhotoLibrary.authorizationStatus()
        switch photos {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({status in
                if status == .authorized {
                    completion?(true)
                } else {
                    completion?(false)
                }
            })
        case .authorized:
            completion?(true)
        default:
            completion?(false)
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let chosenImage: UIImage = info[.editedImage] as? UIImage {
            completion?(chosenImage)
        }
        
        if let photoReferenceUrl = info[.referenceURL] as? URL, let urlCompletion = urlCompletion {
            // Handle picking a Photo from the Photo Library
            let assets = PHAsset.fetchAssets(withALAssetURLs: [photoReferenceUrl], options: nil)
            let asset = assets.firstObject
            
            asset?.requestContentEditingInput(with: nil, completionHandler: { (contentEditingInput, info) in
                if let imageFileURL = contentEditingInput?.fullSizeImageURL {
                    urlCompletion(imageFileURL, photoReferenceUrl)
                }
            })
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
