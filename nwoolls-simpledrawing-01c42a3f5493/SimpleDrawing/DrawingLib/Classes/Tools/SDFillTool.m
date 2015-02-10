//
//  SDFillTool.m
//  SimpleDrawing
//
//  Created by Nathanial Woolls on 11/3/12.
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

#import "SDFillTool.h"
#import "FloodFill.h"
#import "MBProgressHUD.h"

@implementation SDFillTool

- (void)touchEnded:(UITouch*)touch
{
    if (!self.drawingImageView.image) {
        [self initializeEmptyImage];
        //fill entire area, faster than a flood fill esp on retina
        [self fillRectangleFromPoint:CGPointMake(0, 0) toPoint:CGPointMake(self.drawingImageView.bounds.size.width, self.drawingImageView.bounds.size.height)];
        
        [super touchEnded:touch];
    } else {
        
        [MBProgressHUD showHUDAddedTo:self.drawingImageView animated:YES];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *filledImage = [self floodFillAtPoint:[touch locationInView:self.drawingImageView]];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.drawingImageView.image = filledImage;
                [MBProgressHUD hideHUDForView:self.drawingImageView animated:YES];
                
                [super touchEnded:touch];
            });
        });    
        
    }
}

//override to disable double-buffered drawing (e.g. for eraser)
- (BOOL)doubleBufferDrawing
{    
    return NO;
}

- (UIImage*)floodFillAtPoint:(CGPoint)fillCenter
{        
    unsigned char *rawData = [self rawDataFromImage:self.drawingImageView.image];
    
    color fromColor = [FloodFill getColorForX:fillCenter.x Y:fillCenter.y fromImage:rawData imageWidth:self.drawingImageView.image.size.width];
    int fromColorInt = [self mkcolorI:fromColor.red G:fromColor.green B:fromColor.blue A:fromColor.alpha];
    
    CGFloat r, g, b, a;
    [self.settings.primaryColor getRed: &r green:&g blue:&b alpha:&a];
    CGFloat alpha = 255.0 * ((100.0 - self.settings.transparency) / 100.0);
    int toColorInt = [self mkcolorI:r*255 G:g*255 B:b*255 A:alpha];
    
    [FloodFill floodfillX:fillCenter.x Y:fillCenter.y image:rawData width:self.drawingImageView.image.size.width height:self.drawingImageView.image.size.height origIntColor:fromColorInt replacementIntColor:toColorInt];
    
    UIImage *filledImage = [self imageFromRawData:rawData];
    
	free(rawData);
    
	return filledImage;
}

- (void)initializeEmptyImage
{    
    //initialize blank image
    UIGraphicsBeginImageContextWithOptions(self.drawingImageView.bounds.size, NO, 0.0);
    [self.drawingImageView.image drawInRect:self.drawingImageView.bounds];
    self.drawingImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

- (UIImage*)imageFromRawData:(unsigned char*)rawData
{
    NSUInteger bitsPerComponent = 8;
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * self.drawingImageView.image.size.width;
    CGImageRef imageRef = [self.drawingImageView.image CGImage];
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    
	CGContextRef context = CGBitmapContextCreate(rawData,
                                                 self.drawingImageView.image.size.width,
                                                 self.drawingImageView.image.size.height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast);
	
	imageRef = CGBitmapContextCreateImage (context);
	UIImage* rawImage = [UIImage imageWithCGImage:imageRef];
	
	CGContextRelease(context);
		
    CGImageRelease(imageRef);
    
    return rawImage;
}

- (unsigned char*)rawDataFromImage:(UIImage*)image
{
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = malloc(height * width * 4);
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
												 bitsPerComponent, bytesPerRow, colorSpace,
												 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
	
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    return rawData;
}

// creates color int from RGBA
- (int)mkcolorI:(int)red G:(int)green B:(int)blue A:(int)alpha {
    int x = 0;
    x |= (red & 0xff) << 24;
    x |= (green & 0xff) << 16;
    x |= (blue & 0xff) << 8;
    x |= (alpha & 0xff);
    return x;
}

- (void)fillRectangleFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint
{
    [self setupImageContextForDrawing];
    
    CGFloat red, green, blue, alpha;
    [self.settings.primaryColor getRed:&red green:&green blue:&blue alpha:&alpha];
    CGContextSetRGBFillColor(UIGraphicsGetCurrentContext(), red, green, blue, alpha);
    
    CGRect rectToFill = CGRectMake(fromPoint.x, fromPoint.y, toPoint.x - fromPoint.x, toPoint.y - fromPoint.y);    
    CGContextFillRect(UIGraphicsGetCurrentContext(), rectToFill);
        
    self.drawingImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

@end
