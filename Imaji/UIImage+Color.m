//
//  UIImage+Color.m
//  Imaji
//
//  Created by Cheng-Yu Hsu on 5/1/16.
//  Copyright © 2016 cyhsu. All rights reserved.
//

#import "UIImage+Color.h"

@implementation UIImage (Color)

+(instancetype)imageWithColor:(UIColor *)color
{
    return [UIImage imageWithColor:color andSize:CGSizeMake(1.0, 1.0) autoScale:NO];
}

+(instancetype)imageWithColor:(UIColor *)color size:(CGSize)size
{
    return [UIImage imageWithColor:color andSize:size autoScale:YES];
}

+(instancetype)gradientImageWithColors:(NSArray *)colors size:(CGSize)size
{
    return [UIImage gradientImageWithColors:colors locations:nil size:size];
}

+(instancetype)gradientImageWithColors:(NSArray *)colors
                             locations:(NSArray *)locations
                                  size:(CGSize)size
{
    CAGradientLayer *layer = [CAGradientLayer layer];
    [layer setFrame:(CGRect){CGPointZero, size}];
    NSMutableArray *colorsCG = [[NSMutableArray alloc] init];
    for(UIColor *color in colors){
        [colorsCG addObject:(id)color.CGColor];
    }
    [layer setColors:colorsCG];
    
    if(locations != nil){
        [layer setLocations:locations];
    }
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [layer renderInContext:ctx];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

// private method

+(instancetype)imageWithColor:(UIColor *)color andSize:(CGSize)size autoScale:(BOOL)autoScale
{
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, autoScale ? 1.0 : 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
