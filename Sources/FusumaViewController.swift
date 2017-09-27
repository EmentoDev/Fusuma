//
//  FusumaViewController.swift
//  Fusuma
//
//  Created by Yuta Akizuki on 2015/11/14.
//  Copyright © 2015年 ytakzk. All rights reserved.
//

import UIKit
import Photos

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

public protocol FusumaDelegate: class {
    
    func fusumaImageSelected(_ image: UIImage, source: FusumaMode)
    func fusumaMultipleImageSelected(_ images: [UIImage], source: FusumaMode)
    func fusumaVideoCompleted(withFileURL fileURL: URL)
    
    // optional
    func fusumaImageSelected(_ image: UIImage, source: FusumaMode, metaData: ImageMetadata)
    func fusumaDismissedWithImage(_ image: UIImage, source: FusumaMode)
    func fusumaClosed()
    func fusumaWillClosed()
    func fusumaCameraRollUnauthorized(_ fusumaViewController: FusumaViewController)
    func fusumaCameraUnauthorized(_ fusumaViewController: FusumaViewController)
}

public extension FusumaDelegate {
    
    func fusumaImageSelected(_ image: UIImage, source: FusumaMode, metaData: ImageMetadata) {}
    func fusumaDismissedWithImage(_ image: UIImage, source: FusumaMode) {}
    func fusumaClosed() {}
    func fusumaWillClosed() {}
    func fusumaCameraRollUnauthorized(_ fusumaViewController: FusumaViewController) {}
    func fusumaCameraUnauthorized(_ fusumaViewController: FusumaViewController) {}
}

@objc public enum FusumaMode: Int {
    
    case camera
    case library
    case video
    
    static var all: [FusumaMode] {
        
        return [.camera, .library, .video]
    }
}

public struct ImageMetadata {
    public let mediaType: PHAssetMediaType
    public let pixelWidth: Int
    public let pixelHeight: Int
    public let creationDate: Date?
    public let modificationDate: Date?
    public let location: CLLocation?
    public let duration: TimeInterval
    public let isFavourite: Bool
    public let isHidden: Bool
    public let asset: PHAsset
}

// MARK: - Singleton

final class FusumaShared {
    
    // Can't init is singleton
    private init() { }
    
    // MARK: Shared Instance
    
    static let shared = FusumaShared()
    
    // MARK: Local Variable
    public var fusumaCropImage: Bool  = true
    public var fusumaBackgroundColor = UIColor.hex("#FCFCFC", alpha: 1.0)
    public var cropHeightRatio: CGFloat = 1
    public var allowMultipleSelection: Bool = false
    public var shouldDisplayTopBar = false
    public var topBarTintColor = UIColor.white
    public var topBarCloseButtonFont = UIFont(name: "Farah", size: 13)
    public var fusumaBaseTintColor   = UIColor.hex("#c9c7c8", alpha: 1.0)
    public var fusumaTintColor       = UIColor.hex("#424141", alpha: 1.0)
    public var fusumaTriggerTintColor : UIColor?
    
    public var fusumaCheckImage: UIImage?
    public var fusumaCloseImage: UIImage?
    public var fusumaFlashOnImage: UIImage?
    public var fusumaFlashOffImage: UIImage?
    public var fusumaFlipImage: UIImage?
    public var fusumaShotImage: UIImage?
    
    public var fusumaVideoStartImage: UIImage?
    public var fusumaVideoStopImage: UIImage?
    
    public var fusumaSavesImage: Bool = false
    public var fusumaCircularImage: Bool  = false
    public var fusumaShouldAddSpaceForStatusBar = false
    
    public var fusumaCameraRollTitle = "Library"
    public var fusumaCameraTitle     = "Photo"
    public var fusumaVideoTitle      = "Video"
    public var fusumaCloseTitle      = "Close"
    public var fusaumaTitle         = ""
    public var fusumaUseCameraRollImageTitle = "USE IMAGE"
    public var fusumaTitleFont       = UIFont(name: "AvenirNext-DemiBold", size: 15)
    public var fusumaTabFont         = UIFont(name: "AvenirNext-DemiBold", size: 15)
    public var fusumaCameraDirection = AVCaptureDevicePosition.back
    public var fusumaStatusBarHidden = false
}


