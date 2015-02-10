//
//  SDLayersViewController.m
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

#import "SDLayersViewController.h"
#import "SDLayerSettingsViewController.h"

@interface SDLayersViewController () <SDLayerSettingsViewControllerDelegate>

#pragma mark - IBOutlets

@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;

@end

@implementation SDLayersViewController

@synthesize activeLayerIndex = _activeLayerIndex;

- (void)setActiveLayerIndex:(int)activeLayerIndex {
    
    _activeLayerIndex = activeLayerIndex;
    [self.delegate viewController:self didActivateLayer:self.layers[self.activeLayerIndex]];
    
}

- (int)activeLayerIndex {
    return _activeLayerIndex;
}

- (void)selectActiveLayer {
    
    if ((self.activeLayerIndex >= 0) && (self.activeLayerIndex < self.layers.count)) {
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.activeLayerIndex inSection:0] animated:NO scrollPosition:UITableViewScrollPositionBottom];
    }    
    
}

- (void)ensureActiveLayerSelected {
    
    if (!self.tableView.indexPathForSelectedRow) {
        [self selectActiveLayer];
    }
    
}

#pragma mark - IBActions

- (IBAction)addTapped:(id)sender {
    
    SDDrawingLayer *newLayer = [[SDDrawingLayer alloc] init];
    [self.layers insertObject:newLayer atIndex:0];
    
    [self.delegate viewController:self didAddLayer:newLayer];
    
    self.activeLayerIndex = 0;
    
    [self.tableView reloadData];
    
    [self selectActiveLayer];
    
}

- (IBAction)doneTapped:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:^{}];
    
}

- (IBAction)editTapped:(id)sender {
    
    [self.tableView setEditing:!self.tableView.editing animated:YES];
    
    if (self.tableView.editing) {
        self.editButton.title = @"Done";
    } else {
        self.editButton.title = @"Edit";
    }
    
}

#pragma mark - SDLayerSettingsViewController delegate

- (void)viewController:(SDLayerSettingsViewController*)viewController didChangeLayerVisibility:(BOOL)visible {
    
    viewController.layer.visible = visible;
    [self.delegate viewController:self didChangeLayerVisibility:viewController.layer];
    
}

- (void)viewController:(SDLayerSettingsViewController *)viewController didChangeLayerTransparency:(int)transparency {
    
    viewController.layer.transparency = transparency;
    [self.delegate viewController:self didChangeLayerTransparency:viewController.layer];
    
}

#pragma mark - View life cycle

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
    
}

#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"LayerSettingsSegue"]) {
        SDLayerSettingsViewController *viewController = (SDLayerSettingsViewController*)segue.destinationViewController;
        int accessoryIndex = ((NSNumber*)sender).intValue;
        viewController.layer = (SDDrawingLayer*)self.layers[accessoryIndex];
        viewController.delegate = self;
    }
    
}

#pragma mark - Memory management

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self selectActiveLayer];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.layers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"LayersCell";
    
    UITableViewCell *cell;
    if ([tableView respondsToSelector:@selector(dequeueReusableCellWithIdentifier:forIndexPath:)]) {
        // iOS 6.0+
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = ((SDDrawingLayer*)self.layers[indexPath.row]).layerName;
    
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    //this is needed to preserve cell selection when clicking Edit/Done
    [self ensureActiveLayerSelected];
    
    return self.layers.count > 1;
    
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        SDDrawingLayer *layer = self.layers[indexPath.row];
        
        [self.layers removeObjectAtIndex:indexPath.row];
        
        //call after removing row so proper undo objects are saved
        [self.delegate viewController:self didDeleteLayer:layer];
        
        [tableView reloadData];
        
        if (self.activeLayerIndex >= self.layers.count) {
            self.activeLayerIndex = self.layers.count - 1;
        } else if (indexPath.row < self.activeLayerIndex) {
            self.activeLayerIndex--;
        }
        
        if (self.layers.count == 1) {
            [tableView setEditing:NO animated:YES];
        }
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    // fetch the object at the row being moved
    SDDrawingLayer *layer = self.layers[fromIndexPath.row];
    
    // remove the original from the data structure
    [self.layers removeObjectAtIndex:fromIndexPath.row];
    
    // insert the object at the target row
    [self.layers insertObject:layer atIndex:toIndexPath.row];
    
    [self.delegate viewController:self didMoveLayer:layer toIndex:toIndexPath.row];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return YES;
    
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    self.activeLayerIndex = indexPath.row;
    
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    
    [self performSegueWithIdentifier:@"LayerSettingsSegue" sender:@(indexPath.row)];
    
}

@end