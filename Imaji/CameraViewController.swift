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
        case dotted
        case squared
        case smeared
    }
    
    fileprivate let cameraView = FusumaViewController()
    
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
    
    fileprivate var selectedEmojis = [String]()
    fileprivate var detectiveIndex = 0
    fileprivate var detectiveTimer: Timer?
    fileprivate let detectives = ["🕵", "🕵🏾", "🕵🏼", "🕵🏿", "🕵🏻"]
    
    fileprivate var selectedImage: UIImage?
    fileprivate var progressToolTip: EasyTipView?
    
    fileprivate var filter = FilterType.dotted
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        outputLabel?.text = nil
        
        cameraView.delegate = self
        addChildViewController(cameraView)
        cameraView.didMove(toParentViewController: self)
        
        view.addSubview(cameraView.view)
        cameraView.view.translatesAutoresizingMaskIntoConstraints = false
        cameraView.view.autoPinEdgesToSuperviewEdges()
        
        navigationController?.isNavigationBarHidden = true
        
        view.bringSubview(toFront: postEditTopBar!)
        view.bringSubview(toFront: postEditBottomArea!)
        
        previewImageView?.superview?.isHidden = true
        view.bringSubview(toFront: previewImageView!.superview!)
        
        filterSlider?.setThumbImage(UIImage(named: "slider_thumb"), for: UIControlState())
        filterSlider?.addTarget(self, action: #selector(self.filterValueUpdated(_:)), for: .valueChanged)
        
        sliderConfirmButton?.addTarget(self, action: #selector(self.saveFilterButtonPressed(_:)), for: .touchUpInside)
        
        buttonsContainerView?.isHidden = true
        
        adjustDotFilterButton?.alpha = 0.0
        shareButton?.alpha = 0.0
        startOverButton?.alpha = 0.0
        
        adjustDotFilterButton?.addTarget(self, action: #selector(self.adjustDotBtnPressed(_:)), for: .touchUpInside)
        shareButton?.addTarget(self, action: #selector(self.shareButtonPressed(_:)), for: .touchUpInside)
        startOverButton?.addTarget(self, action: #selector(self.resetButtonPressed(_:)), for: .touchUpInside)
        
        adjustDotFilterButton?.isExclusiveTouch = true
        shareButton?.isExclusiveTouch = true
        startOverButton?.isExclusiveTouch = true
        
        VisionAPIManager.sharedManager.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }


}

extension CameraViewController {
    func adjustDotBtnPressed(_ sender: AnyObject!) {
        
        sliderConfirmContainerBottomSpace?.constant = 0.0
        
        UIView.animate(
            withDuration: 0.375,
            delay: 0.0,
            options: UIViewAnimationOptions(),
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
                self.adjustDotFilterButton?.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
                self.shareButton?.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
                self.startOverButton?.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
            }
        )
        
    }
    
    func shareButtonPressed(_ sender: AnyObject!) {
        
        let finalResultImage = drawEmojiOnImage(previewImageView!.image!)
        
        let sharer = UIActivityViewController(
            activityItems: [
                self.selectedEmojis.joined(separator: ""),
                finalResultImage
            ],
            applicationActivities: nil
        )
        
        sharer.completionWithItemsHandler = {
            (type, completed, returnedItems, error) in
            if completed {
                SVProgressHUD.showSuccess(withStatus: nil)
            } else {
                if let _ = error {
                    SVProgressHUD.showError(withStatus: nil)
                }
            }
        }
        
        onMainThread {
            self.present(sharer, animated: true, completion: nil)
        }
    }
    
    func resetButtonPressed(_ sender: AnyObject!) {
        
        postEditTopBarCenterHide?.isActive = true
        postEditTopBarCenterShow?.isActive = false
        
        postEditBottomAreaCenterHide?.isActive = true
        postEditBottomAreaCenterShow?.isActive = false
        
        cameraView.cameraView.restart()
        
        view.setNeedsLayout()
        
        UIView.animate(
            withDuration: 0.375,
            delay: 0.0,
            options: UIViewAnimationOptions(),
            animations: {
                self.view.layoutIfNeeded()
                self.previewImageView?.superview?.alpha = 0.0
            },
            completion: {
                _ in
                self.cameraView.view.isUserInteractionEnabled = true
                self.buttonsContainerView?.isHidden = true
                self.previewImageView?.image = nil
                self.selectedImage = nil
                self.outputLabel?.text = nil
                self.selectedEmojis = [String]()
                self.detectiveLabel?.alpha = 1.0
                self.previewImageView?.superview?.isHidden = true
                self.previewImageView?.superview?.alpha = 1.0
                self.outputLabel?.text = nil
            }
        )
    }
}


extension CameraViewController {
    fileprivate func animateLoadingView() {
        
        resetDetectiveTimer()
        detectiveIndex = 0
        detectiveLabel?.text = detectives[detectiveIndex]
        
        cameraView.view.isUserInteractionEnabled = false
        
        postEditTopBarCenterHide?.isActive = false
        postEditTopBarCenterShow?.isActive = true
        
        postEditBottomAreaCenterHide?.isActive = false
        postEditBottomAreaCenterShow?.isActive = true
        
        view.setNeedsLayout()
        
        UIView.animate(
            withDuration: 0.375,
            delay: 0.0,
            options: UIViewAnimationOptions(),
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
    
    fileprivate func resetDetectiveTimer() {
        if let timer = detectiveTimer {
            timer.invalidate()
        }
        detectiveTimer = nil
    }
    
    fileprivate func startDetectiveTimer() {
        guard detectiveTimer == nil else { return }
        
        detectiveTimer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(CameraViewController.detectiveTimerUpdated(_:)),
            userInfo: nil,
            repeats: true
        )
        detectiveTimer?.fire()
    }
    
    func detectiveTimerUpdated(_ timer: AnyObject!) {
        guard let displayLabel = detectiveLabel else { return }
        
        detectiveIndex = (detectiveIndex + 1) % detectives.count
        
        UIView.transition(
            with: displayLabel,
            duration: 1.0,
            options: .transitionCrossDissolve,
            animations: {
                displayLabel.text = self.detectives[self.detectiveIndex]
            },
            completion: nil
        )
    }
    
    fileprivate func showToolTip() {
        if let toolTip = progressToolTip {
            toolTip.dismiss()
        }
        
        let tipView = EasyTipView(text: "🔍 emojis for you")
        tipView.show(forView: detectiveLabel!, withinSuperview: view)
        
        progressToolTip = tipView
    }
}

extension CameraViewController: FusumaDelegate {
    func fusumaImageSelected(_ image: UIImage) {
        
        buttonsContainerView?.isHidden = true
        startOverButton?.alpha = 0.0
        shareButton?.alpha = 0.0
        adjustDotFilterButton?.alpha = 0.0
        
        startOverButton?.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
        shareButton?.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
        adjustDotFilterButton?.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
        
        filterSlider?.value = 0.01
        selectedImage = image.fixImageOrientation()
        previewImageView?.image = selectedImage
        previewImageView?.superview?.isHidden = false
        VisionAPIManager.sharedManager.uploadImage(selectedImage!)
        
        animateLoadingView()
    }
    
    func fusumaCameraRollUnauthorized() {
    
    }
}

extension CameraViewController: VisionAPIManagerDelgate {
    func progressUpdated(_ progress: Double) {
        let actualP = progress * 0.95
        let k = actualP * (0.05 - 0.01) + 0.01
        onMainThread {
            self.filterSlider?.value = Float(k)
            self.applyFilter()
        }
    }
    
    func completed(objects: [String], emotions: [Emotion]) {
        
        var emojis = Set<String>()
        
        if let emo = emotions.first,
           let icon = EmojiOracle.sharedOracle.toEmoji(emo.rawValue) {
            emojis.insert(icon)
        }
        
        objects.forEach {
            $0.components(separatedBy: " ").forEach {
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
                preferredStyle: .alert
            )
            
            let okAction = UIAlertAction(
                title: "👌",
                style: .cancel,
                handler: {
                    _ in
                    self.progressToolTip?.dismiss()
                    self.resetDetectiveTimer()
                    self.resetButtonPressed(self.startOverButton)
                }
            )
            
            alert.addAction(okAction)
            
            alert.view.tintColor = BrandColor
            
            present(
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
            outputLabel?.text = emojis.joined(separator: " ")
        }
        
        progressToolTip?.dismiss()
        resetDetectiveTimer()
        
        sliderConfirmContainerBottomSpace?.constant = 0.0
        
        UIView.animate(
            withDuration: 0.375,
            delay: 0.0,
            options: UIViewAnimationOptions(),
            animations: {
                self.detectiveLabel?.alpha = 0.0
                self.sliderContainer?.alpha = 1.0
                self.sliderConfirmContainer?.setNeedsLayout()
                self.sliderConfirmContainer?.layoutIfNeeded()
            },
            completion: nil
        )
    }
    
    func failed(_ error: NSError) {
        let alert = UIAlertController(
            title: "😔",
            message: "Sorry, we've encountered some problems, would you mind checking your Internet connections and try again?",
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(
            title: "👌",
            style: .cancel,
            handler: {
                _ in
                self.progressToolTip?.dismiss()
                self.resetDetectiveTimer()
                self.resetButtonPressed(self.startOverButton)
            }
        )
        
        alert.addAction(okAction)
        
        alert.view.tintColor = BrandColor
        
        present(
            alert,
            animated: true,
            completion: {
                alert.view.tintColor = BrandColor
            }
        )
    }
    
}

extension CameraViewController {
    
    func saveFilterButtonPressed(_ sender: AnyObject!) {
        
        sliderConfirmContainerBottomSpace?.constant = -60.0

        UIView.animate(
            withDuration: 0.375,
            delay: 0.0,
            options: UIViewAnimationOptions(),
            animations: {
                self.sliderContainer?.alpha = 0.0
                self.sliderConfirmContainer?.setNeedsLayout()
                self.sliderConfirmContainer?.layoutIfNeeded()
            },
            completion: nil
        )
        
        buttonsContainerView?.isHidden = false
        
        startOverButton?.alpha = 0.0
        shareButton?.alpha = 0.0
        adjustDotFilterButton?.alpha = 0.0
        
        UIView.animate(
            withDuration: 0.3,
            delay: 0.1,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.5,
            options: UIViewAnimationOptions(),
            animations: {
                self.adjustDotFilterButton?.alpha = 1.0
                self.adjustDotFilterButton?.transform = CGAffineTransform.identity
            },
            completion: nil
        )
        
        UIView.animate(
            withDuration: 0.3,
            delay: 0.2,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.5,
            options: UIViewAnimationOptions(),
            animations: {
                self.shareButton?.alpha = 1.0
                self.shareButton?.transform = CGAffineTransform.identity
            },
            completion: nil
        )
        
        UIView.animate(
            withDuration: 0.3,
            delay: 0.3,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.5,
            options: UIViewAnimationOptions(),
            animations: {
                self.startOverButton?.alpha = 1.0
                self.startOverButton?.transform = CGAffineTransform.identity
            },
            completion: nil
        )
    }
    
    func filterValueUpdated(_ sender: AnyObject!) {
        applyFilter()
    }
    
    func applyFilter() {
        let stillImageSource = GPUImagePicture(image: selectedImage)
        let stillImageFilter = GPUImagePolkaDotFilter()
        stillImageFilter.fractionalWidthOfAPixel = CGFloat(filterSlider!.value)
        
        stillImageSource?.addTarget(stillImageFilter)
        stillImageFilter.useNextFrameForImageCapture()
        stillImageSource?.processImage()
        
        let outcomeImage = stillImageFilter.imageFromCurrentFramebuffer()
        previewImageView?.image = outcomeImage
    }
    
    fileprivate func drawEmojiOnImage(_ image: UIImage) -> UIImage {
        
        let text: NSString = outputLabel!.text as NSString? ?? ""
        
        
        let scale = image.size.width / view.frame.size.width
        let font = UIFont(name: outputLabel!.font!.fontName, size: outputLabel!.font!.pointSize * scale)!
        let textFrame = outputLabel!.frame.applying(CGAffineTransform(scaleX: scale, y: scale))
        
        UIGraphicsBeginImageContextWithOptions(image.size, true, 0.0)
        image.draw(in: CGRect(x: 0.0, y: 0.0, width: image.size.width, height: image.size.height))
        text.draw(
            in: textFrame,
            withAttributes: [
                NSFontAttributeName : font
            ]
        )
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        
        return newImage!;
    }
}

