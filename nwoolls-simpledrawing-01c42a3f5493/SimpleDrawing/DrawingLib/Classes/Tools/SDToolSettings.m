//
//  SDToolSettings.m
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

#import "SDToolSettings.h"

@implementation SDToolSettings

NSString* const kSDSettingsColor1RedKey      =  @"DRAWING_COLOR1_RED";
NSString* const kSDSettingsColor1BlueKey     =  @"DRAWING_COLOR1_BLUE";
NSString* const kSDSettingsColor1GreenKey    =  @"DRAWING_COLOR1_GREEN";
NSString* const kSDSettingsColor1AlphaKey    =  @"DRAWING_COLOR1_ALPHA";
NSString* const kSDSettingsColor2RedKey      =  @"DRAWING_COLOR2_RED";
NSString* const kSDSettingsColor2BlueKey     =  @"DRAWING_COLOR2_BLUE";
NSString* const kSDSettingsColor2GreenKey    =  @"DRAWING_COLOR2_GREEN";
NSString* const kSDSettingsColor2AlphaKey    =  @"DRAWING_COLOR2_ALPHA";
NSString* const kSDSettingsLineWidth         =  @"DRAWING_LINE_WIDTH";
NSString* const kSDSettingsTransparency      =  @"DRAWING_TRANSPARENCY";
NSString* const kSDSettingsDrawingTool       =  @"DRAWING_TOOL";
NSString* const kSDSettingsFontSize          =  @"DRAWING_FONT_SIZE";

- (void)loadFromUserDefaults {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults objectForKey:kSDSettingsColor1AlphaKey]) {
        self.primaryColor = [UIColor colorWithRed:[defaults floatForKey:kSDSettingsColor1RedKey] green:[defaults floatForKey:kSDSettingsColor1GreenKey] blue:[defaults floatForKey:kSDSettingsColor1BlueKey] alpha:[defaults floatForKey:kSDSettingsColor1AlphaKey]];
    } else {
        self.primaryColor = [UIColor blueColor];
    }
    
    if ([defaults objectForKey:kSDSettingsColor2AlphaKey]) {
        self.secondaryColor = [UIColor colorWithRed:[defaults floatForKey:kSDSettingsColor2RedKey] green:[defaults floatForKey:kSDSettingsColor2GreenKey] blue:[defaults floatForKey:kSDSettingsColor2BlueKey] alpha:[defaults floatForKey:kSDSettingsColor2AlphaKey]];
    } else {
        self.secondaryColor = [UIColor redColor];
    }
    
    if ([defaults objectForKey:kSDSettingsLineWidth]) {
        self.lineWidth = [defaults integerForKey:kSDSettingsLineWidth];
    } else {
        self.lineWidth = 10;
    }
    
    if ([defaults objectForKey:kSDSettingsTransparency]) {
        self.transparency = [defaults integerForKey:kSDSettingsTransparency];
    } else {
        self.transparency = 0;
    }
    
    if ([defaults objectForKey:kSDSettingsDrawingTool]) {
        self.drawingTool = [defaults stringForKey:kSDSettingsDrawingTool];
        //fix old stored setting (Brush #1, Brush #2, etc)
        if ([self.drawingTool rangeOfString:@"Brush #"].location != NSNotFound) {
            self.drawingTool = @"Brush";
        }
    } else {
        self.drawingTool = @"Pen";
    }
    
    if ([defaults objectForKey:kSDSettingsFontSize]) {
        self.fontSize = [defaults integerForKey:kSDSettingsFontSize];
    } else {
        self.fontSize = 50;
    }
    
}

- (void)saveToUserDefaults {
    
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha =0.0;
    [self.primaryColor getRed:&red green:&green blue:&blue alpha:&alpha];
    
    [defaults setFloat:red forKey:kSDSettingsColor1RedKey];
    [defaults setFloat:green forKey:kSDSettingsColor1GreenKey];
    [defaults setFloat:blue forKey:kSDSettingsColor1BlueKey];
    [defaults setFloat:alpha forKey:kSDSettingsColor1AlphaKey];
    
    [self.secondaryColor getRed:&red green:&green blue:&blue alpha:&alpha];
    
    [defaults setFloat:red forKey:kSDSettingsColor2RedKey];
    [defaults setFloat:green forKey:kSDSettingsColor2GreenKey];
    [defaults setFloat:blue forKey:kSDSettingsColor2BlueKey];
    [defaults setFloat:alpha forKey:kSDSettingsColor2AlphaKey];
    
    [defaults setInteger:self.lineWidth forKey:kSDSettingsLineWidth];
    [defaults setInteger:self.transparency forKey:kSDSettingsTransparency];
    [defaults setObject:self.drawingTool forKey:kSDSettingsDrawingTool];
    [defaults setInteger:self.fontSize forKey:kSDSettingsFontSize];
    
    [defaults synchronize];
    
}

@end
