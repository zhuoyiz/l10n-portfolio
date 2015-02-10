//
//  SDToolSettingsViewController.h
//  SimpleDrawing
//
//  Created by Nathanial Woolls on 10/15/12.
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

#import <UIKit/UIKit.h>

@class SDToolSettingsViewController;

@protocol SDToolSettingsViewControllerDelegate <NSObject>

- (void)settingsViewController:(SDToolSettingsViewController*)viewController didPickTool:(NSString*)tool;
- (void)settingsViewController:(SDToolSettingsViewController*)viewController didPickColor1:(UIColor*)color;
- (void)settingsViewController:(SDToolSettingsViewController*)viewController didPickColor2:(UIColor*)color;
- (void)settingsViewController:(SDToolSettingsViewController*)viewController didPickWidth:(int)lineWidth;
- (void)settingsViewController:(SDToolSettingsViewController*)viewController didPickTransparency:(int)transparency;
- (void)settingsViewController:(SDToolSettingsViewController*)viewController didPickFontSize:(int)fontSize;

@end

@interface SDToolSettingsViewController : UITableViewController

@property (assign) id<SDToolSettingsViewControllerDelegate> delegate;
@property (copy) NSString *tool;
@property (weak) NSMutableArray *drawingTools;
@property (weak) UIColor *color1;
@property (weak) UIColor *color2;
@property (assign) int lineWidth;
@property (assign) int transparency;
@property (assign) int fontSize;

@end
