//
//  FSCameraView.swift
//  Fusuma
//
//  Created by Yuta Akizuki on 2015/11/14.
//  Copyright © 2015年 ytakzk. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion
import Photos

@objc protocol FSCameraViewDelegate: class {
    func cameraShotFinished(_ image: UIImage)
    func cameraUnauthorized()
}

final class FSCameraView: UIView, UIGestureRecognizerDelegate {

    @IBOutlet weak var previewViewContainer: UIView!
    @IBOutlet weak var approveViewContainer: UIView!
    @IBOutlet weak var buttonPanelContainer: UIView!
    @IBOutlet weak var shotButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var flipButton: UIButton!
    @IBOutlet weak var fullAspectRatioConstraint: NSLayoutConstraint!
    var croppedAspectRatioConstraint: NSLayoutConstraint?
    
    weak var delegate: FSCameraViewDelegate? = nil
    var circularImage: Bool  = false
    var triggerTint: UIColor?
    var flashTint: UIColor?
    var flipTint: UIColor?
    
    fileprivate var session: AVCaptureSession?
    fileprivate var device: AVCaptureDevice?
    fileprivate var videoInput: AVCaptureDeviceInput?
    fileprivate var imageOutput: AVCaptureStillImageOutput?
    fileprivate var videoLayer: AVCaptureVideoPreviewLayer?
    fileprivate var finalImage: UIImage?
    fileprivate var pureFinalImage: UIImage?

    fileprivate var focusView: UIView?

    fileprivate var flashOffImage: UIImage?
    fileprivate var flashOnImage: UIImage?
    
    fileprivate var motionManager: CMMotionManager?
    fileprivate var currentDeviceOrientation: UIDeviceOrientation?
    
    static func instance() -> FSCameraView {
        
        return UINib(nibName: "FSCameraView", bundle: Bundle(for: self.classForCoder())).instantiate(withOwner: self, options: nil)[0] as! FSCameraView
    }
    
