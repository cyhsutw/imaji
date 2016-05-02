//
//  AppDelegate.swift
//  Imaji
//
//  Created by Cheng-Yu Hsu on 4/28/16.
//  Copyright © 2016 cyhsu. All rights reserved.
//

import UIKit
import AFNetworkActivityLogger
import EasyTipView
import SVProgressHUD

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private var shortcutItem: UIApplicationShortcutItem?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        AFNetworkActivityLogger.sharedLogger().startLogging()
        
        SVProgressHUD.setMinimumDismissTimeInterval(1.3)
        
        setupToolTip()
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let defaults = NSUserDefaults.standardUserDefaults()
        
        let didShowIntro = defaults.boolForKey("didShowIntro")
        
        if !didShowIntro {
            let intro = storyboard.instantiateViewControllerWithIdentifier("IntroView")
            window?.rootViewController = intro
        } else {
            let cam = storyboard.instantiateViewControllerWithIdentifier("CamView")
            window?.rootViewController = cam
        }
        
        window?.makeKeyAndVisible()
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    private func setupToolTip() {
        var preferences = EasyTipView.Preferences()
        preferences.drawing.font = UIFont.systemFontOfSize(14.0)
        preferences.drawing.foregroundColor = UIColor.whiteColor()
        preferences.drawing.backgroundColor = BrandColor
        preferences.drawing.cornerRadius = 4.0
        preferences.drawing.arrowPosition = EasyTipView.ArrowPosition.Bottom
        
        preferences.animating.dismissTransform = CGAffineTransformTranslate(CGAffineTransformMakeScale(0.0, 0.0), 0, -8.0)
        preferences.animating.showInitialTransform = CGAffineTransformTranslate(CGAffineTransformMakeScale(0.0, 0.0), 0, -8.0)
        preferences.animating.showFinalTransform = CGAffineTransformMakeTranslation(0, -8.0)
        preferences.animating.showInitialAlpha = 0
        preferences.animating.showDuration = 0.75
        preferences.animating.dismissDuration = 0.75
        
        EasyTipView.globalPreferences = preferences
    }
}