@objc public class FusumaViewController: UIViewController {

    public var fusumaCropImage = FusumaShared.shared.fusumaCropImage { willSet { FusumaShared.shared.fusumaCropImage = newValue } }
    public var fusumaBackgroundColor = FusumaShared.shared.fusumaBackgroundColor { willSet { FusumaShared.shared.fusumaBackgroundColor = newValue } }
    public var cropHeightRatio = FusumaShared.shared.cropHeightRatio { willSet { FusumaShared.shared.cropHeightRatio = newValue } }
    public var allowMultipleSelection = FusumaShared.shared.allowMultipleSelection { willSet { FusumaShared.shared.allowMultipleSelection = newValue } }
    public var shouldDisplayTopBar = FusumaShared.shared.shouldDisplayTopBar { willSet { FusumaShared.shared.shouldDisplayTopBar = newValue } }
    public var topBarTintColor = FusumaShared.shared.topBarTintColor { willSet { FusumaShared.shared.topBarTintColor = newValue } }
    public var topBarCloseButtonFont = FusumaShared.shared.topBarCloseButtonFont { willSet { FusumaShared.shared.topBarCloseButtonFont = newValue } }
    public var fusumaBaseTintColor   = FusumaShared.shared.fusumaBaseTintColor { willSet { FusumaShared.shared.fusumaBaseTintColor = newValue } }
    public var fusumaTintColor       = FusumaShared.shared.fusumaTintColor { willSet { FusumaShared.shared.fusumaTintColor = newValue } }
    public var fusumaTriggerTintColor = FusumaShared.shared.fusumaTriggerTintColor { willSet { FusumaShared.shared.fusumaTriggerTintColor = newValue } }
    
    public var fusumaCheckImage = FusumaShared.shared.fusumaCheckImage { willSet { FusumaShared.shared.fusumaCheckImage = newValue } }
    public var fusumaCloseImage = FusumaShared.shared.fusumaCloseImage { willSet { FusumaShared.shared.fusumaCloseImage = newValue } }
    public var fusumaFlashOnImage = FusumaShared.shared.fusumaFlashOnImage { willSet { FusumaShared.shared.fusumaFlashOnImage = newValue } }
    public var fusumaFlashOffImage = FusumaShared.shared.fusumaFlashOffImage { willSet { FusumaShared.shared.fusumaFlashOffImage = newValue } }
    public var fusumaFlipImage = FusumaShared.shared.fusumaFlipImage { willSet { FusumaShared.shared.fusumaFlipImage = newValue } }
    public var fusumaShotImage = FusumaShared.shared.fusumaShotImage { willSet { FusumaShared.shared.fusumaShotImage = newValue } }
    
    public var fusumaVideoStartImage = FusumaShared.shared.fusumaVideoStartImage { willSet { FusumaShared.shared.fusumaVideoStartImage = newValue } }
    public var fusumaVideoStopImage = FusumaShared.shared.fusumaVideoStopImage { willSet { FusumaShared.shared.fusumaVideoStopImage = newValue } }
    
    public var fusumaSavesImage = FusumaShared.shared.fusumaSavesImage { willSet { FusumaShared.shared.fusumaSavesImage = newValue } }
    public var fusumaCircularImage = FusumaShared.shared.fusumaCircularImage { willSet { FusumaShared.shared.fusumaCircularImage = newValue } }
    public var fusumaShouldAddSpaceForStatusBar = FusumaShared.shared.fusumaShouldAddSpaceForStatusBar { willSet { FusumaShared.shared.fusumaShouldAddSpaceForStatusBar = newValue } }
    
