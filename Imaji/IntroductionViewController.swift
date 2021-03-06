//
//  IntroductionViewController.swift
//  Imaji
//
//  Created by Cheng-Yu Hsu on 5/1/16.
//  Copyright © 2016 cyhsu. All rights reserved.
//

import UIKit
import LTMorphingLabel

class IntroductionViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView?
    @IBOutlet weak var emojiLabel: UILabel?
    @IBOutlet weak var imajiImageView: UIImageView?
    
    @IBOutlet weak var startButton: UIButton?
    
    @IBOutlet weak var wordLabel: LTMorphingLabel?
    @IBOutlet weak var typeLabel: LTMorphingLabel?
    
    @IBOutlet weak var imageDefLabel: UITextView?
    @IBOutlet weak var emojiDefLabel: UITextView?
    @IBOutlet weak var imajiDefLabel: UITextView?
    
    
    fileprivate let imageDef = "A visible impression displayed on a computer or video screen."
    fileprivate let emojiDef = "A small digital image or icon used to express an idea or emotion in electronic communication."
    fileprivate let imagiDef = "An image with dotted patterns and emojis.\nUsually serve as a riddle."
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView?.clipsToBounds = true
        startButton?.backgroundColor = UIColor.clear
        startButton?.clipsToBounds = true
        startButton?.setBackgroundImage(UIImage(color: BrandColor), for: UIControlState())
        startButton?.setTitleColor(UIColor.white, for: UIControlState())
        startButton?.layer.cornerRadius = 20.0
        startButton?.alpha = 0.0
        startButton?.addTarget(self, action: #selector(self.dismiss(_:)), for: .touchUpInside)
        
        imageView?.alpha = 0.0
        emojiLabel?.alpha = 0.0
        imajiImageView?.alpha = 0.0
        
        imageDefLabel?.alpha = 0.0
        emojiDefLabel?.alpha = 0.0
        imajiDefLabel?.alpha = 0.0
        
        imageDefLabel?.text = imageDef
        emojiDefLabel?.text = emojiDef
        imajiDefLabel?.text = imagiDef
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Thread.sleep(forTimeInterval: 2.0)
        
        self.wordLabel?.text = "image"
        
        delay(1.1) {
            self.typeLabel?.text = "noun"
        }
        
        UIView.animate(
            withDuration: 1.0,
            delay: 2.0,
            options: UIViewAnimationOptions(),
            animations: {
                self.imageDefLabel?.alpha = 1.0
                self.imageView?.alpha = 1.0
            },
            completion: {
                _ in
                delay(3.0) {
                    self.wordLabel?.text = "emoji"
                }
                
                UIView.animate(
                    withDuration: 1.0,
                    delay: 3.0,
                    options: UIViewAnimationOptions(),
                    animations: {
                        self.imageDefLabel?.alpha = 0.0
                        self.emojiDefLabel?.alpha = 1.0
                        self.imageView?.alpha = 0.0
                        self.emojiLabel?.alpha = 1.0
                    },
                    completion: {
                        _ in
                        
                        delay(3.0) {
                            self.wordLabel?.text = "imaji"
                        }
                        
                        UIView.animate(
                            withDuration: 1.0,
                            delay: 3.0,
                            options: UIViewAnimationOptions(),
                            animations: {
                                self.emojiDefLabel?.alpha = 0.0
                                self.imajiDefLabel?.alpha = 1.0
                                self.emojiLabel?.alpha = 0.0
                                self.imajiImageView?.alpha = 1.0
                            },
                            completion: {
                                _ in
                                
                                UIView.animate(
                                    withDuration: 1.0,
                                    delay: 2.0,
                                    options: UIViewAnimationOptions(),
                                    animations: {
                                        self.startButton?.alpha = 1.0
                                    },
                                    completion: nil
                                )
                                
                            }
                        )
                    }
                )
            }
        )
        
    }
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    func dismiss(_ sender: AnyObject!) {
        let cam = storyboard!.instantiateViewController(withIdentifier: "CamView")
        present(cam, animated: true, completion: {
            self.imageView?.image = nil
            self.imajiImageView?.image = nil
            
            let defaults = UserDefaults.standard
            defaults.set(true, forKey: "didShowIntro")
            defaults.synchronize()
        })
    }
}

func delay(_ time: Double, _ block: @escaping (() -> ())) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(time * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC),
        execute: block
    )
}
