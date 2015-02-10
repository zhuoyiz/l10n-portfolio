//
//  SDColorPickerViewController.m
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

#import "SDColorPickerViewController.h"
#import "RSColorPickerView.h"
#import "RSBrightnessSlider.h"

@interface SDColorPickerViewController () <RSColorPickerViewDelegate>

@property (strong) RSColorPickerView* colorPicker;
@property (strong) RSBrightnessSlider* brightnessSlider;
@property (strong) UIView *colorPatch;
@property (assign) BOOL trackChangeEvents;

@end

@implementation SDColorPickerViewController

- (void)createColorControls {
    
    self.colorPicker = [[RSColorPickerView alloc] initWithFrame:CGRectMake(10.0, 10.0, 300.0, 300.0)];
	self.colorPicker.delegate = self;
	self.colorPicker.brightness = 1.0;
	self.colorPicker.cropToCircle = NO; // Defaults to YES (and you can set BG color)
    [self.view addSubview:self.colorPicker];
    
	self.brightnessSlider = [[RSBrightnessSlider alloc] initWithFrame:CGRectMake(8.0, 320.0, 304.0, 30.0)];
	self.brightnessSlider.colorPicker = self.colorPicker;
	self.brightnessSlider.useCustomSlider = YES; // Defaults to NO
    [self.view addSubview:self.brightnessSlider];
	
    
    
}

- (void)setupControlsFromCurrentColor {
        
    self.colorPicker.selectionColor = self.color;
    self.brightnessSlider.value = self.colorPicker.brightness;
    self.colorPatch.backgroundColor = self.color;
    
}

#pragma mark - View lifecycle

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    self.color = self.colorPicker.selectionColor;
    [self.delegate viewController:self didPickColor:self.color];
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    //do in viewWillAppear so the alignment is correct
    const int patchTop = 360;
	self.colorPatch = [[UIView alloc] initWithFrame:CGRectMake(10.0, patchTop, 300.0, self.view.bounds.size.height - patchTop - 10)];
    [self.view addSubview:self.colorPatch];
    
    //don't do this in viewDidLoad, it occurs before prepareForSegue under iOS 5
    [self setupControlsFromCurrentColor];
    self.trackChangeEvents = YES;
    
}

#pragma mark - Memory management

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self createColorControls];
    
}

#pragma mark - RSColorPickerView delegate

-(void)colorPickerDidChangeSelection:(RSColorPickerView *)cp {
    
	self.colorPatch.backgroundColor = cp.selectionColor;
    if (self.trackChangeEvents) {
        self.color = cp.selectionColor;
    }
    
}

@end