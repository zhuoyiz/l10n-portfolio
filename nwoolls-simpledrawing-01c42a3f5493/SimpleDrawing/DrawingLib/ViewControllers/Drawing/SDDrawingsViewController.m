//
//  SDViewController.m
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

#import "SDDrawingsViewController.h"
#import "iCarousel.h"
#import "UIImage+Resize.h"
#import "SDDrawingLayer.h"
#import "SDDrawingFileNames.h"

@interface SDDrawingsViewController () <iCarouselDelegate, iCarouselDataSource, SDDrawingViewControllerDelegate>

#pragma mark - IBOutlets

@property (strong, nonatomic) IBOutlet iCarousel *carousel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

#pragma mark - Properties

@property (strong) NSArray *drawings;
@property (strong) NSCache *imageCache;

@end

@implementation SDDrawingsViewController

- (void)setTitleForDrawingAtIndex:(NSInteger)index
{
    if (index == 0) {
        self.titleLabel.text = @"New Drawing";
    } else {
        int drawingIndex = index - 1;
        NSString *fullPath = self.drawings[drawingIndex];
        NSString *textPath = [[fullPath stringByDeletingPathExtension] stringByAppendingPathComponent:kSDFileTitleFile];
        NSString *drawingTitle = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:textPath] encoding:NSUTF8StringEncoding error:nil];
        if (drawingTitle) {
            self.titleLabel.text = drawingTitle;
        } else {
            self.titleLabel.text = @"Untitled Drawing";
        }
    }
}

- (BOOL)useNavigationController
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"NAVIGATE_TO_DRAW"];
}

#pragma mark - Handling drawings

- (void)populateDrawings {
    
    NSMutableArray *mutableDrawings = [[NSMutableArray alloc] init];
    
    NSString *drawingsDirectory = [self drawingsDirectory];
    
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:drawingsDirectory error:nil];
    
    for (NSString *file in files) {
        
        NSString *fullPath = [drawingsDirectory stringByAppendingPathComponent:file];
        NSString *framesFilePath = [fullPath stringByAppendingPathComponent:kSDFileLayersFile];
        if ([[NSFileManager defaultManager] fileExistsAtPath:framesFilePath]) {
            [mutableDrawings addObject:fullPath];
        }
        
    }
    
    // reverse sort the drawings by modified date
    self.drawings = [mutableDrawings sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        
        NSString *filePathA = [(NSString*)a stringByAppendingPathComponent:kSDFileLayersFile];
        NSString *filePathB = [(NSString*)b stringByAppendingPathComponent:kSDFileLayersFile];
        
        NSDate *modDateA = [self modDateForFileAtPath:filePathA];
        NSDate *modDateB = [self modDateForFileAtPath:filePathB];
        
        return [modDateB compare:modDateA];
    }];
    
    [self.carousel reloadData];
    
    [self setTitleForDrawingAtIndex:self.carousel.currentItemIndex];
    
}

- (NSDate*)modDateForFileAtPath:(NSString*)filePath {
    
    NSDictionary *properties = [[NSFileManager defaultManager]
                                attributesOfItemAtPath:filePath
                                error:nil];
    return properties[NSFileModificationDate];
    
}

//if the app crashes or is terminated with a drawing up, a folder may be left behind
//with that drawing's undo files - clean these up in a background thread
- (void)cleanupOrphanedDrawings {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSString *drawingsDirectory = [self drawingsDirectory];
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:drawingsDirectory error:nil];
        
        for (NSString *file in files) {
            
            NSString *fullPath = [drawingsDirectory stringByAppendingPathComponent:file];
            NSString *framesFilePath = [fullPath stringByAppendingPathComponent:kSDFileLayersFile];
            if (![[NSFileManager defaultManager] fileExistsAtPath:framesFilePath]) {
                [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
            }
            
        }
                
    });
    
}

#pragma mark - Directory paths

- (NSString*)drawingsDirectory {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask ,YES );
    NSString *documentsDirectory = paths[0];
    NSString *drawingsDirectory = [documentsDirectory stringByAppendingPathComponent:kSDFileDrawingsDirectory];
    
    return drawingsDirectory;
    
}

#pragma mark - Orientation support for iOS 5

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    //force portrait for iPhone and landscape for iPad
    return (((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) && ((orientation == UIInterfaceOrientationLandscapeLeft) || (orientation == UIInterfaceOrientationLandscapeRight))) ||
            ((UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) && (orientation == UIInterfaceOrientationPortrait)));
}

#pragma mark - SDDrawingViewController delegate

- (void)viewControllerDidSaveDrawing:(SDDrawingViewController *)viewController {
    
    NSString *photoFilePath = [[self drawingsDirectory]  stringByAppendingPathComponent:viewController.drawingID];
    [self.imageCache removeObjectForKey:photoFilePath];
    
    [self dismissDrawing];
    if(self.delegate)
        [self.delegate viewControllerDidSaveDrawing:viewController];
    else if(((SDDrawingsViewController *) self.parentViewController).delegate)
        [((SDDrawingsViewController *) self.parentViewController).delegate viewControllerDidSaveDrawing:viewController];
}

- (void)viewControllerDidCancelDrawing:(SDDrawingViewController *)viewController {
    
    [self dismissDrawing];
    if(self.delegate)
        [self.delegate viewControllerDidCancelDrawing:viewController];
    else if(((SDDrawingsViewController *) self.parentViewController).delegate)
        [((SDDrawingsViewController *) self.parentViewController).delegate viewControllerDidCancelDrawing:viewController];
}

