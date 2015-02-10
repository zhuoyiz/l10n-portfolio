//
//  SDTextTool.m
//  SimpleDrawing
//
//  Created by Nathanial Woolls on 10/18/12.
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

#import "SDTextTool.h"
#import "UIAlertView+BlocksKit.h"

@interface SDTextTool()

@property (assign) CGPoint lastPoint;

@end

@implementation SDTextTool

- (void)touchEnded:(UITouch*)touch {
    
    self.lastPoint = [touch locationInView:self.drawingImageView];
    [self promptForTextToolText];    

    //don't call super touchEnded - we just prompted, aren't done yet
    
}

- (void)promptForTextToolText {
    
    UIAlertView *alertView = [UIAlertView alertViewWithTitle:@"Text Tool" message:@"Enter the text to draw."];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView setCancelButtonWithTitle:@"Cancel" handler:nil];
    [alertView addButtonWithTitle:@"Ok" handler:^{
        [self drawText:[alertView textFieldAtIndex:0].text atPoint:self.lastPoint];
    }];
    [alertView show];
    
}

- (void)initializeEmptyImage {
    
    //initialize blank image
    UIGraphicsBeginImageContextWithOptions(self.drawingImageView.bounds.size, NO, 0.0);
    [self.drawingImageView.image drawInRect:self.drawingImageView.bounds];
    self.drawingImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
}

- (void)drawText:(NSString*)textToDraw atPoint:(CGPoint)textPoint
{
    if (!self.drawingImageView.image) {
        [self initializeEmptyImage];
    }
    
    UIFont *font = [UIFont boldSystemFontOfSize:self.settings.fontSize];
    UIGraphicsBeginImageContextWithOptions(self.drawingImageView.frame.size, NO, 0.0);
        
    [self.drawingImageView.image drawInRect:self.drawingImageView.bounds];
    CGRect rect = CGRectMake(textPoint.x, textPoint.y - [textToDraw sizeWithFont:font].height, self.drawingImageView.image.size.width, self.drawingImageView.image.size.height);
    //[[self.settings.primaryColor colorWithAlphaComponent:1.0 - (self.settings.transparency / 100.00)] set];
    [self.settings.primaryColor set];//colorWithAlphaComponent:1.0 - (self.settings.transparency / 100.00)] set];
    [textToDraw drawInRect:CGRectIntegral(rect) withFont:font];
    
    self.drawingImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    self.completion();
}

//we manually call the completion in drawText
//disable double-buffering or the undo snapshot will be
//before compositing the final image
//other option is to make compositeDrawingImageView public
//and call that in drawText before completion
- (BOOL)doubleBufferDrawing
{
    return NO;
}

@end
