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

    fileprivate var shortcutItem: UIApplicationShortcutItem?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        AFNetworkActivityLogger.shared().startLogging()
        
        SVProgressHUD.setMinimumDismissTimeInterval(1.3)
        
        setupToolTip()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let defaults = UserDefaults.standard
        
        let didShowIntro = defaults.bool(forKey: "didShowIntro")
        
        if !didShowIntro {
            let intro = storyboard.instantiateViewController(withIdentifier: "IntroView")
            window?.rootViewController = intro
        } else {
            let cam = storyboard.instantiateViewController(withIdentifier: "CamView")
            window?.rootViewController = cam
        }
        
        window?.makeKeyAndVisible()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    fileprivate func setupToolTip() {
        var preferences = EasyTipView.Preferences()
        preferences.drawing.font = UIFont.systemFont(ofSize: 14.0)
        preferences.drawing.foregroundColor = UIColor.white
        preferences.drawing.backgroundColor = BrandColor
        preferences.drawing.cornerRadius = 4.0
        preferences.drawing.arrowPosition = EasyTipView.ArrowPosition.bottom
        
        preferences.animating.dismissTransform = CGAffineTransform(scaleX: 0.0, y: 0.0).translatedBy(x: 0, y: -8.0)
        preferences.animating.showInitialTransform = CGAffineTransform(scaleX: 0.0, y: 0.0).translatedBy(x: 0, y: -8.0)
        preferences.animating.showFinalTransform = CGAffineTransform(translationX: 0, y: -8.0)
        preferences.animating.showInitialAlpha = 0
        preferences.animating.showDuration = 0.75
        preferences.animating.dismissDuration = 0.75
        
        EasyTipView.globalPreferences = preferences
    }
}

