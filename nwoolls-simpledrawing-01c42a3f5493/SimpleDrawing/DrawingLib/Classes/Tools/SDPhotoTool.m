//
//  SDPhotoTool.m
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

#import "SDPhotoTool.h"

@implementation SDPhotoTool

- (void)touchMoved:(UITouch*)touch {
    
    [super touchMoved:touch];
    
    CGPoint currentPoint = [touch locationInView:self.drawingImageView];
    [self drawPhotoFromPoint:self.firstPoint toPoint:currentPoint];
    
}

- (void)touchEnded:(UITouch *)touch {
    
    self.photo = nil;
    
    [super touchEnded:touch];
    
}

- (void)drawPhotoFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint {
    
    [self setupImageContextForDrawing];
    
    CGRect drawRect = CGRectMake(fromPoint.x, fromPoint.y, toPoint.x - fromPoint.x, toPoint.y - fromPoint.y);
    
    //adjust orientation
    if (drawRect.size.height < 0) {
        drawRect.origin.y += drawRect.size.height;
        drawRect.size.height = -drawRect.size.height;
    }
    if (drawRect.size.width < 0) {
        drawRect.origin.x += drawRect.size.width;
        drawRect.size.width = -drawRect.size.width;
    }
    
    //use alpha of 1.0 - compositing will apply transparency
    [self.photo drawInRect:drawRect blendMode:kCGBlendModeNormal alpha:1.0];
    
    self.drawingImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
}

@end
