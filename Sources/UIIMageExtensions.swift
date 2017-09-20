//
//  UIIMageExtensions.swift
//  FusumaExample
//
//  Created by Jacob Bachmann on 20/09/2017.
//  Copyright © 2017 ytakzk. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    var isPortrait:  Bool    { return size.height > size.width }
    var isLandscape: Bool    { return size.width > size.height }
    var breadth:     CGFloat { return min(size.width, size.height) }
    var breadthSize: CGSize  { return CGSize(width: breadth, height: breadth) }
    var breadthRect: CGRect  { return CGRect(origin: .zero, size: breadthSize) }
    var circleMasked: UIImage {
        UIGraphicsBeginImageContextWithOptions(breadthSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        guard let cgImage = cgImage?.cropping(to: CGRect(origin: CGPoint(x: isLandscape ? floor((size.width - size.height) / 2) : 0, y: isPortrait  ? floor((size.height - size.width) / 2) : 0), size: breadthSize)) else { return UIImage() }
        UIBezierPath(ovalIn: breadthRect).addClip()
        UIImage(cgImage: cgImage, scale: 1, orientation: imageOrientation).draw(in: breadthRect)
        guard let finalImage = UIGraphicsGetImageFromCurrentImageContext() else {
            print("Unable to  generate image in UIGraphicsGetImageFromCurrentImageContext")
            return UIImage()
        }
        return finalImage
    }
}
