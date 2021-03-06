//
//  FZImageCropView.swift
//  Fusuma
//
//  Created by Yuta Akizuki on 2015/11/16.
//  Copyright © 2015年 ytakzk. All rights reserved.
//

import UIKit

final class FSImageCropView: UIScrollView, UIScrollViewDelegate {
    
    var imageView = UIImageView()
    
    var imageSize: CGSize?
    
    var image: UIImage! = nil {
        
        didSet {
            
            if image != nil {
                
                if !imageView.isDescendant(of: self) {
                    self.imageView.alpha = 1.0
                    self.addSubview(imageView)
                }
                
            } else {
                
                imageView.image = nil
                return
            }

            if !FusumaShared.shared.fusumaCropImage {
                // Disable scroll view and set image to fit in view
                imageView.frame = self.frame
                imageView.contentMode = .scaleAspectFit
                self.isUserInteractionEnabled = false

                imageView.image = image
                return
            }

            let imageSize = self.imageSize ?? image.size

            let ratioW = frame.width / imageSize.width // 400 / 1000 => 0.4
            let ratioH = frame.height / imageSize.height // 300 / 500 => 0.6

            if ratioH > ratioW {
                imageView.frame = CGRect(
                    origin: CGPoint.zero,
                    size: CGSize(width: imageSize.width  * ratioH, height: frame.height)
                )
            } else {
                imageView.frame = CGRect(
                    origin: CGPoint.zero,
                    size: CGSize(width: frame.width, height: imageSize.height  * ratioW)
                )
            }

            self.contentOffset = CGPoint(
                x: imageView.center.x - self.center.x,
                y: imageView.center.y - self.center.y
            )

            self.contentSize = CGSize(width: imageView.frame.width + 1, height: imageView.frame.height + 1)
            
            imageView.image = image
            
            self.zoomScale = 1.0
            
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)!
        
        self.backgroundColor = FusumaShared.shared.fusumaBackgroundColor
        self.frame.size      = CGSize.zero
        self.clipsToBounds   = true
        self.imageView.alpha = 0.0
        
        imageView.frame = CGRect(origin: CGPoint.zero, size: CGSize.zero)
        
        self.maximumZoomScale = 2.0
        self.minimumZoomScale = 0.8
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator   = false
        self.bouncesZoom = true
        self.bounces = true
        self.scrollsToTop = false
        
        self.delegate = self
    }
    
    
    func changeScrollable(_ isScrollable: Bool) {
        
        self.isScrollEnabled = isScrollable
    }
    
    // MARK: UIScrollViewDelegate Protocol
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        
        return imageView

    }
    
    var previousImageViewFrame: CGRect?
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        
        let boundsSize = scrollView.bounds.size
        var contentsFrame = imageView.frame
        previousImageViewFrame = imageView.frame
        
        if contentsFrame.size.width < boundsSize.width {
            
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
            
        } else {
            contentsFrame.origin.x = 0.0
        }
        
        if contentsFrame.size.height < boundsSize.height {
            
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
        } else {
            
            contentsFrame.origin.y = 0.0
        }
        
        imageView.frame = contentsFrame
        
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        
        guard let previousFrame = previousImageViewFrame else {
            print("could not retrive previous state for imageview")
            return
        }
        
        if imageView.frame.width>imageView.frame.height {
            //landscape
            if(imageView.frame.height<scrollView.bounds.height){
                UIView.animate(withDuration: 0.3,
                               delay: 0.0,
                               options: UIViewAnimationOptions.curveEaseOut,
                               animations: {
                                self.contentSize = CGSize(width: previousFrame.width + 1, height: previousFrame.height + 1)
                                scrollView.setZoomScale(1.0, animated: false)
                                self.layoutIfNeeded()
                                
                }, completion: nil)
                
            }
        } else if(imageView.frame.width<scrollView.bounds.height){
            //portrait
            if(imageView.frame.width<scrollView.bounds.width){
                UIView.animate(withDuration: 0.3,
                               delay: 0.0,
                               options: UIViewAnimationOptions.curveEaseOut,
                               animations: {
                                self.contentSize = CGSize(width: previousFrame.width + 1, height: previousFrame.height + 1)
                                scrollView.setZoomScale(1.0, animated: false)
                                self.layoutIfNeeded()
                                
                }, completion: nil)
            }
        } else {
            self.contentSize = CGSize(width: imageView.frame.width + 1, height: imageView.frame.height + 1)
        }
        
    }
    
}
