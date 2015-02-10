//
//  FSDirectoryViewController.m
//  FileSystemView
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

#import "FSDirectoryViewController.h"
#import "FSFileViewController.h"
#import "NSString+FileSize.h"
#import "NSFileManager+DirectoryInfo.h"

@interface FSDirectoryViewController ()

#pragma mark - IBOutlets
@property (weak, nonatomic) IBOutlet UILabel *summaryLabel;

#pragma mark - Properties
@property (strong) NSArray *directoryContents;

@end

@implementation FSDirectoryViewController

- (void)initializePropertyDefaults {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask ,YES);
    
    if (self.rootPath.length == 0) {
        //initialize with a default root
        self.rootPath = paths[0];
    }
    
    if (self.startingPath.length == 0) {
        //initialize with the root path
        self.startingPath = self.rootPath;
        if (self.rootPathTitle.length > 0) {
            self.navigationItem.title = self.rootPathTitle;
        }
    }
    
}

#pragma mark - IBActions

- (IBAction)doneTapped:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (IBAction)rootDirectoryTapped:(id)sender {
    
    NSBundle *bundle = [NSBundle bundleForClass:[FSDirectoryViewController class]];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"FSFileSystemView" bundle:bundle];
    UINavigationController *navigationController = [storyboard instantiateInitialViewController];
    FSDirectoryViewController *viewController = (FSDirectoryViewController*)navigationController.topViewController;
    
    viewController.rootPath = self.rootPath;
    viewController.rootPathTitle = self.rootPathTitle;
    viewController.startingPath = self.rootPath;
    if (self.rootPathTitle.length > 0) {
        viewController.navigationItem.title = self.rootPathTitle;
    }
    
    [self.navigationController pushViewController:viewController animated:YES];
    
}

#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"DirectorySegue"]) {
        
        FSDirectoryViewController *viewController = (FSDirectoryViewController*)segue.destinationViewController;
        viewController.startingPath = [self.startingPath stringByAppendingPathComponent:self.directoryContents[[self.tableView indexPathForSelectedRow].row]];
        viewController.rootPath = self.rootPath;
        viewController.rootPathTitle = self.rootPathTitle;
        
    } else if ([segue.identifier isEqualToString:@"FileSegue"]) {
        
        FSFileViewController *viewController = (FSFileViewController*)segue.destinationViewController;
        viewController.filePath = [self.startingPath stringByAppendingPathComponent:self.directoryContents[((NSNumber*)sender).intValue]];
        
    }
    
}

#pragma mark - Memory management

- (void)viewDidLoad
{
    [super viewDidLoad];
        
	[self initializePropertyDefaults];

    [self populateDirectoryContents];
    
    if (!self.presentingViewController) {
        //no Done button in popover
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    [self populateSummaryView];
    
}

- (void)viewDidUnload {
    
    [self setSummaryLabel:nil];
    [super viewDidUnload];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.directoryContents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    NSString *filePath = [self.startingPath stringByAppendingPathComponent:self.directoryContents[indexPath.row]];    
    BOOL isDirectory = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
    
    if (isDirectory) {
        
        static NSString *CellIdentifier = @"DirectoryCell";
        
        if ([tableView respondsToSelector:@selector(dequeueReusableCellWithIdentifier:forIndexPath:)]) {
            // iOS 6.0+
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        }
        
        [self populateDirectoryCell:cell forPath:filePath];
        
    } else {
        
        static NSString *CellIdentifier = @"FileCell";
        
        if ([tableView respondsToSelector:@selector(dequeueReusableCellWithIdentifier:forIndexPath:)]) {
            // iOS 6.0+
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        }
        
        [self populateFileCell:cell forPath:filePath];
        
    }
        
    return cell;
}

#pragma mark - UITableViewController delegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    
    [self performSegueWithIdentifier:@"FileSegue" sender:@(indexPath.row)];
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Populating views

- (void)populateSummaryView {
    
    long totalSize = 0;
    long fileCount = 0;
    
    [NSFileManager subFileCount:&fileCount andSubFileSize:&totalSize forDirectory:self.startingPath];
    
    self.summaryLabel.text = [NSString stringWithFormat:@"Total: %ld files, %@", fileCount, [NSString stringWithFileSize:totalSize]];
    
}

- (void)populateDirectoryCell:(UITableViewCell*)cell forPath:(NSString*)filePath {
            
    long totalSize = 0;
    long fileCount = 0;
    
    [NSFileManager subFileCount:&fileCount andSubFileSize:&totalSize forDirectory:filePath];
    
    cell.textLabel.text = [filePath lastPathComponent];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld files, %@ total", fileCount, [NSString stringWithFileSize:totalSize]];
    
}

- (void)populateFileCell:(UITableViewCell*)cell forPath:(NSString*)filePath {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:filePath error:nil];    
    NSNumber *fileSizeNumber = fileAttributes[NSFileSize];
    long fileSize = [fileSizeNumber longLongValue];
    
    cell.textLabel.text = [filePath lastPathComponent];
    cell.detailTextLabel.text = [NSString stringWithFileSize:fileSize];
    
}

- (void)populateDirectoryContents {
    
    self.directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.startingPath error:nil];
    
}

@end
