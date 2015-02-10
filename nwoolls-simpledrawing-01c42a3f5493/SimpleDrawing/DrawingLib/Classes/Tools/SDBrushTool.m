//
//  SDBrushTool.m
//  SimpleDrawing
//
//  Created by Nathanial Woolls on 11/4/12.
//  Copyright (c) 2012 Nathanial Woolls. All rights reserved.
//

// This code is distributed under the terms and conditions of the MIT license.

// Copyright (c) 2012 Nathanial Woolls
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "SDBrushTool.h"
#import "UIImage+Tint.h"
#import "UIImage+Resize.h"
#import "SDBrushSettingsViewController.h"

@interface SDBrushTool ()

@property (strong) UIImage* template;
@property (strong) SDBrushSettingsViewController *settingsController;

@end

@implementation SDBrushTool

//return a VC if the tool supports specific settings
//VC will be pushed into a navigation controller
- (UIViewController*)settingsViewController
{
    if (!self.settingsController) {
        self.settingsController = [[SDBrushSettingsViewController alloc] initWithNibName:@"SDBrushSettingsViewController" bundle:nil];
    }
    return self.settingsController;
}

- (void)touchBegan:(UITouch *)touch inImageView:(UIImageView *)imageView withSettings:(SDToolSettings *)settings
{
    [super touchBegan:touch inImageView:imageView withSettings:settings];
    
    NSString *templateImageName = [[NSUserDefaults standardUserDefaults] stringForKey:@"BRUSH_PATTERN_IMAGE_NAME"];
    if (templateImageName.length == 0) {
        templateImageName = @"brush1.png";
    }
    
    self.template = [[UIImage imageNamed:templateImageName withTint:self.settings.primaryColor] resizedImage:CGSizeMake(self.settings.lineWidth, self.settings.lineWidth) interpolationQuality:kCGInterpolationDefault];
}

- (void)touchMoved:(UITouch *)touch
{
    [super touchMoved:touch];
    
    CGPoint currentPoint = [touch locationInView:self.drawingImageView];
    [self drawTemplateAtPoint:currentPoint];
}

//necessary or you can't "tap" to make a single stroke/stamp
- (void)touchEnded:(UITouch *)touch
{
    CGPoint currentPoint = [touch locationInView:self.drawingImageView];
    [self drawTemplateAtPoint:currentPoint];
    
    [super touchEnded:touch];
}

- (void)drawTemplateAtPoint:(CGPoint)currentPoint
{
    [self setupImageContextForDrawing];
    
    CGFloat offset = self.settings.lineWidth / 2.0;
    
    CGRect drawRect = CGRectMake(currentPoint.x - offset, currentPoint.y - offset, self.settings.lineWidth, self.settings.lineWidth);
    
    //use alpha of 1.0 - compositing will apply transparency
    [self.template drawInRect:drawRect blendMode:kCGBlendModeNormal alpha:1.0];
    
    self.drawingImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //commit changes
    self.drawingSnapshot = self.drawingImageView.image;
}

@end
