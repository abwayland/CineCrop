//
//  ViewController.swift
//  ShareCropper
//
//  Created by Adam Wayland on 9/12/15.
//  Copyright (c) 2015 Adam Wayland. All rights reserved.
//
//  ShareCropper is an image and potentially video cropping app that provides the standard film aspect ratios as well as custom aspect ratios.


// CHECK IF ALL NECESSARY
import UIKit
import MobileCoreServices
import Foundation
import AVFoundation
import CoreMedia

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
    var avPlayer: AVPlayer!
    
    var pickedImage: UIImage = UIImage(named: "cinema cropper.png")!

    @IBOutlet weak var pickerView: UIPickerView!
    
    @IBOutlet weak var saveLabel: UILabel!
    
    @IBAction func savePressed(sender: AnyObject) {
        var cropRect = CGRect()
        cropRect.origin = scrollView.contentOffset
        cropRect.size = scrollView.bounds.size
        
        let scale = 1.0 / scrollView.zoomScale
        
        cropRect.origin.x *= scale
        cropRect.origin.y *= scale
        cropRect.size.width *= scale
        cropRect.size.height *= scale
        
        let orientedImage = fixOrientation(pickedImage)
        
        if let imageRef = CGImageCreateWithImageInRect(orientedImage.CGImage, cropRect) {
            let imageToSave = UIImage(CGImage: imageRef, scale: 1.0, orientation: orientedImage.imageOrientation)
            print("iV: \(imageView.image!.imageOrientation) \npI: \(pickedImage.imageOrientation)")
            UIImageWriteToSavedPhotosAlbum(imageToSave, self, "image:didFinishSavingWithError:contextInfo:", nil)
        }
    }
    
    func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafePointer<Void>) {
        if error == nil {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .Alert)
            ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            presentViewController(ac, animated: true, completion: nil)
        } else {
            let ac = UIAlertController(title: "Save error", message: error?.localizedDescription, preferredStyle: .Alert)
            ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            presentViewController(ac, animated: true, completion: nil)
        }
    }
    
    func fixOrientation(img:UIImage) -> UIImage {
        
        if (img.imageOrientation == UIImageOrientation.Up) {
            return img;
        }
        
        UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale);
        let rect = CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
        img.drawInRect(rect)
        
        let normalizedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        return normalizedImage;
        
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
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        scrollView.frame.size = getCropSize()
        scrollView.frame.origin.y = getCropOrigin()
    }
    
    //MARK: CAMERA ROLL
    
    @IBAction func useCameraRoll(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum) {
            let imagePicker = UIImagePickerController()
            
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            imagePicker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
            imagePicker.allowsEditing = false
            
            self.presentViewController(imagePicker, animated: true, completion: nil)
            
            //newMedia = false
        }
        
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        self.dismissViewControllerAnimated(true, completion: nil)
        for view in scrollView.subviews {
            view.removeFromSuperview()
        }
        if mediaType == kUTTypeImage as String {
            pickedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            imageView = UIImageView(image: pickedImage)
            scrollView.addSubview(imageView)
            setZoomScale(imageView.bounds.size)
        } else if mediaType == kUTTypeMovie as String {
            let videoClipURL = info[UIImagePickerControllerMediaURL] as! NSURL
            
            let asset = AVAsset(URL: videoClipURL)
            
            let item = AVPlayerItem(asset: asset)
            
            avPlayer = AVPlayer(playerItem: item)
            
            let layer = AVPlayerLayer(player: avPlayer)
            avPlayer.actionAtItemEnd = AVPlayerActionAtItemEnd.None
            layer.videoGravity = AVLayerVideoGravityResizeAspectFill
            
//            let tracksARR = asset.tracksWithMediaType(AVMediaTypeVideo)
//            let videoTrack = tracksARR[0]
//            imageView.bounds.size = videoTrack.naturalSize
            
            layer.frame = imageView.bounds
            
            imageView = UIImageView()
            imageView.layer.addSublayer(layer)
            scrollView.addSubview(imageView)
            setZoomScale(imageView.bounds.size)
            
            avPlayer.play()
        }
//            if (newMedia == true) {
//                UIImageWriteToSavedPhotosAlbum(image, self,
//                    "image:didFinishSavingWithError:contextInfo:", nil)
//
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
    
    func setZoomScale(size: CGSize) {
        scrollView.contentSize = size
        let widthScale = scrollView.bounds.size.width / size.width
        scrollView.minimumZoomScale = widthScale
        scrollView.maximumZoomScale = 1.0
        scrollView.zoomScale = widthScale
        }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    //MARK: LIFECYCLE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ratiosArr = [ academy, europeanWS, sixteenNine, americanWS, seventyMM, anamorphic, cinerama ]
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.selectRow(3, inComponent: 0, animated: false)
        scrollView = UIScrollView(frame: CGRect(origin: view.bounds.origin, size: getCropSize()))
        scrollView.frame.origin.y = getCropOrigin()
        scrollView.delegate = self
        view.backgroundColor = UIColor.blackColor()
        imageView = UIImageView(image: pickedImage)
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        setZoomScale(imageView.bounds.size)
    }
    
    func getCropOrigin() -> CGFloat {
        //return ((view.bounds.height - pickerView.frame.height) / 2) - (scrollView.frame.height / 2)
        if let parent = self.parentViewController as! UINavigationController! {
            let navBarHeight = parent.navigationBar.frame.height
            let position = ((view.bounds.height - pickerView.frame.height) / 2) - (scrollView.frame.height / 2) + navBarHeight
            print(position)
            return position
        } else {
            return ((view.bounds.height - pickerView.frame.height) / 2) - (scrollView.frame.height / 2)
        }
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

