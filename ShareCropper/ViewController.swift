//
//  ViewController.swift
//  ShareCropper
//
//  Created by Adam Wayland on 9/12/15.
//  Copyright (c) 2015 Adam Wayland. All rights reserved.
//
//  ShareCropper is an image and potentially video cropping app that provides the standard film aspect ratios as well as custom aspect ratios.

import UIKit
import MobileCoreServices

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let academy = 1.33
    let europeanWS = 1.66
    let sixteenNine = 1.77
    let americanWS = 1.85
    let seventyMM = 2.2
    let anamorphic = 2.35 //could be 2.39
    let cinerama = 2.77
    
    
    
    let ratiosArr: [Double] = [ 1.33,    //"Academy"
                                1.66,       //"European"
                                1.77,       //"HDTV" 16:9
                                1.85,       //"American"
                                2.2,        //"70mm"
                                2.35,       //"Anamorphic"
                                2.77 ]      //"Cinerama"
    
    var pickerTitleArr = [  "Academy 1.33",
                            "European 1.66",
                            "HDTV 16:9",
                            "American 1:85",
                            "70mm 2.2",
                            "Anamorphic 2.35",
                            "Cinerama 2.77" ]

    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var cropImageView: UIImageView!
    
    @IBAction func cropPressed(sender: UIButton) {
        cropImage()
    }
    
    func cropImage() {
        let ratio = ratiosArr[pickerView.selectedRowInComponent(0)]
        let cropRectSize = CGSizeMake(cropImageView.bounds.width, cropImageView.bounds.width / CGFloat(ratio))
        cropImageView.bounds.size = cropRectSize
        print(ratio)
    }
    
    //var newMedia: Bool? //Use when implement camera
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerTitleArr.count
    }
    
    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: pickerTitleArr[row], attributes: [NSForegroundColorAttributeName:UIColor.whiteColor()])
    }
    
    @IBAction func useCameraRoll(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum) {
            let imagePicker = UIImagePickerController()
            
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            imagePicker.mediaTypes = [kUTTypeImage as String]
            imagePicker.allowsEditing = false
            
            self.presentViewController(imagePicker, animated: true, completion: nil)
            
            //newMedia = false
        }
        
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        self.dismissViewControllerAnimated(true, completion: nil)
        if mediaType == kUTTypeImage as String {
            let pickedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            cropImageView.image = pickedImage;
//            if (newMedia == true) {
//                UIImageWriteToSavedPhotosAlbum(image, self,
//                    "image:didFinishSavingWithError:contextInfo:", nil)
//            } else if mediaType.isEqualToString(kUTTypeMovie as! String) {
//                // Code to support video here
//            }
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerView.delegate = self
        pickerView.dataSource = self
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        cropImage()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

