//
//  FusumaViewController.swift
//  Fusuma
//
//  Created by Yuta Akizuki on 2015/11/14.
//  Copyright © 2015年 ytakzk. All rights reserved.
//

import UIKit
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


@objc public protocol FusumaDelegate: class {
    
    func fusumaImageSelected(_ image: UIImage)
    func fusumaCameraRollUnauthorized()
    
    @objc optional func fusumaClosed()
    @objc optional func fusumaDismissedWithImage(_ image: UIImage)
}

public var fusumaTintColor       = UIColor.hex("#009688", alpha: 1.0)
public var fusumaBackgroundColor = UIColor.hex("#212121", alpha: 1.0)


public enum FusumaMode {
    case camera
    case library
}

public enum FusumaModeOrder {
    case cameraFirst
    case libraryFirst
}

public final class FusumaViewController: UIViewController, FSCameraViewDelegate, FSAlbumViewDelegate {

    fileprivate var mode: FusumaMode?
    public var defaultMode: FusumaMode?
    public var modeOrder: FusumaModeOrder = .libraryFirst
    public var willFilter = true

    @IBOutlet weak var photoLibraryViewerContainer: UIView!
    @IBOutlet weak var cameraShotContainer: UIView!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!

    @IBOutlet var libraryFirstConstraints: [NSLayoutConstraint]!
    @IBOutlet var cameraFirstConstraints: [NSLayoutConstraint]!
    
    var albumView  = FSAlbumView.instance()
    public var cameraView = FSCameraView.instance()
    
    public weak var delegate: FusumaDelegate? = nil
    
    override public func loadView() {
        
        if let view = UINib(nibName: "FusumaViewController", bundle: Bundle(for: self.classForCoder)).instantiate(withOwner: self, options: nil).first as? UIView {
            
            self.view = view
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
    
        self.view.backgroundColor = fusumaBackgroundColor
        
        cameraView.delegate = self
        albumView.delegate  = self

        menuView.backgroundColor = fusumaBackgroundColor
        menuView.addBottomBorder(UIColor.black, width: 1.0)
        
        let bundle = Bundle(for: self.classForCoder)
        
        let albumImage = UIImage(named: "ic_insert_photo", in: bundle, compatibleWith: nil)
        let cameraImage = UIImage(named: "ic_photo_camera", in: bundle, compatibleWith: nil)
        let checkImage = UIImage(named: "ic_check", in: bundle, compatibleWith: nil)

        
        libraryButton.setImage(albumImage, for: UIControlState())
        libraryButton.setImage(albumImage, for: .highlighted)
        libraryButton.setImage(albumImage, for: .selected)

        cameraButton.setImage(cameraImage, for: UIControlState())
        cameraButton.setImage(cameraImage, for: .highlighted)
        cameraButton.setImage(cameraImage, for: .selected)
        
        libraryButton.tintColor = fusumaTintColor
        cameraButton.tintColor  = fusumaTintColor
        
        cameraButton.adjustsImageWhenHighlighted  = false
        libraryButton.adjustsImageWhenHighlighted = false
        cameraButton.clipsToBounds  = true
        libraryButton.clipsToBounds = true

        changeMode(defaultMode ?? FusumaMode.library)
        
        photoLibraryViewerContainer.addSubview(albumView)
        cameraShotContainer.addSubview(cameraView)
        
        doneButton.setImage(checkImage, for: UIControlState())
        doneButton.tintColor = UIColor.white

        if modeOrder != .libraryFirst {
            libraryFirstConstraints.forEach { $0.priority = 250 }
            cameraFirstConstraints.forEach { $0.priority = 1000 }
        }
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        albumView.frame  = CGRect(origin: CGPoint.zero, size: photoLibraryViewerContainer.frame.size)
        albumView.layoutIfNeeded()
        cameraView.frame = CGRect(origin: CGPoint.zero, size: cameraShotContainer.frame.size)
        cameraView.layoutIfNeeded()
        
        albumView.initialize()
        cameraView.initialize()
    }

    override public var prefersStatusBarHidden : Bool {
        
        return true
    }
        
    @IBAction func libraryButtonPressed(_ sender: UIButton) {
        
        changeMode(FusumaMode.library)
    }
    
    @IBAction func photoButtonPressed(_ sender: UIButton) {
    
        changeMode(FusumaMode.camera)
    }
    
    @IBAction func doneButtonPressed(_ sender: UIButton) {
        
        let view = albumView.imageCropView
        
        UIGraphicsBeginImageContextWithOptions((view?.frame.size)!, true, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: -albumView.imageCropView.contentOffset.x, y: -albumView.imageCropView.contentOffset.y)
        view?.layer.render(in: context!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        delegate?.fusumaImageSelected(image!)
    }
    
    // MARK: FSCameraViewDelegate
    func cameraShotFinished(_ image: UIImage) {
        
        delegate?.fusumaImageSelected(image)
    }
    
    // MARK: FSAlbumViewDelegate
    public func albumViewCameraRollUnauthorized() {
        
        delegate?.fusumaCameraRollUnauthorized()
    }
}

private extension FusumaViewController {
    
    func changeMode(_ mode: FusumaMode) {

        if self.mode == mode {
            
            return
        }
        
        self.mode = mode
        
        dishighlightButtons()
        
        if mode == FusumaMode.library {
            
            titleLabel.text = "CAMERA ROLL"
            doneButton.isHidden = false
            
            highlightButton(libraryButton)
            self.view.insertSubview(photoLibraryViewerContainer, aboveSubview: cameraShotContainer)
            
        } else {

            titleLabel.text = "PHOTO"
            doneButton.isHidden = true
            
            highlightButton(cameraButton)
            self.view.insertSubview(cameraShotContainer, aboveSubview: photoLibraryViewerContainer)
        }
    }
    
    
    func dishighlightButtons() {
        
        cameraButton.tintColor  = UIColor.white
        libraryButton.tintColor = UIColor.white
        
        if cameraButton.layer.sublayers?.count > 1 {
            
            for layer in cameraButton.layer.sublayers! {
                
                if let borderColor = layer.borderColor , UIColor(cgColor: borderColor) == fusumaTintColor {
                    
                    layer.removeFromSuperlayer()
                }
                
            }
        }
        
        if libraryButton.layer.sublayers?.count > 1 {
            
            for layer in libraryButton.layer.sublayers! {
                
                if let borderColor = layer.borderColor , UIColor(cgColor: borderColor) == fusumaTintColor {
                    
                    layer.removeFromSuperlayer()
                }
                
            }
        }
        
    }
    
    func highlightButton(_ button: UIButton) {
        
        button.tintColor = fusumaTintColor
        
        button.addBottomBorder(fusumaTintColor, width: 3)
    }
}
