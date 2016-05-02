//
//  CameraViewController.swift
//  Imaji
//
//  Created by Cheng-Yu Hsu on 4/28/16.
//  Copyright © 2016 cyhsu. All rights reserved.
//

import UIKit
import CoreLocation
import Fusuma
import PureLayout
import EasyTipView
import GPUImage
import SVProgressHUD

class CameraViewController: UIViewController {

    enum FilterType {
        case Dotted
        case Squared
        case Smeared
    }
    
    private let cameraView = FusumaViewController()
    
    @IBOutlet weak var postEditTopBar: UIView?
    @IBOutlet weak var postEditBottomArea: UIView?
    
    @IBOutlet var postEditTopBarCenterHide: NSLayoutConstraint?
    @IBOutlet var postEditTopBarCenterShow: NSLayoutConstraint?
    
    @IBOutlet weak var previewImageView: UIImageView?
    
    @IBOutlet var postEditBottomAreaCenterHide: NSLayoutConstraint?
    @IBOutlet var postEditBottomAreaCenterShow: NSLayoutConstraint?
    
    @IBOutlet weak var detectiveLabel: UILabel?
    
    @IBOutlet weak var sliderContainer: UIView?
    @IBOutlet weak var filterSlider: UISlider?
    @IBOutlet weak var sliderConfirmContainer: UIView?
    @IBOutlet weak var sliderConfirmButton: UIButton?
    
    @IBOutlet var sliderConfirmContainerBottomSpace: NSLayoutConstraint?
    
    @IBOutlet weak var outputLabel: UILabel?
    
    @IBOutlet weak var adjustDotFilterButton: UIButton?
    @IBOutlet weak var shareButton: UIButton?
    @IBOutlet weak var startOverButton: UIButton?
    
    @IBOutlet weak var buttonsContainerView: UIView?
    
    private var selectedEmojis = [String]()
    private var detectiveIndex = 0
    private var detectiveTimer: NSTimer?
    private let detectives = ["🕵", "🕵🏾", "🕵🏼", "🕵🏿", "🕵🏻"]
    
    private var selectedImage: UIImage?
    private var progressToolTip: EasyTipView?
    
    private var filter = FilterType.Dotted
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        outputLabel?.text = nil
        
        cameraView.delegate = self
        addChildViewController(cameraView)
        cameraView.didMoveToParentViewController(self)
        
        view.addSubview(cameraView.view)
        cameraView.view.translatesAutoresizingMaskIntoConstraints = false
        cameraView.view.autoPinEdgesToSuperviewEdges()
        
        navigationController?.navigationBarHidden = true
        
        view.bringSubviewToFront(postEditTopBar!)
        view.bringSubviewToFront(postEditBottomArea!)
        
        previewImageView?.superview?.hidden = true
        view.bringSubviewToFront(previewImageView!.superview!)
        
