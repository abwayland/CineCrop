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

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIScrollViewDelegate {
    
    
    //Aspect ratio Constants
    let academy = 1.33
    let europeanWS = 1.66
    let sixteenNine = 1.77
    let americanWS = 1.85
    let seventyMM = 2.2
    let anamorphic = 2.35 //also 2.39
    let cinerama = 2.77
    
    var ratiosArr: [Double] = []
    
    var pickerTitleArr = [  "Academy 1.33",
                            "European WS 1.66",
                            "HDTV 16:9",
                            "American WS 1.85",
                            "70mm 2.2",
                            "Anamorphic 2.35",
                            "Cinerama 2.77" ]
    
    var imageView: UIImageView!
    var scrollView: UIScrollView!
    
    var pickedImage: UIImage = UIImage(named: "cinema cropper.png")!

    @IBOutlet weak var pickerView: UIPickerView!
    
    
    @IBAction func cropPressed(sender: UIButton) {
        scrollView.frame.size = getCropSize()
        scrollView.frame.origin.y = getCropOrigin()
    }
    
    //MARK: PICKERVIEW
    
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
            pickedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            for view in scrollView.subviews {
                view.removeFromSuperview()
            }
            imageView = UIImageView(image: pickedImage)
            scrollView.addSubview(imageView)
            setZoomScale()
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

    //MARK: SCROLLVIEW
    
    //Adjusts the size of the scrollView to the appropriate aspect ratio chosen in the pickerController
    func getCropSize() -> CGSize {
        let ratio = ratiosArr[pickerView.selectedRowInComponent(0)]
        let cropRectSize = CGSizeMake(view.bounds.width, view.bounds.width / CGFloat(ratio))
        return cropRectSize
    }
    
    func setZoomScale() {
        scrollView.contentSize = imageView.bounds.size
        let widthScale = scrollView.bounds.size.width / imageView.bounds.size.width
        scrollView.minimumZoomScale = widthScale
        scrollView.maximumZoomScale = 1.0
        scrollView.zoomScale = widthScale
        }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return scrollView.subviews[0]
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
//        centerScrollViewContents()
    }
    
    //MARK: LIFECYCLE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ratiosArr = [ academy, europeanWS, sixteenNine, americanWS, seventyMM, anamorphic, cinerama ]
        pickerView.delegate = self
        pickerView.dataSource = self
        scrollView = UIScrollView(frame: CGRect(origin: view.bounds.origin, size: getCropSize()))
        scrollView.frame.origin.y = getCropOrigin()
        scrollView.delegate = self
        view.backgroundColor = UIColor.blackColor()
        imageView = UIImageView(image: pickedImage)
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        setZoomScale()
    }
    
    func getCropOrigin() -> CGFloat {
        return ((view.bounds.height - pickerView.frame.height) / 2) - (scrollView.frame.height / 2)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        scrollView.layer.borderWidth = 1
        scrollView.layer.borderColor = UIColor.redColor().CGColor
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

