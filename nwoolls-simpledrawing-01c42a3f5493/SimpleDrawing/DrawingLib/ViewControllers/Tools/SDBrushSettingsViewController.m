//
//  SDBrushSettingsViewController.m
//  SimpleDrawing
//
//  Created by Nathanial Woolls on 11/4/12.
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

#import "SDBrushSettingsViewController.h"

@interface SDBrushSettingsViewController ()

@property (strong) NSArray *patternNames;
@property (strong) NSArray *patternImageNames;

@end

@implementation SDBrushSettingsViewController

#pragma mark - Memory management

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.patternNames = @[@"Brush #1", @"Brush #2", @"Leaf", @"Star", @"Peace Sign", @"Heart"];
    self.patternImageNames = @[@"brush1.png", @"brush2.png", @"brush3.png", @"brush4.png", @"brush5.png", @"brush6.png"];
    
    //prevent popover from resizing
    CGSize size = self.parentViewController.view.bounds.size;//CGSizeMake(320, 480); // size of view in popover
    size.height -= self.navigationController.navigationBar.bounds.size.height;
    self.contentSizeForViewInPopover = size;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    self.patternNames = nil;
    self.patternImageNames = nil;
}

#pragma mark - View life cycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //view is kept in memory by the tool - refresh when showing
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.patternNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = self.patternNames[indexPath.row];
    
    NSString *templateImageName = [[NSUserDefaults standardUserDefaults] stringForKey:@"BRUSH_PATTERN_IMAGE_NAME"];
    if (templateImageName.length == 0) {
        templateImageName = @"brush1.png";
    }
    
    if ([templateImageName isEqualToString:self.patternImageNames[indexPath.row]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [[NSUserDefaults standardUserDefaults] setObject:self.patternImageNames[indexPath.row] forKey:@"BRUSH_PATTERN_IMAGE_NAME"];
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
