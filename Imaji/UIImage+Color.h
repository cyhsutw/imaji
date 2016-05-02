//
//  UIImage+Color.h
//  Imaji
//
//  Created by Cheng-Yu Hsu on 5/1/16.
//  Copyright © 2016 cyhsu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Color)

+(instancetype)imageWithColor:(UIColor *)color;
+(instancetype)imageWithColor:(UIColor *)color size:(CGSize)size;
+(instancetype)gradientImageWithColors:(NSArray *)colors size:(CGSize)size;
+(instancetype)gradientImageWithColors:(NSArray *)colors
                             locations:(NSArray *)locations
                                  size:(CGSize)size;

@end
