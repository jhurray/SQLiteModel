//
//  BlogComposeViewController.swift
//  Blogz4Dayz
//
//  Created by Jeff Hurray on 4/9/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import UIKit
import Neon
import SQLiteModel

class BlogComposeViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate,
ImageCollectionViewDatasource {

    var blog: BlogModel? {
        didSet {
            imageCollectionDelegate = ImageCollectionDelegate(navController: self.navigationController, blog: blog)
            imageCollection.delegate = imageCollectionDelegate!
        }
    }
    let textField = UITextField()
    let textView = UITextView()
    let filler = UIView()
    let imageCollection = ImageCollectionView(frame: CGRectZero)
    var imageCollectionDelegate: ImageCollectionDelegate?
    let keyBoardHeight: CGFloat = 280
    let textColor = UIColor.whiteColor()
    
    // MARK: ImageCollectionViewDatasource
    var images: [Image] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = true
        self.edgesForExtendedLayout = UIRectEdge.None
        
        view.backgroundColor = color
        let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "dismiss")
        let saveButton = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "saveTouched")
        let deleteButton = UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: "deleteTouched")
        navigationItem.leftBarButtonItem = doneButton
        navigationItem.rightBarButtonItems = [deleteButton, saveButton]
        
        imageCollectionDelegate = ImageCollectionDelegate(navController: self.navigationController!, blog: blog)
        imageCollection.delegate = imageCollectionDelegate!
        imageCollection.dataSource = self
        view.addSubview(imageCollection)
        
        textView.backgroundColor = textColor
        textView.editable = true
        textView.scrollEnabled = true
        textView.delegate = self
        view.addSubview(textView)
        
        textField.backgroundColor = textColor
        textField.placeholder = "Title"
        textField.tintColor = UIColor.darkGrayColor()
        textField.clearButtonMode = .WhileEditing
        textField.delegate = self
        view.addSubview(textField)
        
        view.addSubview(filler)
        
        textField.anchorAndFillEdge(.Top, xPad: 16, yPad: 16, otherSize: 36)
        imageCollection.alignAndFillWidth(align: .UnderCentered, relativeTo: textField, padding: 8, height: 160)
        filler.anchorAndFillEdge(.Bottom, xPad: 0, yPad: 0, otherSize: keyBoardHeight)
        textView.alignBetweenVertical(align: .UnderCentered, primaryView: imageCollection, secondaryView: filler, padding: 8, width: textField.width)
    }
    
    func reload() {
        if let model = blog {
            textView.text = model => BlogModel.Body
            textField.text = model => BlogModel.Title
            
            model ~* BlogModel.Images ~* { imageModels in
                dispatch_async(dispatch_get_main_queue(), {
                    self.images = imageModels.flatMap {$0 as Image}
                    self.imageCollection.reload()
                })
            }
        }
        else {
            textField.text = ""
            textView.text = ""
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        textField.resignFirstResponder()
        textView.resignFirstResponder()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.reload()
    }
    
    func dismiss() {
        if self.navigationController!.viewControllers.count > 1 {
            self.navigationController?.popViewControllerAnimated(true)
        }
        else {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func saveTouched() {
        if var model = blog {
            model <| BlogModel.Title |> (self.textField.text != nil ||  self.textField.text == "" ? self.textField.text! : "Empty Title")
            model <| BlogModel.Body |> self.textView.text
            let _ = try? model.save()
        }
    }
    
    func deleteTouched() {
        if let model = blog {
            let _ = try? model.delete()
            dismiss()
        }
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