    func initialize() {
        
        if session != nil { return }
        
        self.backgroundColor = FusumaShared.shared.fusumaBackgroundColor
        
        let bundle = Bundle(for: self.classForCoder)
        
        flashOnImage = FusumaShared.shared.fusumaFlashOnImage != nil ? FusumaShared.shared.fusumaFlashOnImage : UIImage(named: "ic_flash_on", in: bundle, compatibleWith: nil)
        flashOffImage = FusumaShared.shared.fusumaFlashOffImage != nil ? FusumaShared.shared.fusumaFlashOffImage : UIImage(named: "ic_flash_off", in: bundle, compatibleWith: nil)
        let flipImage = FusumaShared.shared.fusumaFlipImage != nil ? FusumaShared.shared.fusumaFlipImage : UIImage(named: "ic_loop", in: bundle, compatibleWith: nil)
        let shotImage = FusumaShared.shared.fusumaShotImage != nil ? FusumaShared.shared.fusumaShotImage : UIImage(named: "ic_shutter", in: bundle, compatibleWith: nil)
        
        flashButton.tintColor = (flipTint != nil) ? flipTint : FusumaShared.shared.fusumaBaseTintColor
        flipButton.tintColor  = (flashTint != nil) ? flashTint : FusumaShared.shared.fusumaBaseTintColor
        shotButton.tintColor  = (triggerTint != nil) ? triggerTint : FusumaShared.shared.fusumaBaseTintColor
    
        flashButton.setImage(flashOffImage?.withRenderingMode(.alwaysTemplate), for: .normal)
        flipButton.setImage(flipImage?.withRenderingMode(.alwaysTemplate), for: .normal)
        shotButton.setImage(shotImage?.withRenderingMode(.alwaysTemplate), for: .normal)
        
        self.isHidden = false
        
        // AVCapture
        session = AVCaptureSession()
        
        guard let session = session else { return }
        
        for device in AVCaptureDevice.devices() {
            
            if let device = device as? AVCaptureDevice,
                device.position == FusumaShared.shared.fusumaCameraDirection{
                
                self.device = device
                
                if !device.hasFlash {
                    
                    flashButton.isHidden = true
                }
            }
        }
        
        do {
            
            videoInput = try AVCaptureDeviceInput(device: device)
            
            session.addInput(videoInput)
            
            imageOutput = AVCaptureStillImageOutput()
            
            session.addOutput(imageOutput)
            
            videoLayer = AVCaptureVideoPreviewLayer(session: session)
            videoLayer?.frame = self.previewViewContainer.bounds
            videoLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            
            self.previewViewContainer.layer.addSublayer(videoLayer!)
            
            // adding circle
            if (circularImage) {
                let radius = previewViewContainer.frame.size.width
                let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: previewViewContainer.bounds.size.width, height: previewViewContainer.bounds.size.height), cornerRadius: 0)
                let circlePath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: radius, height: radius), cornerRadius: radius/2)
                path.append(circlePath)
                path.usesEvenOddFillRule = true
                
                let fillLayer = CAShapeLayer()
                fillLayer.path = path.cgPath
                fillLayer.fillRule = kCAFillRuleEvenOdd
                fillLayer.fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor
                fillLayer.opacity = 0.5
                previewViewContainer.layer.addSublayer(fillLayer)
            }
            
            session.sessionPreset = AVCaptureSessionPresetPhoto
            
            session.startRunning()

            // Focus View
            self.focusView         = UIView(frame: CGRect(x: 0, y: 0, width: 90, height: 90))
            let tapRecognizer      = UITapGestureRecognizer(target: self, action:#selector(FSCameraView.focus(_:)))
            tapRecognizer.delegate = self
            self.previewViewContainer.addGestureRecognizer(tapRecognizer)
            
        } catch {
            
        }
        
        flashConfiguration()
        
        self.startCamera()
        
        NotificationCenter.default.addObserver(self, selector: #selector(FSCameraView.willEnterForegroundNotification(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    func willEnterForegroundNotification(_ notification: Notification) {
        
        startCamera()
    }
    
    deinit {
        
        NotificationCenter.default.removeObserver(self)
        self.finalImage = nil
    }
    
    func startCamera() {
        
        if (self.finalImage != nil) { return }
        
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut,
                       animations: {self.approveViewContainer.alpha = 0},
                       completion: { _ in
                        self.approveViewContainer.isHidden = true
                        self.buttonPanelContainer.isHidden = false
                        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn,
                                       animations: {self.buttonPanelContainer.alpha = 1},
                                       completion: nil)
        })
        
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
            
        case .authorized:
            
            session?.commitConfiguration()
            
            session?.startRunning()
            
            motionManager = CMMotionManager()
            motionManager!.accelerometerUpdateInterval = 0.2
            motionManager!.startAccelerometerUpdates(to: OperationQueue()) { [unowned self] (data, _) in
                
                if let data = data {
                    
                    if abs(data.acceleration.y) < abs(data.acceleration.x) {
                        
                        self.currentDeviceOrientation = data.acceleration.x > 0 ? .landscapeRight : .landscapeLeft

                    } else {
                        
                        self.currentDeviceOrientation = data.acceleration.y > 0 ? .portraitUpsideDown : .portrait
                    }
                }
            }
            
        case .denied, .restricted:
            
            stopCamera()
            self.approveViewContainer.isUserInteractionEnabled = false
            self.buttonPanelContainer.isUserInteractionEnabled = false
            self.delegate?.cameraUnauthorized()
            
        default:
            
            break
        }
    }
    
    
    func stopCamera() {
        
        session?.stopRunning()
        motionManager?.stopAccelerometerUpdates()
        currentDeviceOrientation = nil
    }
    
    @IBOutlet weak var UseImageThatWasTakenButton: UIButton!
    @IBAction func UseImageThatWasTakeWithCamera(_ sender: Any) {
        
        guard let croppedUIImage = FusumaShared.shared.fusumaReturnSqareImage ? self.pureFinalImage : self.finalImage else {
            print("there was no image to set for the delegate")
            return
        }
        
        DispatchQueue.main.async(execute: { [weak self]() -> Void in
            guard let this = self else {
                print("FSCameraView no loger present")
                return
            }
            this.delegate?.cameraShotFinished(croppedUIImage)
            
            if FusumaShared.shared.fusumaSavesImage {
                
                this.saveImageToCameraRoll(image: croppedUIImage)
            }
            
            this.session       = nil
            this.videoLayer    = nil
            this.device        = nil
            this.imageOutput   = nil
            this.motionManager = nil
        })
        
    }
    
    func approveViewEnabled(_ enabled: Bool) {
        flipButton.isEnabled = !enabled
        shotButton.isEnabled = !enabled
        flashButton.isEnabled = !enabled
        takeNewImageButton.isEnabled = enabled
        UseImageThatWasTakenButton.isEnabled = enabled
    }
    
    @IBOutlet weak var takeNewImageButton: UIButton!
    @IBAction func takeANewImage(_ sender: Any) {
        approveViewEnabled(false)
        self.finalImage = nil
        self.startCamera()
    }
    
    @IBAction func shotButtonPressed(_ sender: UIButton) {
        approveViewEnabled(true)
        
        guard let imageOutput = imageOutput else {
            
            return
        }
        
        DispatchQueue.global(qos: .default).async(execute: { [weak self] () -> Void in
            guard let this = self else {
                print("FSCameraView no loger present")
                return
            }
            
            let videoConnection = imageOutput.connection(withMediaType: AVMediaTypeVideo)
            
            imageOutput.captureStillImageAsynchronously(from: videoConnection) { (buffer, error) -> Void in
                
                this.stopCamera()
                
                guard let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer),
                    let image = UIImage(data: data),
                    let cgImage = image.cgImage,
                    let videoLayer = this.videoLayer else {
                        
                        return
                }
                
                let rect   = videoLayer.metadataOutputRectOfInterest(for: videoLayer.bounds)
                let width  = CGFloat(cgImage.width)
                let height = CGFloat(cgImage.height)
                
                let cropRect = CGRect(x: rect.origin.x * width,
                                      y: rect.origin.y * height,
                                      width: rect.size.width * width,
                                      height: rect.size.height * height)
                
                guard let img = cgImage.cropping(to: cropRect) else {
                    
                    return
                }
                let finalImage = UIImage(cgImage: img, scale: 1.0, orientation: image.imageOrientation)
                this.pureFinalImage = finalImage
                this.finalImage = this.circularImage ? finalImage.circleMasked : finalImage
                
                UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut,
                               animations: {this.buttonPanelContainer.alpha = 0},
                               completion: { _ in
                                this.buttonPanelContainer.isHidden = true
                                this.approveViewContainer.isHidden = false
                                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn,
                                               animations: {this.approveViewContainer.alpha = 1},
                                               completion: nil)
                })
                
            }
        })
        
    }
    
    @IBAction func flipButtonPressed(_ sender: UIButton) {
        
        

        if !cameraIsAvailable { return }
        
        session?.stopRunning()
        
        do {

            session?.beginConfiguration()

            if let session = session {
                
                for input in session.inputs {
                    
                    session.removeInput(input as! AVCaptureInput)
                }

                let position = (videoInput?.device.position == AVCaptureDevicePosition.front) ? AVCaptureDevicePosition.back : AVCaptureDevicePosition.front

                for device in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) {

                    if let device = device as? AVCaptureDevice , device.position == position {
                 
                        videoInput = try AVCaptureDeviceInput(device: device)
                        session.addInput(videoInput)
                    }
                }

            }
            
            session?.commitConfiguration()
            
        } catch {
            
        }
        
        session?.startRunning()
    }
    
    @IBAction func flashButtonPressed(_ sender: UIButton) {

        if !cameraIsAvailable { return }

        do {
            
            guard let device = device, device.hasFlash else { return }
            
            try device.lockForConfiguration()
            
            switch device.flashMode {
                
            case .off:
                
                device.flashMode = AVCaptureFlashMode.on
                flashButton.setImage(flashOnImage?.withRenderingMode(.alwaysTemplate), for: UIControlState())
                
            case .on:
                
                device.flashMode = AVCaptureFlashMode.off
                flashButton.setImage(flashOffImage?.withRenderingMode(.alwaysTemplate), for: UIControlState())
                
            default:
                
                break
            }
            
            device.unlockForConfiguration()

        } catch _ {

            flashButton.setImage(flashOffImage?.withRenderingMode(.alwaysTemplate), for: UIControlState())
            
            return
        }
 
    }
}

