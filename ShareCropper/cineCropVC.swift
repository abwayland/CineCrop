//
//  ViewController.swift
//  ShareCropper
//
//  Created by Adam Wayland on 9/12/15.
//  Copyright (c) 2015 Adam Wayland. All rights reserved.
//
//  ShareCropper is an image and video cropping app that provides traditional motion picture aspect ratios as well as custom aspect ratios.


import UIKit
import MobileCoreServices
import AVFoundation
import CoreMedia
import AssetsLibrary

class cineCropVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIScrollViewDelegate {
    
    //MARK: Constants and Variables
    
    let model = CinemaCropperModel()
    
    // Title for UIPickerController
    let pickerTitleArr = [  "Academy [1.33:1]",
                            "European WS [1.66:1]",
                            "HDTV [16:9]",
                            "American WS [1.85:1]",
                            "70mm [2.2:1]",
                            "Anamorphic [2.35:1]",
                            "Cinerama [2.77:1]" ]
    
    // Variables
    var imageView: UIImageView!
    var scrollView: UIScrollView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    //MARK: Outlets and Actions

    @IBOutlet weak var pickerView: UIPickerView!
    
    //MARK: Save
    
    @IBOutlet weak var errLabel: UILabel!
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBAction func savePressed(sender: AnyObject) {
        if errLabel.hidden == false {
            errLabel.hidden = true
        }
        //creates a cropRect based on size of scrollView and scales according to zoom
        model.setFrame(origin: scrollView.contentOffset, size: scrollView.bounds.size, zoom: scrollView.zoomScale)
        
//      PHOTO
        if model.mediaType == kUTTypeImage as String {
            
            let orientedImage = fixOrientation(model.pickedImage!)
            
            if let imageRef = CGImageCreateWithImageInRect(orientedImage.CGImage, model.getFrame()) {
                let imageToSave = UIImage(CGImage: imageRef, scale: 1.0, orientation: orientedImage.imageOrientation)
                UIImageWriteToSavedPhotosAlbum(imageToSave, self, "image:didFinishSavingWithError:contextInfo:", nil)
            }
            
//      VIDEO
        } else if model.mediaType == kUTTypeMovie as String {
            
            exportVideo()

        }
    }
    
    func getLBImage(size: CGSize, color: UIColor) -> UIImage {
        
        let lbRect = CGRect(origin: CGPointMake(0,0), size: CGSizeMake(size.width, (size.width - size.height) / 2))
        UIGraphicsBeginImageContextWithOptions(lbRect.size, false, 0)
        color.setFill()
        UIRectFill(lbRect)
        let lbImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return lbImage
        
    }
    
    func exportVideo() {
        
        //Create video composition
        let videoComposition = AVMutableVideoComposition()
        if let track = model.asset?.tracksWithMediaType(AVMediaTypeVideo)[0] {
            videoComposition.frameDuration = CMTimeMake(1, 60)
            videoComposition.renderSize = model.getFrame().size
            
            videoComposition.renderSize.height -= videoComposition.renderSize.height % 2
            videoComposition.renderSize.width -= videoComposition.renderSize.width % 2

            //to prevent green lines on bottom and side, rendersize must be divisible by 2
            
            let preferredTransform = track.preferredTransform
            
            let orientation = findOrientation(preferredTransform)
            
            //Transforms are based on orientation
            
            let finalTransform = createTransform(orientation, preferredTransform: preferredTransform)
            
            let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
            
            transformer.setTransform(finalTransform, atTime: kCMTimeZero)
            
            let instructions = AVMutableVideoCompositionInstruction()
            instructions.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30))
            
            instructions.layerInstructions = [transformer]
            videoComposition.instructions = [instructions]
            
