//
//  SDPenTool.m
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

#import "SDPenTool.h"

@interface SDPenTool()

@property (assign) CGPoint previousPoint1;
@property (assign) CGPoint previousPoint2;
@property (assign) CGMutablePathRef path;
@property (assign) CGPoint lastPoint;

@end

@implementation SDPenTool

- (void)touchBegan:(UITouch *)touch inImageView:(UIImageView *)imageView withSettings:(SDToolSettings *)settings {
    
    [super touchBegan:touch inImageView:imageView withSettings:settings];
        
    [self createPath];
    
    self.previousPoint1 = [touch previousLocationInView:self.drawingImageView];
    self.previousPoint2 = [touch previousLocationInView:self.drawingImageView];
    
    [self touchMoved:touch];
    
}

- (void)touchEnded:(UITouch *)touch {
        
    //first reset the image, we're still adjusting/drawing the curve
    self.drawingImageView.image = self.drawingSnapshot;
    
    //finish the curve along to the final touch
    [self drawCurveEndingAtTouch:touch];
    
    [self releasePath];
    
    [super touchEnded:touch];
    
}

static const CGFloat kPointMinDistance = 5;
static const CGFloat kPointMinDistanceSquared = kPointMinDistance * kPointMinDistance;

- (void)touchMoved:(UITouch *)touch {  
    
    CGPoint currentPoint = [touch locationInView:self.drawingImageView];
    
    /* check if the point is farther than min dist from previous */
    CGFloat dx = currentPoint.x - self.lastPoint.x;
    CGFloat dy = currentPoint.y - self.lastPoint.y;
    
    if (dx * dx + dy * dy < kPointMinDistanceSquared) {
        return;
    }
    
    //call touch moved after the above check - image will be restored
    [super touchMoved:touch];
            
    [self drawCurveEndingAtTouch:touch];
        
    if (self.pathDistance > 100) {
        //commit changes and recreate path, faster
        self.drawingSnapshot = self.drawingImageView.image;
        [self createPath];
    }
        
    self.lastPoint = currentPoint;
    
}

// drawing curves using quadratic beziers based on https://github.com/levinunnink/Smooth-Line-View
- (void)drawCurveEndingAtTouch:(UITouch*)touch {
    
    [self addTouchToPath:touch];
    
    [self drawCurveForPath];
    
}

- (void)addTouchToPath:(UITouch*)touch {
    
    self.previousPoint2 = self.previousPoint1;
    self.previousPoint1 = [touch previousLocationInView:self.drawingImageView];
    CGPoint currentPoint = [touch locationInView:self.drawingImageView];
    
    CGPoint mid1 = midPoint(self.previousPoint1, self.previousPoint2);
    CGPoint mid2 = midPoint(currentPoint, self.previousPoint1);
    CGMutablePathRef subpath = CGPathCreateMutable();
    CGPathMoveToPoint(subpath, NULL, mid1.x, mid1.y);
    CGPathAddQuadCurveToPoint(subpath, NULL, self.previousPoint1.x, self.previousPoint1.y, mid2.x, mid2.y);
    
    CGPathAddPath(self.path, NULL, subpath);
    
    CGFloat dx = currentPoint.x - self.lastPoint.x;
    CGFloat dy = currentPoint.y - self.lastPoint.y;
    float lastDistance = sqrt(dx * dx + dy * dy);
    self.pathDistance += lastDistance;
    
    CGPathRelease(subpath);
    
}

- (void)drawCurveForPath {
    
    [self setupImageContextForDrawing];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextAddPath(context, self.path);
    CGContextStrokePath(context);
    self.drawingImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
}

CGPoint midPoint(CGPoint p1, CGPoint p2) {
    return CGPointMake((p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5);
}

- (void)releasePath {
    
    if (_path != nil) {
        CGPathRelease(_path);
        _path = nil;
    }
    self.pathDistance = 0.0;
    
}

- (void)createPath {
    
    [self releasePath];
    
    //analyzer will report this leaks - this is released in the above method
    self.path = CGPathCreateMutable();
    self.pathDistance = 0.0;
    
}

@end