    public var fusumaCameraRollTitle = FusumaShared.shared.fusumaCameraRollTitle { willSet { FusumaShared.shared.fusumaCameraRollTitle = newValue } }
    public var fusumaCameraTitle     = FusumaShared.shared.fusumaCameraTitle { willSet { FusumaShared.shared.fusumaCameraTitle = newValue } }
    public var fusumaVideoTitle      = FusumaShared.shared.fusumaVideoTitle { willSet { FusumaShared.shared.fusumaVideoTitle = newValue } }
    public var fusumaCloseTitle      = FusumaShared.shared.fusumaCloseTitle { willSet { FusumaShared.shared.fusumaCloseTitle = newValue } }
    public var fusaumaTitle         = FusumaShared.shared.fusaumaTitle { willSet { FusumaShared.shared.fusaumaTitle = newValue } }
    public var fusumaUseCameraRollImageTitle = FusumaShared.shared.fusumaUseCameraRollImageTitle { willSet { FusumaShared.shared.fusumaUseCameraRollImageTitle = newValue } }
    public var fusumaTitleFont       = FusumaShared.shared.fusumaTitleFont { willSet { FusumaShared.shared.fusumaTitleFont = newValue } }
    public var fusumaTabFont         = FusumaShared.shared.fusumaTabFont { willSet { FusumaShared.shared.fusumaTabFont = newValue } }
    public var fusumaCameraDirection = FusumaShared.shared.fusumaCameraDirection { willSet { FusumaShared.shared.fusumaCameraDirection = newValue } }
    public var fusumaStatusBarHidden = FusumaShared.shared.fusumaStatusBarHidden { willSet { FusumaShared.shared.fusumaStatusBarHidden = newValue } }

    fileprivate var mode: FusumaMode = .library
    
    public var availableModes: [FusumaMode] = [.library, .camera]

    @IBOutlet weak var photoLibraryViewerContainer: UIView!
    @IBOutlet weak var cameraShotContainer: UIView!
    @IBOutlet weak var videoShotContainer: UIView!
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var topBarTitle: UILabel!
    @IBOutlet weak var topBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var topBarOffsetConstraint: NSLayoutConstraint!
    @IBOutlet weak var topBarCloseButton: UIButton!

    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var videoButton: UIButton!
    
    lazy var albumView  = FSAlbumView.instance()
    lazy var cameraView = FSCameraView.instance()
    lazy var videoView  = FSVideoCameraView.instance()

    fileprivate var hasGalleryPermission: Bool {
        
        return PHPhotoLibrary.authorizationStatus() == .authorized
    }
    
    public weak var delegate: FusumaDelegate? = nil
    