            if lbRatio == "1:1" || lbRatio == "16:9" {
                
                let frameHeight = lbRatio == "1:1" ? videoComposition.renderSize.width : videoComposition.renderSize.width / (16.0 / 9.0)
                
                let frameColor: UIColor = lbColor == "white" ? UIColor.whiteColor() : UIColor.blackColor()
                
                let lbHeight = (frameHeight - videoComposition.renderSize.height) / 2
                
                let lbRect = CGRect(origin: CGPointMake(0,0), size: CGSizeMake(videoComposition.renderSize.width, lbHeight))
                
                UIGraphicsBeginImageContextWithOptions(lbRect.size, false, 0)
                frameColor.setFill()
                UIRectFill(lbRect)
                let lbImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                let lbLayerBottom = CALayer()
                lbLayerBottom.contents = lbImage.CGImage
                lbLayerBottom.frame = CGRectMake(0, 0, lbImage.size.width, lbHeight)
                lbLayerBottom.masksToBounds = false
                
                let lbLayerTop = CALayer()
                lbLayerTop.contents = lbImage.CGImage
                lbLayerTop.frame = CGRectMake(0, (lbHeight + videoComposition.renderSize.height), lbImage.size.width, lbHeight)
                lbLayerTop.masksToBounds = false
                
                let videoLayer = CALayer()
                videoLayer.frame = CGRectMake(0, -lbHeight, videoComposition.renderSize.width, frameHeight)
                
                videoComposition.renderSize.height = frameHeight
        
                let parentLayer = CALayer()
                parentLayer.addSublayer(videoLayer)
                parentLayer.addSublayer(lbLayerBottom)
                parentLayer.addSublayer(lbLayerTop)
                
                videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, inLayer: parentLayer)
        
            }
            
            print("renderSize : \(videoComposition.renderSize)")

            let exportURL = createExportURL()
            
            //TODO: Should save as .mp4 as well?
            //exportURL.URLByAppendingPathExtension(UTTypeCopyPreferredTagWithClass(AVFileTypeQuickTimeMovie, kUTTagClassFilenameExtension)!.takeUnretainedValue() as String)
            
            let exporter: AVAssetExportSession = AVAssetExportSession(asset: model.asset!, presetName: AVAssetExportPresetHighestQuality)!
            exporter.videoComposition = videoComposition
            exporter.outputFileType = AVFileTypeQuickTimeMovie
            exporter.outputURL = exportURL
            exporter.shouldOptimizeForNetworkUse = true
            activityIndicator.startAnimating()
            exporter.exportAsynchronouslyWithCompletionHandler {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.activityIndicator.stopAnimating()
                })
                if exporter.status == AVAssetExportSessionStatus.Completed {
                    let assetsLibrary = ALAssetsLibrary()
                    if assetsLibrary.videoAtPathIsCompatibleWithSavedPhotosAlbum(exporter.outputURL) {
                        UISaveVideoAtPathToSavedPhotosAlbum(exporter.outputURL!.path!, self, "image:didFinishSavingWithError:contextInfo:", nil)
                        //print("Video Saved to Camera Roll")
                    }
                } else {
                    self.errLabel.hidden = false
                }
            }
            
        } else {
            print("Error: Video")
        }
    }
    
    func createExportURL() -> NSURL {
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        
        // Create save path based on date
        let docPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        let dateString = dateFormatter.stringFromDate(NSDate())
        let exportPath = docPath.stringByAppendingFormat("/\(dateString).mov")
        
        let exportURL = NSURL.fileURLWithPath(exportPath)
        
        return exportURL
        
    }
    
    func createTransform(orientation: String, preferredTransform: CGAffineTransform) -> CGAffineTransform {
        
        var tx: CGFloat = 0.0
        var ty: CGFloat = 0.0
        
        switch orientation {
        case "up": //print("switchUP")
        tx = -scrollView.contentOffset.y * model.scale
        ty = scrollView.contentOffset.x * model.scale
        case "left": //print("switchLEFT")
        tx = -scrollView.contentOffset.x * model.scale
        ty = -scrollView.contentOffset.y * model.scale
        case "right": //print("switchRight")
        tx = scrollView.contentOffset.x * model.scale
        ty = scrollView.contentOffset.y * model.scale
        case "down": //print("switchDown")
        tx = scrollView.contentOffset.y * model.scale
        ty = -scrollView.contentOffset.x * model.scale
        default: print("default")
        }
        
        let t1 = CGAffineTransformTranslate(preferredTransform, tx, ty)
        
        return t1
        
    }
    
    func findOrientation(preferredTransform: CGAffineTransform) -> String {
        
        var orientation: String = "up"
        
        //          values found @ http://stackoverflow.com/questions/4627940/how-to-detect-iphone-sdk-if-a-video-file-was-recorded-in-portrait-orientation
        
        if (preferredTransform.a == 1 && preferredTransform.d == 1 && preferredTransform.b == 0 && preferredTransform.c == 0) {
            orientation = "left"
        } else if (preferredTransform.a == -1 && preferredTransform.d == -1 && preferredTransform.b == 0 && preferredTransform.c == 0) {
            orientation = "right"
        } else if (preferredTransform.a == 0 && preferredTransform.d == 0 && preferredTransform.b == -1 && preferredTransform.c == 1) {
            orientation = "down"
        }
        
        return orientation
        
    }
    
    func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafePointer<Void>) {
        if error == nil {
            let ac = UIAlertController(title: "Saved!", message: "Export has been saved to your photos.", preferredStyle: .Alert)
            ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            presentViewController(ac, animated: true, completion: nil)
        } else {
            let ac = UIAlertController(title: "Save error", message: error?.localizedDescription, preferredStyle: .Alert)
            ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            presentViewController(ac, animated: true, completion: nil)
        }
    }
    
    //Adjusts orientation of UIImage based on camera orientation
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
        return NSAttributedString(string: pickerTitleArr[row], attributes: [NSForegroundColorAttributeName:UIColor.lightGrayColor()])
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        UIView.animateWithDuration(0.5) { () -> Void in
            self.scrollView.frame.size = self.getCropSize()
            self.scrollView.frame.origin.y = self.getCropOrigin()
            if let zoom = self.model.pickedImage?.size {
                self.setZoomScale(zoom)
            }
            if self.scrollView.contentSize.height > self.scrollView.bounds.size.height || self.scrollView.contentSize.width > self.scrollView.bounds.size.width {
                self.centerImageInScrollView()
            }
        }
        
    }
    
    func centerImageInScrollView() {
        if scrollView.contentSize.width > scrollView.bounds.width {
            scrollView.contentOffset.x = ((scrollView.contentSize.width - scrollView.bounds.width) / 2)
        }
        if scrollView.contentSize.height > scrollView.bounds.height {
            scrollView.contentOffset.y = ((scrollView.contentSize.height - scrollView.bounds.height) / 2)
        }
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
        }
        
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        model.mediaType = info[UIImagePickerControllerMediaType] as? String
        self.dismissViewControllerAnimated(true, completion: nil)
        for view in scrollView.subviews {
            view.removeFromSuperview()
        }
        if model.mediaType == kUTTypeImage as String {
            model.pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        } else if model.mediaType == kUTTypeMovie as String {
            let videoClipURL = info[UIImagePickerControllerMediaURL] as! NSURL
            model.asset = AVAsset(URL: videoClipURL)
            if let snapshot = vidSnapshot(videoClipURL) {
                model.pickedImage = snapshot
            }
        } else {
            print("Unrecognized Media Type")
            return
        }
        imageView = UIImageView(image: model.pickedImage)
        scrollView.addSubview(imageView)
        setZoomScale(imageView.bounds.size)
        centerImageInScrollView()
        saveButton.enabled = true
    }
    
    func vidSnapshot(vidURL: NSURL) -> UIImage? {
        let asset = AVURLAsset(URL: vidURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let timestamp = CMTime(seconds: 1, preferredTimescale: 60)
        
        do {
            let imageRef = try generator.copyCGImageAtTime(timestamp, actualTime: nil)
            return UIImage(CGImage: imageRef)
        }
        catch let error as NSError {
            print("Image generatior failed with error: \(error)")
            return nil
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    //MARK: SCROLLVIEW
    
    //Adjusts the size of the scrollView to the appropriate aspect ratio chosen in the pickerController
    func getCropSize() -> CGSize {
        let ratio = model.ratiosArr[pickerView.selectedRowInComponent(0)]
        let cropRectSize = CGSizeMake(view.bounds.width, view.bounds.width / CGFloat(ratio))
        return cropRectSize
    }
    
    func getCropOrigin() -> CGFloat {
            let position = (view.bounds.height / 3) - (scrollView.frame.height / 2)
            return position
    }
    
    let lbRatios = [1, 16/9]
    let lbColors = ["black", "white"]
    
    var lbRatio = "none"
    var lbColor = "white"
    
    
    @IBAction func lbRatioChanged(sender: UISegmentedControl) {
        let segIdx = sender.selectedSegmentIndex
        switch segIdx {
        case 0: lbRatio = "none"
        case 1: lbRatio = "1:1"
        case 2: lbRatio = "16:9"
        default: lbRatio = "none"
        }
    }
    
    @IBAction func lbColorChanged(sender: AnyObject) {
        let segIdx = sender.selectedSegmentIndex
        switch segIdx {
        case 0: lbColor = "white"
        case 1: lbColor = "black"
        default: lbColor = "white"
        }
    }

    func setZoomScale(size: CGSize) {
        scrollView.contentSize = size
        let widthScale = scrollView.bounds.size.width / size.width
        let heightScale = scrollView.bounds.size.height / size.height
        let maxScale = max(widthScale, heightScale)
        scrollView.minimumZoomScale = maxScale
        scrollView.maximumZoomScale = 1.33
        scrollView.zoomScale = maxScale
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    //MARK: LIFECYCLE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.selectRow(3, inComponent: 0, animated: false)
        scrollView = UIScrollView(frame: CGRect(origin: view.bounds.origin, size: getCropSize()))
        scrollView.delegate = self
        imageView = UIImageView(image: model.pickedImage)
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        setZoomScale(imageView.bounds.size)

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        scrollView.frame.origin.y = getCropOrigin()
        scrollView.layer.borderWidth = 1
        scrollView.layer.borderColor = UIColor.whiteColor().CGColor

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

