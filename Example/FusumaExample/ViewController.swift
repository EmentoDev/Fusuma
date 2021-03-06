//
//  ViewController.swift
//  Fusuma
//
//  Created by ytakzk on 01/31/2016.
//  Copyright (c) 2016 ytakzk. All rights reserved.
//

import UIKit

class ViewController: UIViewController, FusumaDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var showButton: UIButton!
    
    @IBOutlet weak var fileUrlLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        showButton.layer.cornerRadius = 2.0
        self.fileUrlLabel.text = ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func showButtonPressed(_ sender: AnyObject) {
        
        let fusuma = FusumaViewController()
        
        fusuma.delegate = self
        fusuma.cropHeightRatio = 1.0
        fusuma.allowMultipleSelection = false
        fusuma.fusumaCropImage = true
        fusuma.fusumaCircularImage = true
        fusuma.availableModes = [.camera, .library]
        fusuma.shouldDisplayTopBar = true
        fusuma.topBarTintColor = UIColor(red: 44.0/255.0, green: 44.0/255.0, blue: 44.0/255.0, alpha: 1.0)
        fusuma.fusumaCloseTitle = "Annuller"
        fusuma.fusumaShouldAddSpaceForStatusBar = true
        fusuma.fusumaTabFont =  UIFont(name: "Farah", size: 13)
        fusuma.fusumaBaseTintColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.5)
        fusuma.fusumaTintColor = UIColor(red: 255, green: 255, blue: 255, alpha: 1)
        fusuma.fusumaBackgroundColor = UIColor.black
        fusuma.fusumaSavesImage = false
        fusuma.fusumaCameraDirection = .front
        
        self.present(fusuma, animated: true, completion: nil)
    }
    
    // MARK: FusumaDelegate Protocol
    func fusumaImageSelected(_ image: UIImage, source: FusumaMode?) {
        
        imageView.image = image
        
        guard let src = source else {
            return
        }
        
        switch src {
            
        case .camera:
            
            print("Image captured from Camera")
        
        case .library:
            
            print("Image selected from Camera Roll")
        
        default:
        
            print("Image selected")
        }
    }
    
    func fusumaMultipleImageSelected(_ images: [UIImage], source: FusumaMode) {
        
        print("Number of selection images: \(images.count)")

        var count: Double = 0
        
        for image in images {
        
            DispatchQueue.main.asyncAfter(deadline: .now() + (3.0 * count)) {
            
                self.imageView.image = image
                print("w: \(image.size.width) - h: \(image.size.height)")
            }
            count += 1
        }
    }

    func fusumaImageSelected(_ image: UIImage, source: FusumaMode, metaData: ImageMetadata?) {
        
        imageView.image = image
        
        guard let meta = metaData else {
            return
        }
        
        print("Image mediatype: \(meta.mediaType)")
        print("Source image size: \(meta.pixelWidth)x\(meta.pixelHeight)")
        print("Creation date: \(String(describing: meta.creationDate))")
        print("Modification date: \(String(describing: meta.modificationDate))")
        print("Video duration: \(meta.duration)")
        print("Is favourite: \(meta.isFavourite)")
        print("Is hidden: \(meta.isHidden)")
        print("Location: \(String(describing: meta.location))")
        
    }

    func fusumaVideoCompleted(withFileURL fileURL: URL) {
        
        print("video completed and output to file: \(fileURL)")
        self.fileUrlLabel.text = "file output to: \(fileURL.absoluteString)"
    }
    
    func fusumaDismissedWithImage(_ image: UIImage, source: FusumaMode) {
        
        switch source {
        
        case .camera:
        
            print("Called just after dismissed FusumaViewController using Camera")
        
        case .library:
        
            print("Called just after dismissed FusumaViewController using Camera Roll")
        
        default:
        
            print("Called just after dismissed FusumaViewController")
        }
    }
    
    func fusumaCameraUnauthorized(_ fusumaViewController: FusumaViewController) {
        print("Camera unauthorized")
        
        let alert = UIAlertController(title: "Access Requested",
                                      message: "The app cant access your camera, please go to setting to enable it.",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { (action) -> Void in
            
            if let url = URL(string:UIApplicationOpenSettingsURLString) {
                
                UIApplication.shared.openURL(url)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            
        })
        
        fusumaViewController.present(alert, animated: true, completion: nil)
    }
    
    func fusumaCameraRollUnauthorized(_ fusumaViewController: FusumaViewController)  {
        
        print("Camera roll unauthorized")
        
        let alert = UIAlertController(title: "Access Requested",
                                      message: "Saving image needs to access your photo album",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { (action) -> Void in
            
            if let url = URL(string:UIApplicationOpenSettingsURLString) {
                
                UIApplication.shared.openURL(url)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            
        })

        fusumaViewController.present(alert, animated: true, completion: nil)
    }
    
    func fusumaClosed() {
        
        print("Called when the FusumaViewController disappeared")
    }
    
    func fusumaWillClosed() {
        
        print("Called when the close button is pressed")
    }

}