        filterSlider?.setThumbImage(UIImage(named: "slider_thumb"), forState: .Normal)
        filterSlider?.addTarget(self, action: #selector(self.filterValueUpdated(_:)), forControlEvents: .ValueChanged)
        
        sliderConfirmButton?.addTarget(self, action: #selector(self.saveFilterButtonPressed(_:)), forControlEvents: .TouchUpInside)
        
        buttonsContainerView?.hidden = true
        
        adjustDotFilterButton?.alpha = 0.0
        shareButton?.alpha = 0.0
        startOverButton?.alpha = 0.0
        
        adjustDotFilterButton?.addTarget(self, action: #selector(self.adjustDotBtnPressed(_:)), forControlEvents: .TouchUpInside)
        shareButton?.addTarget(self, action: #selector(self.shareButtonPressed(_:)), forControlEvents: .TouchUpInside)
        startOverButton?.addTarget(self, action: #selector(self.resetButtonPressed(_:)), forControlEvents: .TouchUpInside)
        
        adjustDotFilterButton?.exclusiveTouch = true
        shareButton?.exclusiveTouch = true
        startOverButton?.exclusiveTouch = true
        
        VisionAPIManager.sharedManager.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }


}

extension CameraViewController {
    func adjustDotBtnPressed(sender: AnyObject!) {
        
        sliderConfirmContainerBottomSpace?.constant = 0.0
        
        UIView.animateWithDuration(
            0.375,
            delay: 0.0,
            options: .CurveEaseInOut,
            animations: {
                self.sliderContainer?.alpha = 1.0
                self.sliderConfirmContainer?.setNeedsLayout()
                self.sliderConfirmContainer?.layoutIfNeeded()
                
                self.adjustDotFilterButton?.alpha = 0.0
                self.shareButton?.alpha = 0.0
                self.startOverButton?.alpha = 0.0
            },
            completion: {
                _ in
                self.adjustDotFilterButton?.transform = CGAffineTransformMakeScale(0.0, 0.0)
                self.shareButton?.transform = CGAffineTransformMakeScale(0.0, 0.0)
                self.startOverButton?.transform = CGAffineTransformMakeScale(0.0, 0.0)
            }
        )
        
    }
    
    func shareButtonPressed(sender: AnyObject!) {
        
        let finalResultImage = drawEmojiOnImage(previewImageView!.image!)
        
        let sharer = UIActivityViewController(
            activityItems: [
                self.selectedEmojis.joinWithSeparator(""),
                finalResultImage
            ],
            applicationActivities: nil
        )
        
        sharer.completionWithItemsHandler = {
            (type, completed, returnedItems, error) in
            if completed {
                SVProgressHUD.showSuccessWithStatus(nil)
            } else {
                if let _ = error {
                    SVProgressHUD.showErrorWithStatus(nil)
                }
            }
        }
        
        onMainThread {
            self.presentViewController(sharer, animated: true, completion: nil)
        }
    }
    
    func resetButtonPressed(sender: AnyObject!) {
        
        postEditTopBarCenterHide?.active = true
        postEditTopBarCenterShow?.active = false
        
        postEditBottomAreaCenterHide?.active = true
        postEditBottomAreaCenterShow?.active = false
        
        cameraView.cameraView.didCaptureImage = false
        
        view.setNeedsLayout()
        
        UIView.animateWithDuration(
            0.375,
            delay: 0.0,
            options: .CurveEaseInOut,
            animations: {
                self.view.layoutIfNeeded()
                self.previewImageView?.superview?.alpha = 0.0
            },
            completion: {
                _ in
                self.cameraView.view.userInteractionEnabled = true
                self.buttonsContainerView?.hidden = true
                self.previewImageView?.image = nil
                self.selectedImage = nil
                self.outputLabel?.text = nil
                self.selectedEmojis = [String]()
                self.detectiveLabel?.alpha = 1.0
                self.previewImageView?.superview?.hidden = true
                self.previewImageView?.superview?.alpha = 1.0
                self.outputLabel?.text = nil
            }
        )
    }
}


extension CameraViewController {
    private func animateLoadingView() {
        
        resetDetectiveTimer()
        detectiveIndex = 0
        detectiveLabel?.text = detectives[detectiveIndex]
        
        cameraView.view.userInteractionEnabled = false
        
        postEditTopBarCenterHide?.active = false
        postEditTopBarCenterShow?.active = true
        
        postEditBottomAreaCenterHide?.active = false
        postEditBottomAreaCenterShow?.active = true
        
        view.setNeedsLayout()
        
        UIView.animateWithDuration(
            0.375,
            delay: 0.0,
            options: .CurveEaseInOut,
            animations: {
                self.view.layoutIfNeeded()
            },
            completion: {
                _ in
                self.startDetectiveTimer()
                self.showToolTip()
            }
        )
        
    }
    
    private func resetDetectiveTimer() {
        if let timer = detectiveTimer {
            timer.invalidate()
        }
        detectiveTimer = nil
    }
    
    private func startDetectiveTimer() {
        guard detectiveTimer == nil else { return }
        
        detectiveTimer = NSTimer.scheduledTimerWithTimeInterval(
            1.0,
            target: self,
            selector: #selector(CameraViewController.detectiveTimerUpdated(_:)),
            userInfo: nil,
            repeats: true
        )
        detectiveTimer?.fire()
    }
    
    func detectiveTimerUpdated(timer: AnyObject!) {
        guard let displayLabel = detectiveLabel else { return }
        
        detectiveIndex = (detectiveIndex + 1) % detectives.count
        
        UIView.transitionWithView(
            displayLabel,
            duration: 1.0,
            options: .TransitionCrossDissolve,
            animations: {
                displayLabel.text = self.detectives[self.detectiveIndex]
            },
            completion: nil
        )
    }
    
    private func showToolTip() {
        if let toolTip = progressToolTip {
            toolTip.dismiss()
        }
        
        let tipView = EasyTipView(text: "🔍 emojis for you")
        tipView.show(forView: detectiveLabel!, withinSuperview: view)
        
        progressToolTip = tipView
    }
}

extension CameraViewController: FusumaDelegate {
    func fusumaImageSelected(image: UIImage) {
        
        buttonsContainerView?.hidden = true
        startOverButton?.alpha = 0.0
        shareButton?.alpha = 0.0
        adjustDotFilterButton?.alpha = 0.0
        
        startOverButton?.transform = CGAffineTransformMakeScale(0.0, 0.0)
        shareButton?.transform = CGAffineTransformMakeScale(0.0, 0.0)
        adjustDotFilterButton?.transform = CGAffineTransformMakeScale(0.0, 0.0)
        
        filterSlider?.value = 0.01
        selectedImage = image.fixImageOrientation()
        previewImageView?.image = selectedImage
        previewImageView?.superview?.hidden = false
        VisionAPIManager.sharedManager.uploadImage(selectedImage!)
        
        animateLoadingView()
    }
    
    func fusumaCameraRollUnauthorized() {
    
    }
}

extension CameraViewController: VisionAPIManagerDelgate {
    func progressUpdated(progress: Double) {
        let actualP = progress * 0.95
        let k = actualP * (0.05 - 0.01) + 0.01
        onMainThread {
            self.filterSlider?.value = Float(k)
            self.applyFilter()
        }
    }
    
    func completed(objects objects: [String], emotions: [Emotion]) {
        
        var emojis = Set<String>()
        
        if let emo = emotions.first,
           let icon = EmojiOracle.sharedOracle.toEmoji(emo.rawValue) {
            emojis.insert(icon)
        }
        
        objects.forEach {
            $0.componentsSeparatedByString(" ").forEach {
                (str) in
                if let e = EmojiOracle.sharedOracle.toEmoji(str) {
                    if emojis.count < 4 {
                        emojis.insert(e)
                    }
                }
            }
        }
        
        self.applyFilter()
        
        let emoArr = Array(emojis)
        self.selectedEmojis = emoArr
        
        if emojis.count == 0 {
            let alert = UIAlertController(
                title: "😔",
                message: "Sorry, we can't find emojis for you.\nPlease try another photo.",
                preferredStyle: .Alert
            )
            
            let okAction = UIAlertAction(
                title: "👌",
                style: .Cancel,
                handler: {
                    _ in
                    self.progressToolTip?.dismiss()
                    self.resetDetectiveTimer()
                    self.resetButtonPressed(self.startOverButton)
                }
            )
            
            alert.addAction(okAction)
            
            alert.view.tintColor = BrandColor
            
            presentViewController(
                alert,
                animated: true,
                completion: {
                    alert.view.tintColor = BrandColor
                }
            )
            return
        }
        
        if emojis.count == 4 {
            outputLabel?.text = "\(emoArr[0]) \(emoArr[1])\n\(emoArr[2]) \(emoArr[3])"
        } else {
            outputLabel?.text = emojis.joinWithSeparator(" ")
        }
        
        progressToolTip?.dismiss()
        resetDetectiveTimer()
        
        sliderConfirmContainerBottomSpace?.constant = 0.0
        
        UIView.animateWithDuration(
            0.375,
            delay: 0.0,
            options: .CurveEaseInOut,
            animations: {
                self.detectiveLabel?.alpha = 0.0
                self.sliderContainer?.alpha = 1.0
                self.sliderConfirmContainer?.setNeedsLayout()
                self.sliderConfirmContainer?.layoutIfNeeded()
            },
            completion: nil
        )
    }
    
    func failed(error: NSError) {
        let alert = UIAlertController(
            title: "😔",
            message: "Sorry, we've encountered some problems, would you mind checking your Internet connections and try again?",
            preferredStyle: .Alert
        )
        
        let okAction = UIAlertAction(
            title: "👌",
            style: .Cancel,
            handler: {
                _ in
                self.progressToolTip?.dismiss()
                self.resetDetectiveTimer()
                self.resetButtonPressed(self.startOverButton)
            }
        )
        
        alert.addAction(okAction)
        
        alert.view.tintColor = BrandColor
        
        presentViewController(
            alert,
            animated: true,
            completion: {
                alert.view.tintColor = BrandColor
            }
        )
    }
    
}

extension CameraViewController {
    
    func saveFilterButtonPressed(sender: AnyObject!) {
        
        sliderConfirmContainerBottomSpace?.constant = -60.0

        UIView.animateWithDuration(
            0.375,
            delay: 0.0,
            options: .CurveEaseInOut,
            animations: {
                self.sliderContainer?.alpha = 0.0
                self.sliderConfirmContainer?.setNeedsLayout()
                self.sliderConfirmContainer?.layoutIfNeeded()
            },
            completion: nil
        )
        
        buttonsContainerView?.hidden = false
        
        startOverButton?.alpha = 0.0
        shareButton?.alpha = 0.0
        adjustDotFilterButton?.alpha = 0.0
        
        UIView.animateWithDuration(
            0.3,
            delay: 0.1,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.5,
            options: .CurveEaseInOut,
            animations: {
                self.adjustDotFilterButton?.alpha = 1.0
                self.adjustDotFilterButton?.transform = CGAffineTransformIdentity
            },
            completion: nil
        )
        
        UIView.animateWithDuration(
            0.3,
            delay: 0.2,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.5,
            options: .CurveEaseInOut,
            animations: {
                self.shareButton?.alpha = 1.0
                self.shareButton?.transform = CGAffineTransformIdentity
            },
            completion: nil
        )
        
        UIView.animateWithDuration(
            0.3,
            delay: 0.3,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.5,
            options: .CurveEaseInOut,
            animations: {
                self.startOverButton?.alpha = 1.0
                self.startOverButton?.transform = CGAffineTransformIdentity
            },
            completion: nil
        )
    }
    
    func filterValueUpdated(sender: AnyObject!) {
        applyFilter()
    }
    
    func applyFilter() {
        let stillImageSource = GPUImagePicture(image: selectedImage)
        let stillImageFilter = GPUImagePolkaDotFilter()
        stillImageFilter.fractionalWidthOfAPixel = CGFloat(filterSlider!.value)
        
        stillImageSource.addTarget(stillImageFilter)
        stillImageFilter.useNextFrameForImageCapture()
        stillImageSource.processImage()
        
        let outcomeImage = stillImageFilter.imageFromCurrentFramebuffer()
        previewImageView?.image = outcomeImage
    }
    
    private func drawEmojiOnImage(image: UIImage) -> UIImage {
        
        let text: NSString = outputLabel!.text ?? ""
        
        
        let scale = image.size.width / view.frame.size.width
        let font = UIFont(name: outputLabel!.font!.fontName, size: outputLabel!.font!.pointSize * scale)!
        let textFrame = CGRectApplyAffineTransform(outputLabel!.frame, CGAffineTransformMakeScale(scale, scale))
        
        UIGraphicsBeginImageContextWithOptions(image.size, true, 0.0)
        image.drawInRect(CGRectMake(0.0, 0.0, image.size.width, image.size.height))
        text.drawInRect(
            textFrame,
            withAttributes: [
                NSFontAttributeName : font
            ]
        )
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        
        return newImage;
    }
}

