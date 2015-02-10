//
//  SDDrawingTool.m
//  SimpleDrawing
//
//  Created by Nathanial Woolls on 10/17/12.
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

#import "SDDrawingTool.h"

@interface SDDrawingTool()

@property (weak) UIImageView *targetImageView;

@end

@implementation SDDrawingTool

//return a VC if the tool supports specific settings
//VC will be pushed into a navigation controller
- (UIViewController*)settingsViewController
{
    return nil;
}

//override to disable double-buffered drawing (e.g. for eraser)
- (BOOL)doubleBufferDrawing
{
    return YES;
}

- (SDDrawingTool*)initWithCompletion:(dispatch_block_t)completion {
    
    if (self = [super init])
    {
        self.completion = completion;
    }
    return self;
    
}

- (void)touchBegan:(UITouch*)touch inImageView:(UIImageView*)imageView withSettings:(SDToolSettings *)settings {
    
    self.targetImageView = imageView;
    self.settings = settings;
    self.firstPoint = [touch locationInView:imageView];
        
    if ([self doubleBufferDrawing]) {
        self.drawingSnapshot = nil;
        self.drawingImageView = [[UIImageView alloc] initWithFrame:imageView.bounds];
        self.drawingImageView.alpha = 1.00 - (settings.transparency / 100.00);
        [imageView addSubview:self.drawingImageView];
    } else {
        self.drawingSnapshot = imageView.image;
        self.drawingImageView = self.targetImageView;
    }
    
}

- (void)touchMoved:(UITouch*)touch {
    
    self.drawingImageView.image = self.drawingSnapshot;
    
}

- (void)touchEnded:(UITouch*)touch {
    
    self.drawingSnapshot = nil;
    
    if ([self doubleBufferDrawing]) {
        [self compositeDrawingImageView];
    }
    
    if (self.completion) {
        self.completion();
    }
    
}

- (void)setupImageContextForDrawing {
   
    UIGraphicsBeginImageContextWithOptions(self.drawingImageView.frame.size, NO, 0.0);
    [self.drawingImageView.image drawInRect:self.drawingImageView.bounds];
    
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);    
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), self.settings.lineWidth);    
    CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeNormal);
  
    CGFloat red, green, blue, alpha;
    [self.settings.primaryColor getRed:&red green:&green blue:&blue alpha:&alpha];
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), red, green, blue, alpha);
    
    [self.settings.secondaryColor getRed:&red green:&green blue:&blue alpha:&alpha];
    CGContextSetRGBFillColor(UIGraphicsGetCurrentContext(), red, green, blue, alpha);
    
}

- (void)compositeDrawingImageView {
        
    // create a new bitmap image context
    UIGraphicsBeginImageContextWithOptions(self.targetImageView.bounds.size, NO, 0.0);
    
    [self.targetImageView.image drawInRect:self.targetImageView.bounds];
    
    // drawing code comes here
    [self.drawingImageView.image drawInRect:self.drawingImageView.frame blendMode:kCGBlendModeNormal alpha:1.0 - (self.settings.transparency / 100.00)];
    
    // get a UIImage from the image context
    self.targetImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    
    // clean up drawing environment
    UIGraphicsEndImageContext();
    
    // clean up drawing image view
    [self.drawingImageView removeFromSuperview];
    self.drawingImageView = nil;
    
}

@end
