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
import AVFoundation
import CoreMedia
import AssetsLibrary

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIScrollViewDelegate {
    
    //MARK: Constants and Variables
    
    // Aspect ratio constants
    let academy = 1.33
    let europeanWS = 1.66
    let sixteenNine = 1.77
    let americanWS = 1.85
    let seventyMM = 2.2
    let anamorphic = 2.35 //also 2.39
    let cinerama = 2.77
    
    // Array of aspect ratios
    var ratiosArr: [Double] = []
    
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
    var avPlayer: AVPlayer!
    var mediaType: String!
    var pickedImage: UIImage = UIImage(named: "cinema cropper.png")!
    var asset: AVAsset!
    
    //MARK: Outlets and Actions

    @IBOutlet weak var pickerView: UIPickerView!
    
    @IBOutlet weak var saveLabel: UILabel!
    
    //MARK: Save
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBAction func savePressed(sender: AnyObject) {
        
        //creates a cropRect based on size of scrollView and scales according to zoom
        var cropRect = CGRect()
        cropRect.origin = scrollView.contentOffset
        cropRect.size = scrollView.bounds.size
        
        let scale = 1.0 / scrollView.zoomScale
        
        cropRect.origin.x *= scale
        cropRect.origin.y *= scale
        cropRect.size.width *= scale
        cropRect.size.height *= scale
        
//      PHOTO
        if mediaType == kUTTypeImage as String {
            
            let orientedImage = fixOrientation(pickedImage)
            
            if let imageRef = CGImageCreateWithImageInRect(orientedImage.CGImage, cropRect) {
                let imageToSave = UIImage(CGImage: imageRef, scale: 1.0, orientation: orientedImage.imageOrientation)
                UIImageWriteToSavedPhotosAlbum(imageToSave, self, "image:didFinishSavingWithError:contextInfo:", nil)
            }
            
//      VIDEO
        } else if mediaType == kUTTypeMovie as String {
            
            let videoComposition = AVMutableVideoComposition()
            let track = asset.tracksWithMediaType(AVMediaTypeVideo)[0]
            videoComposition.frameDuration = CMTimeMake(1, 60)
            videoComposition.renderSize = cropRect.size
            
            //to prevent green lines on bottom and side, rendersize must be divisible by 2
            videoComposition.renderSize.height -= videoComposition.renderSize.height % 2
            videoComposition.renderSize.width -= videoComposition.renderSize.width % 2

            let preferredTransform = track.preferredTransform
            
            var orientation: String = "up"
            
//          values found @ http://stackoverflow.com/questions/4627940/how-to-detect-iphone-sdk-if-a-video-file-was-recorded-in-portrait-orientation
         
            if (preferredTransform.a == 1 && preferredTransform.d == 1 && preferredTransform.b == 0 && preferredTransform.c == 0) {
                orientation = "left"
            } else if (preferredTransform.a == -1 && preferredTransform.d == -1 && preferredTransform.b == 0 && preferredTransform.c == 0) {
                orientation = "right"
            } else if (preferredTransform.a == 0 && preferredTransform.d == 0 && preferredTransform.b == -1 && preferredTransform.c == 1) {
                orientation = "down"
            }
            
            //Transforms are based on orientation
            var tx: CGFloat = 0.0
            var ty: CGFloat = 0.0
            
            switch orientation {
                case "up": print("switchUP")
                    tx = -scrollView.contentOffset.y * scale
                case "left": print("switchLEFT")
                    ty = -scrollView.contentOffset.y * scale
                case "right": print("switchRight")
                    ty = scrollView.contentOffset.y * scale
                case "down": print("switchDown")
                    tx = scrollView.contentOffset.y * scale
                default: print("default")
            }

            let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: track)

            let t1 = CGAffineTransformTranslate(preferredTransform, tx, ty)

            let finalTransform = t1

            transformer.setTransform(finalTransform, atTime: kCMTimeZero)
            
            let instructions = AVMutableVideoCompositionInstruction()
            instructions.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30))
            
            instructions.layerInstructions = [transformer]
            videoComposition.instructions = [instructions]
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
            dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
    
            // Create save path based on date
            let docPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
            let dateString = dateFormatter.stringFromDate(NSDate())
            let exportPath = docPath.stringByAppendingFormat("/\(dateString).mov")
            
            let exportURL = NSURL.fileURLWithPath(exportPath)
            
            //TODO: Should save as .mp4 as well?
            //exportURL.URLByAppendingPathExtension(UTTypeCopyPreferredTagWithClass(AVFileTypeQuickTimeMovie, kUTTagClassFilenameExtension)!.takeUnretainedValue() as String)

            let exporter: AVAssetExportSession = AVAssetExportSession(asset: asset!, presetName: AVAssetExportPresetHighestQuality)!
            exporter.videoComposition = videoComposition
            exporter.outputFileType = AVFileTypeQuickTimeMovie
            exporter.outputURL = exportURL
            exporter.shouldOptimizeForNetworkUse = true
            
            exporter.exportAsynchronouslyWithCompletionHandler {
                if exporter.status == AVAssetExportSessionStatus.Completed {
                    let assetsLibrary = ALAssetsLibrary()
                    if assetsLibrary.videoAtPathIsCompatibleWithSavedPhotosAlbum(exporter.outputURL) {
                        UISaveVideoAtPathToSavedPhotosAlbum(exporter.outputURL!.path!, self, "image:didFinishSavingWithError:contextInfo:", nil)
                        print("Video Saved to Camera Roll")
                    } else {
                        print("Video not compaltible with Camera Roll")
                    }
                }
            }
        } else {
            print("Error: Image")
        }
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
        return NSAttributedString(string: pickerTitleArr[row], attributes: [NSForegroundColorAttributeName:UIColor.whiteColor()])
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        scrollView.frame.size = getCropSize()
        scrollView.frame.origin.y = getCropOrigin()
        setZoomScale(pickedImage.size)
        if scrollView.contentSize.height > scrollView.bounds.size.height || scrollView.contentSize.width > scrollView.bounds.size.width {
            centerImageInScrollView()
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
        mediaType = info[UIImagePickerControllerMediaType] as! String
        self.dismissViewControllerAnimated(true, completion: nil)
        for view in scrollView.subviews {
            view.removeFromSuperview()
        }
        if mediaType == kUTTypeImage as String {
            pickedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        } else if mediaType == kUTTypeMovie as String {
            let videoClipURL = info[UIImagePickerControllerMediaURL] as! NSURL
            asset = AVAsset(URL: videoClipURL)
            if let snapshot = vidSnapshot(videoClipURL) {
                pickedImage = snapshot
            }
        } else {
            print("Unrecognized Media Type")
            return
        }
        imageView = UIImageView(image: pickedImage)
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
        let ratio = ratiosArr[pickerView.selectedRowInComponent(0)]
        let cropRectSize = CGSizeMake(view.bounds.width, view.bounds.width / CGFloat(ratio))
        return cropRectSize
    }
    
    func getCropOrigin() -> CGFloat {
        if let parent = self.parentViewController as! UINavigationController! {
            let navBarHeight = parent.navigationBar.frame.height
            let position = ((view.bounds.height - pickerView.frame.height) / 2) - (scrollView.frame.height / 2) + navBarHeight
            return position
        } else {
            return ((view.bounds.height - pickerView.frame.height) / 2) - (scrollView.frame.height / 2)
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