fileprivate extension FSCameraView {
    
    func saveImageToCameraRoll(image: UIImage) {
        
        PHPhotoLibrary.shared().performChanges({
            
            PHAssetChangeRequest.creationRequestForAsset(from: image)
            
        }, completionHandler: nil)
    }
    
    @objc func focus(_ recognizer: UITapGestureRecognizer) {
        
        let point = recognizer.location(in: self)
        let viewsize = self.bounds.size
        let newPoint = CGPoint(x: point.y/viewsize.height, y: 1.0-point.x/viewsize.width)
        
        guard let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) else {
            
            return
        }
        
        do {
            
            try device.lockForConfiguration()
            
        } catch _ {
            
            return
        }
        
        if device.isFocusModeSupported(AVCaptureFocusMode.autoFocus) == true {

            device.focusMode = AVCaptureFocusMode.autoFocus
            device.focusPointOfInterest = newPoint
        }

        if device.isExposureModeSupported(AVCaptureExposureMode.continuousAutoExposure) == true {
            
            device.exposureMode = AVCaptureExposureMode.continuousAutoExposure
            device.exposurePointOfInterest = newPoint
        }
        
        device.unlockForConfiguration()
        
        guard let focusView = self.focusView else { return }
        
        focusView.alpha = 0.0
        focusView.center = point
        focusView.backgroundColor = UIColor.clear
        focusView.layer.borderColor = FusumaShared.shared.fusumaBaseTintColor.cgColor
        focusView.layer.borderWidth = 1.0
        focusView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        addSubview(focusView)
        
        UIView.animate(withDuration: 0.8,
                       delay: 0.0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 3.0,
                       options: UIViewAnimationOptions.curveEaseIn,
                       animations: {
            
                focusView.alpha = 1.0
                focusView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        
        }, completion: {(finished) in
        
            focusView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            focusView.removeFromSuperview()
        })
    }
    
    func flashConfiguration() {
    
        do {
            
            if let device = device {
                
                guard device.hasFlash else { return }
                
                try device.lockForConfiguration()
                
                device.flashMode = AVCaptureFlashMode.off
                flashButton.setImage(flashOffImage?.withRenderingMode(.alwaysTemplate), for: UIControlState())
                
                device.unlockForConfiguration()
                
            }
            
        } catch _ {
            
            return
        }
    }

    var cameraIsAvailable: Bool {

        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)

        if status == AVAuthorizationStatus.authorized {

            return true
        }

        return false
    }
}