    override public func loadView() {
        
        if let view = UINib(nibName: "FusumaViewController", bundle: Bundle(for: self.classForCoder)).instantiate(withOwner: self, options: nil).first as? UIView {
            
            self.view = view
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
    
        self.view.backgroundColor = FusumaShared.shared.fusumaBackgroundColor
        
        cameraView.delegate = self
        albumView.delegate  = self
        videoView.delegate  = self
        
        libraryButton.setTitle(fusumaCameraRollTitle, for: .normal)
        cameraButton.setTitle(fusumaCameraTitle, for: .normal)
        videoButton.setTitle(fusumaVideoTitle, for: .normal)
        
        if(fusumaTabFont != nil) {
            libraryButton.titleLabel?.font = fusumaTabFont
            cameraButton.titleLabel?.font = fusumaTabFont
            videoButton.titleLabel?.font = fusumaTabFont
        }
        
        if(shouldDisplayTopBar){
            topBarHeightConstraint.constant = fusumaShouldAddSpaceForStatusBar ? 84 : 64
            if(fusumaShouldAddSpaceForStatusBar) { topBarOffsetConstraint.constant = 20 }
            topBarTitle.text = fusaumaTitle
            topBarView.backgroundColor = topBarTintColor
            topBarCloseButton.setTitle(fusumaCloseTitle, for: .normal)
            topBarCloseButton.setTitleColor(fusumaTintColor, for: .normal)
            topBarCloseButton.titleLabel?.font = topBarCloseButtonFont
        } else {
            topBarTitle.removeFromSuperview()
            topBarHeightConstraint.constant = 0
            topBarView.isHidden = true
        }

        albumView.allowMultipleSelection = allowMultipleSelection
        
        libraryButton.tintColor = fusumaTintColor
        cameraButton.tintColor  = fusumaTintColor
        videoButton.tintColor   = fusumaTintColor
        
        cameraView.circularImage = fusumaCircularImage
        cameraView.triggerTint =  UIColor.lightGray
        cameraView.flashTint = UIColor.white
        cameraView.flipTint = UIColor.white
        albumView.circularImage = fusumaCircularImage
        albumView.useButtonForPhotoRoll.setTitle(fusumaUseCameraRollImageTitle, for: .normal)

        photoLibraryViewerContainer.addSubview(albumView)
        cameraShotContainer.addSubview(cameraView)
        videoShotContainer.addSubview(videoView)
        
        if availableModes.count == 0 || availableModes.count >= 3 {
            
            fatalError("the number of items in the variable of availableModes is incorrect.")
        }
        
        if NSOrderedSet(array: availableModes).count != availableModes.count {
            
            fatalError("the variable of availableModes should have unique elements.")
        }
        
        changeMode(availableModes[0], isForced: true)
        
        var sortedButtons = [UIButton]()
        
        for (i, mode) in availableModes.enumerated() {
            
            let button = getTabButton(mode: mode)
            
            if i == 0 {
                
                self.view.addConstraint(NSLayoutConstraint(
                    item:       button,
                    attribute:  .leading,
                    relatedBy:  .equal,
                    toItem:     self.view,
                    attribute:  .leading,
                    multiplier: 1.0,
                    constant:   0.0
                ))
            
            } else {
                
                self.view.addConstraint(NSLayoutConstraint(
                    item:       button,
                    attribute:  .leading,
                    relatedBy:  .equal,
                    toItem:     sortedButtons[i - 1],
                    attribute:  .trailing,
                    multiplier: 1.0,
                    constant:   0.0
                ))
            }
            
            if i == sortedButtons.count - 1 {
                
                self.view.addConstraint(NSLayoutConstraint(
                    item:       button,
                    attribute:  .trailing,
                    relatedBy:  .equal,
                    toItem:     button,
                    attribute:  .trailing,
                    multiplier: 1.0,
                    constant:   0.0
                ))
                
            }

            self.view.addConstraint(NSLayoutConstraint(
                item: button,
                attribute: .width,
                relatedBy: .equal, toItem: nil,
                attribute: .width,
                multiplier: 1.0,
                constant: UIScreen.main.bounds.width / CGFloat(availableModes.count)
            ))
            
            sortedButtons.append(button)
        }
        
        for m in FusumaMode.all {
            
            if !availableModes.contains(m) {
                
                getTabButton(mode: m).removeFromSuperview()
            }
        }

        if availableModes.count == 1 {
            
            libraryButton.removeFromSuperview()
            cameraButton.removeFromSuperview()
            videoButton.removeFromSuperview()
            return
        }
        
        if !availableModes.contains(.camera) {
            
            return
        }
        
        if FusumaShared.shared.fusumaCropImage {
            
            let heightRatio = getCropHeightRatio()
            
            cameraView.croppedAspectRatioConstraint = NSLayoutConstraint(
                item: cameraView.previewViewContainer,
                attribute: NSLayoutAttribute.height,
                relatedBy: NSLayoutRelation.equal,
                toItem: cameraView.previewViewContainer,
                attribute: NSLayoutAttribute.width,
                multiplier: heightRatio,
                constant: 0)
            cameraView.fullAspectRatioConstraint.isActive     = false
            cameraView.croppedAspectRatioConstraint?.isActive = true
            
        } else {
            
            cameraView.fullAspectRatioConstraint.isActive     = true
            cameraView.croppedAspectRatioConstraint?.isActive = false
        }
        
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if availableModes.contains(.camera) {
            
            albumView.frame = CGRect(origin: CGPoint.zero, size: photoLibraryViewerContainer.frame.size)
            albumView.layoutIfNeeded()
            albumView.initialize()
        }
        
        if availableModes.contains(.camera) {
            
            cameraView.frame = CGRect(origin: CGPoint.zero, size: cameraShotContainer.frame.size)
            cameraView.layoutIfNeeded()
            cameraView.initialize()
        }
        
        if availableModes.contains(.video) {

            videoView.frame = CGRect(origin: CGPoint.zero, size: videoShotContainer.frame.size)
            videoView.layoutIfNeeded()
            videoView.initialize()
        }        
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        self.stopAll()
    }

    override public var prefersStatusBarHidden : Bool {
        
        return FusumaShared.shared.fusumaStatusBarHidden
    }
    
    override public var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func libraryButtonPressed(_ sender: UIButton) {
        
        changeMode(FusumaMode.library)
    }
    
    @IBAction func photoButtonPressed(_ sender: UIButton) {
    
        changeMode(FusumaMode.camera)
    }
    
    @IBAction func videoButtonPressed(_ sender: UIButton) {
        
        changeMode(FusumaMode.video)
    }
    
    func fusumaDidFinishInSingleMode() {
        
        guard let view = albumView.imageCropView else { return }
        
        if FusumaShared.shared.fusumaCropImage {
            
            let normalizedX = view.contentOffset.x / view.contentSize.width
            let normalizedY = view.contentOffset.y / view.contentSize.height
            
            let normalizedWidth  = view.frame.width / view.contentSize.width
            let normalizedHeight = view.frame.height / view.contentSize.height
            
            let cropRect = CGRect(x: normalizedX, y: normalizedY,
                                  width: normalizedWidth, height: normalizedHeight)
            
            requestImage(with: self.albumView.phAsset, cropRect: cropRect) { (asset, image) in
                
                self.delegate?.fusumaImageSelected(image, source: self.mode)
                
                self.dismiss(animated: true, completion: {
                    
                    self.delegate?.fusumaDismissedWithImage(image, source: self.mode)
                })
                
                let metaData = ImageMetadata(
                    mediaType: self.albumView.phAsset.mediaType,
                    pixelWidth: self.albumView.phAsset.pixelWidth,
                    pixelHeight: self.albumView.phAsset.pixelHeight,
                    creationDate: self.albumView.phAsset.creationDate,
                    modificationDate: self.albumView.phAsset.modificationDate,
                    location: self.albumView.phAsset.location,
                    duration: self.albumView.phAsset.duration,
                    isFavourite: self.albumView.phAsset.isFavorite,
                    isHidden: self.albumView.phAsset.isHidden,
                    asset: self.albumView.phAsset)
                
                self.delegate?.fusumaImageSelected(image, source: self.mode, metaData: metaData)
            }
            
        } else {
            
            print("no image to crop")
            delegate?.fusumaImageSelected(view.image, source: mode)
            
            self.dismiss(animated: true) {
            
                self.delegate?.fusumaDismissedWithImage(view.image, source: self.mode)
            }
        }
    }
    
    private func requestImage(with asset: PHAsset, cropRect: CGRect, completion: @escaping (PHAsset, UIImage) -> Void) {
        
        DispatchQueue.global(qos: .default).async(execute: {
            
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.normalizedCropRect = cropRect
            options.resizeMode = .exact
            
            let targetWidth  = floor(CGFloat(asset.pixelWidth) * cropRect.width)
            let targetHeight = floor(CGFloat(asset.pixelHeight) * cropRect.height)
            let dimensionW   = max(min(targetHeight, targetWidth), 1024 * UIScreen.main.scale)
            let dimensionH   = dimensionW * self.getCropHeightRatio()
            
            let targetSize   = CGSize(width: dimensionW, height: dimensionH)
            
            PHImageManager.default().requestImage(
                for: asset, targetSize: targetSize,
                contentMode: .aspectFill, options: options) { result, info in

                guard let result = result else { return }
                    
                DispatchQueue.main.async(execute: {
                    let finalImage = self.fusumaCircularImage ? result.circleMasked : result
                    completion(asset, finalImage)
                })
            }
        })
    }
    
    func fusumaDidFinishInMultipleMode() {
        
        guard let view = albumView.imageCropView else { return }
        
        let normalizedX = view.contentOffset.x / view.contentSize.width
        let normalizedY = view.contentOffset.y / view.contentSize.height
        
        let normalizedWidth  = view.frame.width / view.contentSize.width
        let normalizedHeight = view.frame.height / view.contentSize.height
        
        let cropRect = CGRect(x: normalizedX, y: normalizedY,
                              width: normalizedWidth, height: normalizedHeight)
        
        var images = [UIImage]()
        
        for asset in albumView.selectedAssets {
            
            requestImage(with: asset, cropRect: cropRect) { asset, result in
                
                images.append(result)
                
                if asset == self.albumView.selectedAssets.last {
                    
                    self.dismiss(animated: true) {
                     
                        if let _ = self.delegate?.fusumaMultipleImageSelected {
                        
                            self.delegate?.fusumaMultipleImageSelected(images, source: self.mode)
                        }
                    }
                }
            }
        }
    }
}

extension FusumaViewController: FSAlbumViewDelegate, FSCameraViewDelegate, FSVideoCameraViewDelegate {
    
