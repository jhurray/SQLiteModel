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

class BlogComposeViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {

    var blog: BlogModel? {
        didSet {
            if let model = blog {
                textView.text = model => BlogModel.Body
                textField.text = model => BlogModel.Title
            }
            else {
                textField.text = ""
                textView.text = ""
            }
        }
    }
    let textField = UITextField()
    let textView = UITextView()
    let filler = UIView()
    let keyBoardHeight: CGFloat = 280
    let color = UIColor.whiteColor()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = true
        self.edgesForExtendedLayout = UIRectEdge.None
        
        view.backgroundColor = UIColor.lightGrayColor()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "dismiss")
        let saveButton = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "saveTouched")
        let deleteButton = UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: "deleteTouched")
        navigationItem.leftBarButtonItem = doneButton
        navigationItem.rightBarButtonItems = [deleteButton, saveButton]
        
        textView.backgroundColor = color
        textView.editable = true
        textView.scrollEnabled = true
        textView.delegate = self
        view.addSubview(textView)
        
        textField.backgroundColor = color
        textField.placeholder = "Title"
        textField.tintColor = UIColor.darkGrayColor()
        textField.clearButtonMode = .WhileEditing
        textField.delegate = self
        view.addSubview(textField)
        
        view.addSubview(filler)
        
        textField.anchorAndFillEdge(.Top, xPad: 16, yPad: 18, otherSize: 36)
        filler.anchorAndFillEdge(.Bottom, xPad: 0, yPad: 0, otherSize: keyBoardHeight)
        textView.alignBetweenVertical(align: .UnderCentered, primaryView: textField, secondaryView: filler, padding: 8, width: textField.width)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        textField.resignFirstResponder()
        textView.resignFirstResponder()
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
