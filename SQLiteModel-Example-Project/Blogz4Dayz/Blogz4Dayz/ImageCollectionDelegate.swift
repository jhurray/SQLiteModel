//
//  ImageCollectionDelegate.swift
//  Blogz4Dayz
//
//  Created by Jeff Hurray on 4/9/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import Foundation
import UIKit
import SQLiteModel
import SQLite

class ImageCollectionDelegate : NSObject, ImageCollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    weak var navController: UINavigationController?
    var blog: BlogModel?
    
    init(navController: UINavigationController?, blog: BlogModel? = nil) {
        self.navController = navController
        self.blog = blog
    }
    
    // MARK: ImageCollectionViewDelegate
    
    func imageCollectionViewDidTouchImage(image: Image) {
        
    }
    
    func imageCollectionViewWantsToAddImage() {
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePicker.allowsEditing = false
        
        navController!.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        picker.dismissViewControllerAnimated(true) { () -> Void in
            if var model = self.blog {
                var images: [ImageModel] = model => BlogModel.Images
                let data: NSData = UIImagePNGRepresentation(image)!
                let newImage = try! ImageModel.new([ImageModel.Data <- data])
                images.append(newImage)
                model <| BlogModel.Images |> images
                let _ = try? model.save()
            }
        }
    }
    
    @objc func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
