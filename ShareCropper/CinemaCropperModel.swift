//
//  CinemaCropperModel.swift
//  CinemaCropper
//
//  Created by Adam Wayland on 1/11/16.
//  Copyright © 2016 Adam Wayland. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class CinemaCropperModel {

    // Aspect ratio constants
    private let academy = 1.33
    private let europeanWS = 1.66
    private let sixteenNine = 1.77
    private let americanWS = 1.85
    private let seventyMM = 2.2
    private let anamorphic = 2.35 //also 2.39
    private let cinerama = 2.77

    // Array of aspect ratios
    let ratiosArr: [Double]
    
    // CGRect containing current crop values
    private var cropRect: CGRect
    
    // Image or Video snapshot being edited
    var pickedImage: UIImage?
    
    // The type of media being edited
    var mediaType: String?
    
    // Video asset imported from camera roll
    var asset: AVAsset?
    
    // Video scale level
    var scale: CGFloat!
    
    init() {
        
        ratiosArr = [ academy, europeanWS, sixteenNine, americanWS, seventyMM, anamorphic, cinerama ]
        if let image = UIImage(contentsOfFile: "cinema cropper.png") {
            pickedImage = image
        }
        cropRect = CGRect(origin: CGPointZero, size: CGSizeZero)
        
    }
    
    func setFrame(origin origin: CGPoint, size: CGSize, zoom: CGFloat) {
        
        cropRect = CGRect(origin: origin, size: size)
        
        scale = 1.0 / zoom
        
        cropRect.origin.x *= scale
        cropRect.origin.y *= scale
        cropRect.size.width *= scale
        cropRect.size.height *= scale
        
    }
    
    func getFrame() -> CGRect {
        return cropRect
    }
    
}

