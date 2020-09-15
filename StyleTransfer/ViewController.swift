//
//  ViewController.swift
//  StyleTransfer
//
//  Created by Marta Kramarczyk on 25/08/2020.
//  Copyright © 2020 Marta Kramarczyk. All rights reserved.
//

import UIKit
import Vision
import CoreML

class ViewController: UIViewController {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var pickImageButton: UIButton!
    @IBOutlet var applyFilterButton: UIButton!
    @IBOutlet var applyFilterActivityIndicator: UIActivityIndicatorView!
    @IBOutlet var operationSummaryLabel: UILabel!
    
    let model = TwoFridasStyleTransfer()
    let imagePicker = UIImagePickerController()
    var isFilterApplied: Bool = false
    var isFilterApplyingInProcess: Bool = false
    typealias FilteringCompletion = ((UIImage?) -> ())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
    }

    @IBAction func pickImageButtonTapped(_ sender: UIButton) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func applyButtonTapped(_ sender: UIButton) {
        let methodStart = Date()
        self.stylizeImage(imageToStylize: imageView.image!) {
            filteredImg in self.imageView.image = filteredImg
            let executionTime = String(format: "%.2f seconds", Date().timeIntervalSince(methodStart))
            self.operationSummaryLabel.text = "Success \n enjoy!  \n\n Time elapsed:\n \(executionTime)"
            self.isFilterApplied = true
            self.isFilterApplyingInProcess = false
            self.updateVisibilitiesAndUserInteraction()
        }
    }
    
    func handleError() {
        isFilterApplyingInProcess = false
        DispatchQueue.main.async {
            self.operationSummaryLabel.text = "Failed to process image"
            self.updateVisibilitiesAndUserInteraction()
        }
    }
    
    func stylizeImage(imageToStylize: UIImage, completion: @escaping FilteringCompletion) {
        isFilterApplyingInProcess = true
        updateVisibilitiesAndUserInteraction()
        
        DispatchQueue.global().async {
            
            guard let cvPixelBufferImage = imageToStylize.pixelBuffer(width: 700, height: 700) else {
                self.handleError()
                completion(nil)
                return
            }
            
            guard let output = try? self.model.prediction(content_image: cvPixelBufferImage) else {
                self.handleError()
                completion(nil)
                return
            }
            
            guard let outputImage = UIImage(pixelBuffer: output.styled_image) else {
                self.handleError()
                completion(nil)
                return
            }
            
            let processedImage = outputImage.resize(to: imageToStylize.size)
            DispatchQueue.main.async {
                completion(processedImage)
            }
        }
    }
    
    func initUI() {
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        pickImageButton.layer.cornerRadius = 5
        applyFilterButton.layer.cornerRadius = 5
        updateVisibilitiesAndUserInteraction()
    }
    
    func updateVisibilitiesAndUserInteraction(){
        applyFilterButton.isHidden = ((imageView.image) == nil || isFilterApplied || isFilterApplyingInProcess)
        applyFilterActivityIndicator.isHidden = !isFilterApplyingInProcess
        operationSummaryLabel.isHidden = !isFilterApplied
        pickImageButton.isUserInteractionEnabled = !isFilterApplyingInProcess
    }
}

extension ViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerEditedImage")] as? UIImage{
            imageView.image = image
            isFilterApplied = false
            updateVisibilitiesAndUserInteraction()
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