    public func getCropHeightRatio() -> CGFloat {
        
        return cropHeightRatio
    }
    
    // MARK: FSCameraViewDelegate
    func cameraShotFinished(_ image: UIImage) {
        
        delegate?.fusumaImageSelected(image, source: mode)
        
        self.dismiss(animated: true) {
            
            self.delegate?.fusumaDismissedWithImage(image, source: self.mode)
        }
    }
    
    func cameraUnauthorized() {
        delegate?.fusumaCameraUnauthorized(self)
    }
    
    public func albumViewCameraRollAuthorized() {
        
        // in the case that we're just coming back from granting photo gallery permissions
        // ensure the done button is visible if it should be
        self.updateDoneButtonVisibility()
    }
    
    // MARK: FSAlbumViewDelegate
    public func albumViewCameraRollUnauthorized() {
        
        self.updateDoneButtonVisibility()
        delegate?.fusumaCameraRollUnauthorized(self)
    }
    
    public func albumViewCameraRollFinished() {
        allowMultipleSelection ? self.fusumaDidFinishInMultipleMode() : self.fusumaDidFinishInSingleMode()
    }
    
    func videoFinished(withFileURL fileURL: URL) {
        
        delegate?.fusumaVideoCompleted(withFileURL: fileURL)
        self.dismiss(animated: true, completion: nil)
    }
    
}

private extension FusumaViewController {
    
