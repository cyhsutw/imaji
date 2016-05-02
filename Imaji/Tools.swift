//
//  Tools.swift
//  Imaji
//
//  Created by Cheng-Yu Hsu on 4/30/16.
//  Copyright © 2016 cyhsu. All rights reserved.
//

import Foundation
import UIKit


extension UIColor {
    class func hex (hex : NSString, alpha : CGFloat) -> UIColor {
        let hexStr = hex.stringByReplacingOccurrencesOfString("#", withString: "")
        let scanner = NSScanner(string: hexStr as String)
        var color: UInt32 = 0
        if scanner.scanHexInt(&color) {
            let r = CGFloat((color & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((color & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(color & 0x0000FF) / 255.0
            return UIColor(red:r,green:g,blue:b,alpha:alpha)
        } else {
            print("invalid hex string", terminator: "")
            return UIColor.whiteColor()
        }
    }
}

let BrandColor = UIColor.hex("#FB743B", alpha: 1.0)

func onMainThread(block: (() -> ())) {
    dispatch_async(dispatch_get_main_queue(), block)
}

extension UIImage {
    func fixImageOrientation() -> UIImage {
        
        if self.imageOrientation == UIImageOrientation.Up {
            return self
        }
        
        var transform: CGAffineTransform = CGAffineTransformIdentity
        
        switch self.imageOrientation {
        case UIImageOrientation.Down, UIImageOrientation.DownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI))
            break
        case UIImageOrientation.Left, UIImageOrientation.LeftMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI_2))
            break
        case UIImageOrientation.Right, UIImageOrientation.RightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height)
            transform = CGAffineTransformRotate(transform, CGFloat(-M_PI_2))
            break
        case UIImageOrientation.Up, UIImageOrientation.UpMirrored:
            break
        }
        
        switch self.imageOrientation {
        case UIImageOrientation.UpMirrored, UIImageOrientation.DownMirrored:
            CGAffineTransformTranslate(transform, self.size.width, 0)
            CGAffineTransformScale(transform, -1, 1)
            break
        case UIImageOrientation.LeftMirrored, UIImageOrientation.RightMirrored:
            CGAffineTransformTranslate(transform, self.size.height, 0)
            CGAffineTransformScale(transform, -1, 1)
        case UIImageOrientation.Up, UIImageOrientation.Down, UIImageOrientation.Left, UIImageOrientation.Right:
            break
        }
        
        let ctx:CGContextRef = CGBitmapContextCreate(nil, Int(self.size.width), Int(self.size.height), CGImageGetBitsPerComponent(self.CGImage), 0, CGImageGetColorSpace(self.CGImage), CGImageAlphaInfo.PremultipliedLast.rawValue)!
        
        CGContextConcatCTM(ctx, transform)
        
        switch self.imageOrientation {
        case UIImageOrientation.Left, UIImageOrientation.LeftMirrored, UIImageOrientation.Right, UIImageOrientation.RightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0, 0, self.size.height, self.size.width), self.CGImage)
            break
        default:
            CGContextDrawImage(ctx, CGRectMake(0, 0, self.size.width, self.size.height), self.CGImage)
            break
        }
        
        let cgimg:CGImageRef = CGBitmapContextCreateImage(ctx)!
        let img:UIImage = UIImage(CGImage: cgimg)
        
        return img
    }
}

extension Dictionary where Value : Comparable {
    func sortedKeysByValues(isOrderedBefore: ((Value, Value) -> Bool)) -> [Key] {
        return Array(keys).sort { isOrderedBefore(self[$0]!, self[$1]!) }
    }
}