- (void)viewControllerDidDeleteDrawing:(SDDrawingViewController *)viewController {
    
    [self dismissDrawing];
    if(self.delegate)
        [self.delegate viewControllerDidDeleteDrawing:viewController];
    else if(((SDDrawingsViewController *) self.parentViewController).delegate)
        [((SDDrawingsViewController *) self.parentViewController).delegate viewControllerDidDeleteDrawing:viewController];
}

- (void)dismissDrawing {
    
    //this check is to see if the current drawing is shown Modal or using a Navigation Controller
    //can't use useNavigationController as the setting may have been changed while the drawing was presented
    if (!self.presentedViewController) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - View life cycle

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    [self populateDrawings];
    
}

#pragma mark - Memory management

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.drawings = [[NSMutableArray alloc] init];
    self.imageCache = [[NSCache alloc] init];
    
    self.carousel.type = iCarouselTypeCoverFlow;
    
    [self cleanupOrphanedDrawings];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    [self.imageCache removeAllObjects];    
}

- (void)viewDidUnload {
    
    [self setCarousel:nil];
    [self setTitleLabel:nil];
    [super viewDidUnload];
    
}

#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"ShowDrawingModalSegue"] || [segue.identifier isEqualToString:@"ShowDrawingInNavSegue"]) {
        
        SDDrawingViewController* viewController = (SDDrawingViewController*)segue.destinationViewController;
        
        NSNumber* tileIndex = @0;
        if (sender && [sender isKindOfClass:[NSNumber class]]) {
            tileIndex = (NSNumber*)sender;
        }
        
        if (tileIndex.integerValue > 0) {
            int drawingIndex = tileIndex.intValue - 1;
            NSString *fullPath = self.drawings[drawingIndex];
            viewController.drawingID = [fullPath lastPathComponent];
        }
        
        viewController.delegate = self;
        viewController.customization = self.drawingViewCustomization;
        viewController.toolListCustomization = self.toolListCustomization;
        
    }
    
}

#pragma mark - iCarousel delegate & data source

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    //return the total number of items in the carousel
    return [self.drawings count] + 1;
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    
    //create new view if no view is available for recycling
    if (view == nil)
    {
        //don't do anything specific to the index within
        //this `if (view == nil) {...}` statement because the view will be
        //recycled and used with other index values later
        view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
        
        [self initializeCarouselView:view];        
    }
    
    //remember to always set any properties of your carousel item
    //views outside of the `if (view == nil) {...}` check otherwise
    //you'll get weird issues with carousel item content appearing
    //in the wrong place in the carousel
    [self populateCarouselView:view forIndex:index];
    
    return view;
}

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index;
{
    if ([self useNavigationController]) {
        [self performSegueWithIdentifier:@"ShowDrawingInNavSegue" sender:@(index)];        
    } else {
        [self performSegueWithIdentifier:@"ShowDrawingModalSegue" sender:@(index)];       
    }
}

- (void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel
{
    [self setTitleForDrawingAtIndex:self.carousel.currentItemIndex];
}

#pragma mark - iCarousel helpers

- (void)initializeCarouselView:(UIView*)view
{
    ((UIImageView *)view).image = [UIImage imageNamed:@"page.png"];
    view.contentMode = UIViewContentModeScaleAspectFill;
    
    UILabel *label = [[UILabel alloc] initWithFrame:view.bounds];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = UITextAlignmentCenter;
    label.font = [label.font fontWithSize:50];
    label.tag = 1;
    [view addSubview:label];
    
    UIImageView *previewView = [[UIImageView alloc] initWithFrame:CGRectMake(33, 33, 233, 233)];
    previewView.contentMode = UIViewContentModeScaleAspectFit;
    
    previewView.tag = 2;
    [view addSubview:previewView];
}

- (void)populateCarouselView:(UIView*)view forIndex:(int)index
{
    //get a reference to the label in the recycled view
    UILabel *label = (UILabel*)[view viewWithTag:1];
    UIImageView *previewView = (UIImageView*)[view viewWithTag:2];
    
    previewView.image = nil;
    
    if (index == 0) {
        label.text = @"New";
    } else {
        
        label.text = @"";
        
        NSString *photoDirectory = self.drawings[index - 1];
        
        //is the image already cached in the NSCache?
        UIImage *cachedImage = [self.imageCache objectForKey:photoDirectory];
        if (cachedImage) {
            
            previewView.image = cachedImage;
            
        } else {
            
            //otherwise load the image async
            CGSize targetSize = previewView.frame.size;
            
            //the get the image in the background
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                //get the UIImage
                NSString *imageFileName = [photoDirectory stringByAppendingPathComponent:kSDFileFlatDrawing];
                UIImage *image = [UIImage imageWithContentsOfFile:imageFileName];
                
                //resize the image in this thread to avoid UIImageView resizing it in the main thread
                CGSize realTargetSize = CGSizeMake(targetSize.width, targetSize.width * (image.size.height / image.size.width));
                image = [image resizedImage:realTargetSize interpolationQuality:kCGInterpolationDefault];
                
                //if we found it, then update UI
                if (image)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        previewView.image = image;
                        [self.imageCache setObject:image forKey:photoDirectory];
                        
                    });
                }
            });
            
        }
    }
}

@end