    func stopAll() {
        
        if availableModes.contains(.video) {

            self.videoView.stopCamera()
        }
        
        if availableModes.contains(.camera) {
            
            self.cameraView.stopCamera()
        }
    }
    
    func changeMode(_ mode: FusumaMode, isForced: Bool = false) {

        if !isForced && self.mode == mode { return }
        
        switch self.mode {
            
        case .camera:
            
            self.cameraView.stopCamera()
        
        case .video:
        
            self.videoView.stopCamera()
        
        default:
        
            break
        }
        
        self.mode = mode
        
        dishighlightButtons()
        updateDoneButtonVisibility()
        
        switch mode {
            
        case .library:
            
            highlightButton(libraryButton)
            self.view.bringSubview(toFront: photoLibraryViewerContainer)
            albumView.performCheckPhotoAuth(shouldInitialize: false)
            
        
        case .camera:
            
            highlightButton(cameraButton)
            self.view.bringSubview(toFront: cameraShotContainer)
            cameraView.startCamera()
            
        case .video:
        
            highlightButton(videoButton)
            self.view.bringSubview(toFront: videoShotContainer)
            videoView.startCamera()
        }
        
    }
    
    func updateDoneButtonVisibility() {

        if !hasGalleryPermission {
            
            return
        }

        switch self.mode {
            
        case .library:

            break
            
        default:
   
            break
        }
    }
    
    func dishighlightButtons() {
        
        cameraButton.setTitleColor(UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: self.mode == .camera ? 1.0 : 0.5), for: .normal)
        
        if let libraryButton = libraryButton {
            
            libraryButton.setTitleColor(UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.5), for: .normal)
        }
        
        if let videoButton = videoButton {
            
            videoButton.setTitleColor(UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.5), for: .normal)
        }
    }
    
    func highlightButton(_ button: UIButton) {
        
        button.setTitleColor(UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0), for: .normal)
    }
    
    func getTabButton(mode: FusumaMode) -> UIButton {
        
        switch mode {
            
        case .library:
            
            return libraryButton
            
        case .camera:
            
            return cameraButton
            
        case .video:
            
            return videoButton
        }
    }
}
