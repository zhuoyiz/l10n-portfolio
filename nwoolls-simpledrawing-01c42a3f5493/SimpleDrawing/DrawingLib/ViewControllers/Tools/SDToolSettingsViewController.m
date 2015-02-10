//
//  SDToolSettingsViewController.m
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

#import "SDToolSettingsViewController.h"
#import "SDDrawingToolsViewController.h"
#import "SDColorPickerViewController.h"
#import "SDLineWidthViewController.h"
#import "SDTransparencyViewController.h"
#import "SDFontSizeViewController.h"

@interface SDToolSettingsViewController () <SDDrawingToolsViewControllerDelegate, SDColorPickerViewControllerDelegate, SDLineWidthViewControllerDelegate, SDTransparencyViewControllerDelegate, SDFontSizeViewControllerDelegate>

#pragma mark - IBOutlets

@property (weak, nonatomic) IBOutlet UITableViewCell *toolCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *swapCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *lineWidthCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *transparencyCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *fontSizeCell;
@property (weak, nonatomic) IBOutlet UIView *color1View;
@property (weak, nonatomic) IBOutlet UIView *color2View;


@end

@implementation SDToolSettingsViewController

- (void)swapColors {
    
    UIColor *tmpColor = self.color1;
    self.color1 = self.color2;
    self.color2 = tmpColor;
    
    [self populateView];
    
    [self.delegate settingsViewController:self didPickColor1:self.color1];
    [self.delegate settingsViewController:self didPickColor2:self.color2];
    
}

- (void)populateView {
    
    self.toolCell.detailTextLabel.text = self.tool;
    self.color1View.backgroundColor = self.color1;
    self.color2View.backgroundColor = self.color2;
    self.lineWidthCell.detailTextLabel.text = [NSString stringWithFormat:@"%d pixels", self.lineWidth];
    self.transparencyCell.detailTextLabel.text = [NSString stringWithFormat:@"%d percent", self.transparency];
    self.fontSizeCell.detailTextLabel.text = [NSString stringWithFormat:@"%d points", self.fontSize];
    
}

#pragma mark - IBActions

- (IBAction)doneTapped:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];

}

#pragma mark - SDDrawingToolsViewController delegate

- (void)viewController:(SDDrawingToolsViewController *)viewController didPickTool:(NSString *)tool {
    
    self.tool = tool;
    [self.delegate settingsViewController:self didPickTool:tool];
    [self populateView];
    [self.navigationController popViewControllerAnimated:YES];
    
}

#pragma mark - SDColorPickerViewController delegate

- (void)viewController:(SDColorPickerViewController *)viewController didPickColor:(UIColor *)color {
    
    if (viewController.tag == 2) {
        self.color2 = color;
        [self.delegate settingsViewController:self didPickColor2:color];
    } else {
        self.color1 = color;
        [self.delegate settingsViewController:self didPickColor1:color];
    }
    
    [self populateView];

}

#pragma mark - SDLineWidthViewController delegate

- (void)viewController:(SDLineWidthViewController *)viewController didPickWidth:(int)lineWidth {
    
    self.lineWidth = lineWidth;
    [self.delegate settingsViewController:self didPickWidth:lineWidth];
    [self populateView];
    
}

#pragma mark - SDTransparencyViewController delegate

- (void)viewController:(SDTransparencyViewController *)viewController didPickTransparency:(int)transparency {
    
    self.transparency = transparency;
    [self.delegate settingsViewController:self didPickTransparency:transparency];
    [self populateView];
    
}

#pragma mark - SDFontSizeViewController delegate

- (void)viewController:(SDFontSizeViewController *)viewController didPickFontSize:(int)fontSize {
    
    self.fontSize = fontSize;
    [self.delegate settingsViewController:self didPickFontSize:fontSize];
    [self populateView];
    
}

#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"DrawingToolsSegue"]) {
        SDDrawingToolsViewController *viewController = (SDDrawingToolsViewController*)segue.destinationViewController;
        viewController.drawingTools = self.drawingTools;
        viewController.delegate = self;
    } else if ([segue.identifier isEqualToString:@"ColorPickerSegue"]) {
        SDColorPickerViewController *viewController = (SDColorPickerViewController*)segue.destinationViewController;
        viewController.color = self.color1;
        viewController.tag = 1;
        viewController.delegate = self;
    } else if ([segue.identifier isEqualToString:@"Color2PickerSegue"]) {
        SDColorPickerViewController *viewController = (SDColorPickerViewController*)segue.destinationViewController;
        viewController.color = self.color2;
        viewController.tag = 2;
        viewController.delegate = self;
    } else if ([segue.identifier isEqualToString:@"LineWidthSegue"]) {
        SDLineWidthViewController *viewController = (SDLineWidthViewController*)segue.destinationViewController;
        viewController.lineWidth = self.lineWidth;
        viewController.delegate = self;
    } else if ([segue.identifier isEqualToString:@"TransparencySegue"]) {
        SDTransparencyViewController *viewController = (SDTransparencyViewController*)segue.destinationViewController;
        viewController.transparency = self.transparency;
        viewController.delegate = self;
    } else if ([segue.identifier isEqualToString:@"FontSizeSegue"]) {
        SDFontSizeViewController *viewController = (SDFontSizeViewController*)segue.destinationViewController;
        viewController.fontSize = self.fontSize;
        viewController.delegate = self;
    }
    
}

#pragma mark - Memory management

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self populateView];  
    
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([tableView cellForRowAtIndexPath:indexPath] == self.swapCell) {
        [self swapColors];
    }
    
}

@end
