//
//  SDDrawingViewController.m
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

#import "SDDrawingViewController.h"
#import "SDDrawingLayer.h"
#import "NSString+UUID.h"
#import "UIAlertView+BlocksKit.h"
#import "MBProgressHUD.h"
#import "UIActionSheet+BlocksKit.h"
#import "SDLayersViewController.h"
#import "SDToolSettingsViewController.h"
#import "SDDrawingToolsViewController.h"
#import "SDLineWidthViewController.h"
#import "SDTransparencyViewController.h"
#import "SDFontSizeViewController.h"
#import "UIImage+Tint.h"
#import "SDColorPickerViewController.h"
#import <Twitter/Twitter.h>
#import "SDRectangleStrokeTool.h"
#import "SDToolSettings.h"
#import "SDEllipseStrokeTool.h"
#import "SDLineTool.h"
#import "SDPhotoTool.h"
#import "SDEraserTool.h"
#import "SDPenTool.h"
#import "SDRectangleFillTool.h"
#import "SDEllipseFillTool.h"
#import "SDTextTool.h"
#import "FSDirectoryViewController.h"
#import "NSFileManager+DirectoryInfo.h"
#import "NSString+FileSize.h"
#import "SDDrawingFileNames.h"
#import "SDMapViewController.h"
#import "SDFillTool.h"
#import "SDBrushTool.h"

@interface SDDrawingViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, SDLayersViewControllerDelegate, SDToolSettingsViewControllerDelegate, SDDrawingToolsViewControllerDelegate, SDLineWidthViewControllerDelegate, SDTransparencyViewControllerDelegate, SDFontSizeViewControllerDelegate, SDColorPickerViewControllerDelegate, MFMailComposeViewControllerDelegate, SDMapViewControllerDelegate, UITextFieldDelegate>

#pragma mark - IBOutlets

@property (weak, nonatomic) IBOutlet UIView *layerContainerView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *drawingToolButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *importButton;
@property (weak, nonatomic) IBOutlet UIButton *color1Button;
@property (weak, nonatomic) IBOutlet UIButton *color2Button;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *folderViewButton;
@property (weak, nonatomic) IBOutlet UILabel *fileSizeLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareButton;
@property (weak, nonatomic) IBOutlet UILabel *toolTitleLabel;

#pragma mark - Properties

@property (strong) UIPopoverController *popoverController;

#pragma mark - Layers handling

@property (strong) NSMutableArray *layers;
@property (readonly, weak) UIImageView *activeImageView;
@property (assign) int activeLayerIndex;

#pragma mark - Tool settings

@property (strong) SDToolSettings *toolSettings;

#pragma mark - Undo stack

@property (assign) int undoStackLocation;
@property (assign) int undoStackCount;

#pragma mark - Tracking touch

@property (assign) CGPoint lastPoint;

#pragma mark - Drawing

@property (assign) BOOL isNewDrawing;
@property (copy) NSString* drawingTitle;

#pragma mark - Drawing tools

@property (strong) SDPhotoTool *photoTool;
@property (strong) NSMutableArray *drawingTools;

@end

@implementation SDDrawingViewController

@synthesize popoverController = __popoverViewController;

- (void)dismissCurrentPopover
{
    if (self.popoverController) {
        [self.popoverController dismissPopoverAnimated:YES];
    }
    self.popoverController = nil;
}

#pragma mark - Populating views

- (void)updateFileSizeLabel {
    
    NSString *undoFilesPath = [self undoFilesDirectory];
    NSString *drawingFilesPath = [self photoDirectory];
    
    long fileCount = 0;
    long undoFilesSize = 0;
    long drawingFilesSize = 0;
    
    [NSFileManager subFileCount:&fileCount andSubFileSize:&undoFilesSize forDirectory:undoFilesPath];      
    [NSFileManager subFileCount:&fileCount andSubFileSize:&drawingFilesSize forDirectory:drawingFilesPath];
    
    drawingFilesSize -= undoFilesSize;    
    
    self.fileSizeLabel.text = [NSString stringWithFormat:@"Drawing files: %@, Undo files: %@", [NSString stringWithFileSize:drawingFilesSize], [NSString stringWithFileSize:undoFilesSize]];
    
}

- (void)setupViewBackground {
    
    UIImage *bgImage = [UIImage imageNamed:@"transparent-checkerboard.png"];
    UIColor *color = [UIColor colorWithPatternImage:bgImage];
    self.view.backgroundColor = color;
    
}

- (void)updateDrawingToolButton
{
    SDDrawingTool *tool = [self activeTool];;
    self.drawingToolButton.image = [UIImage imageNamed:tool.imageName];
}

- (void)updateDrawingToolTitle
{
    self.toolTitleLabel.text = self.toolSettings.drawingTool;
}

- (void)updateColorButtons {
    
    [self.color1Button setImage:[UIImage imageNamed:@"color-palette-mini-white.png" withTint:self.toolSettings.primaryColor] forState:UIControlStateNormal];
    [self.color2Button setImage:[UIImage imageNamed:@"color-palette-mini-white.png" withTint:self.toolSettings.secondaryColor] forState:UIControlStateNormal];
    
}

- (void)updateFileInfoControls {
    
    BOOL showFolderViewButton = [[NSUserDefaults standardUserDefaults] boolForKey:@"FILE_SYSTEM_VIEW"];
    if (!showFolderViewButton) {
        [self removeFolderViewButton];
        self.fileSizeLabel.hidden = YES;
    }
    
}

- (void)removeFolderViewButton {
    
    NSMutableArray *newToolBarArray = [self.topToolbar.items mutableCopy];
    [newToolBarArray removeObject:self.folderViewButton];
    
    [self.topToolbar setItems:[@[newToolBarArray] objectAtIndex:0] animated:NO];
    
}

- (void)updateDrawingTitle {
    
    if (self.drawingTitle.length > 0) {
        [self.titleButton setTitle:self.drawingTitle forState:UIControlStateNormal];
    } else {
        [self.titleButton setTitle:@"Tap to add title" forState:UIControlStateNormal];
    }
    
}

#pragma mark - Orientation support for iOS 5

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    //force portrait for iPhone and landscape for iPad
    return (((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) && ((orientation == UIInterfaceOrientationLandscapeLeft) || (orientation == UIInterfaceOrientationLandscapeRight))) || (orientation == UIInterfaceOrientationPortrait));
}

#pragma mark - Drawing sharing

- (void)shareDrawingWithActivityView:(UIImage*)imageToShare {

    UIActivityViewController *viewController = [[UIActivityViewController alloc] initWithActivityItems:@[imageToShare] applicationActivities:nil];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        
        [self dismissCurrentPopover];
        self.popoverController = [[UIPopoverController alloc] initWithContentViewController:viewController];
        [self.popoverController presentPopoverFromBarButtonItem:self.shareButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        
    } else {
        
        [self presentViewController:viewController animated:YES completion:nil];
        
    }

}

// support for iOS 5 - no UIActivityViewController available
- (void)shareDrawingWithActionSheet:(UIImage*)imageToShare {    
    
    UIActionSheet *sheet = [UIActionSheet actionSheetWithTitle:@"How would you like to share the current drawing?"];
    [sheet setDestructiveButtonWithTitle:@"Send with Mail" handler:^{
        if ([MFMailComposeViewController canSendMail]) {            
            [self shareDrawingWithMail:imageToShare];            
        } else {            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                            message:@"You can't send an email right now. Make sure your device has an Internet connection and you have at least one email account setup."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }];
    
    [sheet setDestructiveButtonWithTitle:@"Share with Twitter" handler:^{
        
        if([TWTweetComposeViewController canSendTweet])
        {

        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                            message:@"You can't send a tweet right now. Make sure your device has an Internet connection and you have at least one Twitter account setup."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        
    }];
    [sheet setDestructiveButtonWithTitle:@"Save to Camera Roll" handler:^{
        
        UIImageWriteToSavedPhotosAlbum(imageToShare, nil, nil, nil);
        
    }];
    [sheet setDestructiveButtonWithTitle:@"Copy to Clipboard" handler:^{
        
        [UIPasteboard generalPasteboard].image = imageToShare;
        
    }];
    [sheet setCancelButtonWithTitle:@"Cancel" handler:nil];
    [sheet setDestructiveButtonIndex:-1];
    [sheet showInView:self.view];
    
}

- (void)shareDrawingWithTwitter:(UIImage*)imageToShare {
    
    TWTweetComposeViewController *tweetComposer = [[TWTweetComposeViewController alloc] init];
    [tweetComposer addImage:imageToShare];
    tweetComposer.completionHandler = ^(TWTweetComposeViewControllerResult result){
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    };
    [self presentViewController:tweetComposer animated:YES completion:nil];
    
}

- (void)shareDrawingWithMail:(UIImage*)imageToShare {
    
    MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
    composer.mailComposeDelegate = self;
    
    UIImage *flatImage = [self getFlattenedImageOfDrawing];
    NSData *imageData = UIImagePNGRepresentation(flatImage);
    [composer addAttachmentData:imageData mimeType:@"image/png" fileName:@"Drawing.png"];
    
    [self presentViewController:composer animated:YES completion:nil];
    
}

#pragma mark - Alerts, Sheets, HUDs

- (void)showImportPrompt {
    
    [self dismissCurrentPopover];
    
    UIActionSheet *sheet = [UIActionSheet actionSheetWithTitle:@"What would you like to import?"];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [sheet addButtonWithTitle:@"Import from Camera" handler:^{
            
            [self showCameraPrompt];
            
        }];
    }

    [sheet addButtonWithTitle:@"Import Photo" handler:^{
        
        [self showPhotoPrompt];
        
    }];
    [sheet addButtonWithTitle:@"Import Map" handler:^{
        
        [self performSegueWithIdentifier:@"MapViewSegue" sender:nil];
        
    }];
    [sheet setCancelButtonWithTitle:@"Cancel" handler:nil];
    [sheet showInView:self.view];
    
}

- (void)showPhotoPrompt {
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {        
        self.popoverController = [[UIPopoverController alloc] initWithContentViewController:imagePicker];
        [self.popoverController presentPopoverFromBarButtonItem:self.importButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
    else {
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
    
}

- (void)showCameraPrompt {
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.popoverController = [[UIPopoverController alloc] initWithContentViewController:imagePicker];
        [self.popoverController presentPopoverFromBarButtonItem:self.importButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
    else {
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
    
}

- (void)showInfoHUD:(NSString*)message {
    
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:hud];
    
    // Set custom view mode
    hud.mode = MBProgressHUDModeCustomView;
    
    hud.labelText = message;
    hud.removeFromSuperViewOnHide = YES;
    
    [hud show:YES];
    [hud hide:YES afterDelay:2.0];
    
}

#pragma mark - Directory paths

- (NSString*)drawingsDirectory {

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask ,YES);
    NSString *documentsDirectory = paths[0];
    NSString *drawingsDirectory = [documentsDirectory stringByAppendingPathComponent:kSDFileDrawingsDirectory];
    return drawingsDirectory;

}

- (NSString*)photoDirectory {
    
    NSString *photoDirectory = [[self drawingsDirectory] stringByAppendingPathComponent:self.drawingID];
    return photoDirectory;
    
}

- (NSString*)undoFilesDirectory {
    
    NSString *undoFilesDirectory = [[self photoDirectory] stringByAppendingPathComponent:@"undo"];
    return undoFilesDirectory;
    
}

#pragma mark - UITextField delegate

- (void)textFieldDidEndEditing:(UITextField*)textField {
    
    self.drawingTitle = self.titleTextField.text;
    [self updateDrawingTitle];
    self.titleTextField.hidden = YES;
    self.titleButton.hidden = NO;
    
}

//UITextField Done button
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    
    [self.titleTextField resignFirstResponder];
    return YES;
    
}

#pragma mark - IBActions

- (IBAction)titleButtonTapped:(id)sender {
    
    self.titleButton.hidden = YES;
    self.titleTextField.text = self.drawingTitle;
    self.titleTextField.hidden = NO;
    [self.titleTextField becomeFirstResponder];
    
}

- (IBAction)folderViewTapped:(id)sender {
    
    //instantiate the view controller
    NSBundle *bundle = [NSBundle bundleForClass:[FSDirectoryViewController class]];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"FSFileSystemView" bundle:bundle];
    UINavigationController *navigationController = [storyboard instantiateInitialViewController];
    FSDirectoryViewController *viewController = (FSDirectoryViewController*)navigationController.topViewController;
    
    //set properties on the view controller
    viewController.rootPath = [self drawingsDirectory];
    viewController.rootPathTitle = @"All Drawings";
    viewController.startingPath = [self photoDirectory];
    viewController.navigationItem.title = @"Drawing Contents";
    
    //present the view controller
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        
        [self dismissCurrentPopover];
        self.popoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
        [self.popoverController presentPopoverFromBarButtonItem:self.folderViewButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        
    } else {
        
        [self presentViewController:navigationController animated:YES completion:nil];
        
    }
    
}

- (IBAction)swapColorsTapped:(id)sender {
    
    UIColor* tmpColor = self.toolSettings.primaryColor;
    self.toolSettings.primaryColor = self.toolSettings.secondaryColor;
    self.toolSettings.secondaryColor = tmpColor;
    
    [self updateColorButtons];
    
}

- (IBAction)cancelDrawingTapped:(id)sender {
    
    if (self.isNewDrawing) {
        [self deleteCurrentDrawing];
    }    
    [self.delegate viewControllerDidCancelDrawing:self];
    
}

- (IBAction)deleteDrawingTapped:(id)sender {
    
    UIActionSheet *sheet = [UIActionSheet actionSheetWithTitle:@"Delete the current drawing?"];
    [sheet setDestructiveButtonWithTitle:@"Delete Drawing" handler:^{
        
        [self deleteCurrentDrawing];
        [self.delegate viewControllerDidDeleteDrawing:self];
        
    }];
    [sheet setCancelButtonWithTitle:@"Cancel" handler:nil];
    [sheet showInView:self.view];
    
}

- (IBAction)shareDrawingTapped:(id)sender {
    
    UIImage *imageToShare = [self getFlattenedImageOfDrawing];
    
    if ([UIActivityViewController class]) {
        [self shareDrawingWithActivityView:imageToShare];
    } else {
        [self shareDrawingWithActionSheet:imageToShare];        
    }
    
}

- (IBAction)saveDrawingTapped:(id)sender {
    
    [self saveCurrentDrawing];    
    [self.delegate viewControllerDidSaveDrawing:self];
    
}

- (IBAction)undoActionTapped:(id)sender {
    
    [self undoDrawingStep];
    
}

- (IBAction)redoActionTapped:(id)sender {
    
    [self redoDrawingStep];
    
}

- (IBAction)importTapped:(id)sender {
    
    [self showImportPrompt];
    
}

#pragma mark - Seugue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"ToolSettingsSegue"]) {
        
        SDToolSettingsViewController *viewController = (SDToolSettingsViewController*)((UINavigationController*)segue.destinationViewController).topViewController;
        viewController.tool = self.toolSettings.drawingTool;
        viewController.drawingTools = self.drawingTools;
        viewController.color1 = self.toolSettings.primaryColor;
        viewController.color2 = self.toolSettings.secondaryColor;
        viewController.lineWidth = self.toolSettings.lineWidth;
        viewController.transparency = self.toolSettings.transparency;
        viewController.fontSize = self.toolSettings.fontSize;
        viewController.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"LayersSegue"]) {
        
        SDLayersViewController *viewController = (SDLayersViewController*)((UINavigationController*)segue.destinationViewController).topViewController;
        viewController.layers = self.layers;
        viewController.activeLayerIndex = self.activeLayerIndex;
        viewController.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"DrawingToolsSegue"]) {
        
        SDDrawingToolsViewController *viewController = (SDDrawingToolsViewController*)((UINavigationController*)segue.destinationViewController).topViewController;
        viewController.tool = self.toolSettings.drawingTool;
        viewController.drawingTools = self.drawingTools;
        viewController.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"LineWidthSegue"]) {
        
        SDLineWidthViewController *viewController = (SDLineWidthViewController*)segue.destinationViewController;
        viewController.lineWidth = self.toolSettings.lineWidth;
        viewController.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"TransparencySegue"]) {
        
        SDTransparencyViewController *viewController = (SDTransparencyViewController*)segue.destinationViewController;
        viewController.transparency = self.toolSettings.transparency;
        viewController.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"FontSizeSegue"]) {
        
        SDFontSizeViewController *viewController = (SDFontSizeViewController*)segue.destinationViewController;
        viewController.fontSize = self.toolSettings.fontSize;
        viewController.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"ColorPickerSegue"]) {
        
        SDColorPickerViewController *viewController = (SDColorPickerViewController*)segue.destinationViewController;
        viewController.color = self.toolSettings.primaryColor;
        viewController.tag = 1;
        viewController.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"Color2PickerSegue"]) {
        
        SDColorPickerViewController *viewController = (SDColorPickerViewController*)segue.destinationViewController;
        viewController.color = self.toolSettings.secondaryColor;
        viewController.tag = 2;
        viewController.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"MapViewSegue"]) {
        SDMapViewController *viewController = (SDMapViewController*)segue.destinationViewController;
        viewController.delegate = self;
    }
    
    //save reference to popopver controller
    if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
        
        [self dismissCurrentPopover];
        self.popoverController = ((UIStoryboardPopoverSegue*)segue).popoverController;
        
    }
    
}

#pragma mark - SDMapViewController delegate

- (void)viewController:(SDMapViewController *)viewController wasDismissed:(BOOL)success {
    
    if (success) {
        self.photoTool.photo = [viewController imageOfMap];
        
        [self showInfoHUD:@"Trace a destination rectangle"];
    }
    
}

#pragma mark - MKMailComposerViewController delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

#pragma mark - SDColorPickerViewController delegate

- (void)viewController:(SDColorPickerViewController *)viewController didPickColor:(UIColor *)color {
    
    if (viewController.tag == 2) {
        self.toolSettings.secondaryColor = color;
    } else {
        self.toolSettings.primaryColor = color;
    }
    
    [self updateColorButtons];
    
}

#pragma mark - SDLineWidthViewController delegate

- (void)viewController:(SDLineWidthViewController *)viewController didPickWidth:(int)lineWidth {
    
    self.toolSettings.lineWidth = lineWidth;
    
}

#pragma mark - SDTransparencyViewController delegate

- (void)viewController:(SDTransparencyViewController *)viewController didPickTransparency:(int)transparency {
    
    self.toolSettings.transparency = transparency;
    
}

#pragma mark - SDFontSizeViewController delegate

- (void)viewController:(SDFontSizeViewController *)viewController didPickFontSize:(int)fontSize {
    
    self.toolSettings.fontSize = fontSize;
    
}

#pragma mark - SDDrawingToolsViewController delegate

- (void)viewController:(SDDrawingToolsViewController *)viewController didPickTool:(NSString *)tool
{    
    self.toolSettings.drawingTool = tool;
    
    //cancel importing photo
    self.photoTool.photo = nil;
    
    [self updateDrawingToolButton];
    [self updateDrawingToolTitle];
    
    [self dismissCurrentPopover];    
}

#pragma mark - SDToolSettingsViewController delegate

- (void)settingsViewController:(SDToolSettingsViewController*)viewController didPickTool:(NSString*)tool
{    
    self.toolSettings.drawingTool = tool;
    
    //cancel importing photo
    self.photoTool.photo = nil;
    
    [self updateDrawingToolButton];
    [self updateDrawingToolTitle];
}

- (void)settingsViewController:(SDToolSettingsViewController*)viewController didPickColor1:(UIColor*)color {
    
    self.toolSettings.primaryColor = color;

}

- (void)settingsViewController:(SDToolSettingsViewController*)viewController didPickColor2:(UIColor*)color {
    
    self.toolSettings.secondaryColor = color;

}

- (void)settingsViewController:(SDToolSettingsViewController*)viewController didPickWidth:(int)lineWidth {
    
    self.toolSettings.lineWidth = lineWidth;
    
}

- (void)settingsViewController:(SDToolSettingsViewController*)viewController didPickTransparency:(int)transparency {
    
    self.toolSettings.transparency = transparency;
    
}

- (void)settingsViewController:(SDToolSettingsViewController*)viewController didPickFontSize:(int)fontSize {
    
    self.toolSettings.fontSize = fontSize;
    
}

#pragma mark - SDLayersViewController delegate

- (void)viewController:(SDLayersViewController*)viewController didRenameLayer:(SDDrawingLayer*)layer {
        
}

- (void)viewController:(SDLayersViewController*)viewController didDeleteLayer:(SDDrawingLayer*)layer {
    
    [layer.imageView removeFromSuperview];
    
    [self addDrawingToUndoStack];
    
}

- (void)viewController:(SDLayersViewController*)viewController didMoveLayer:(SDDrawingLayer*)layer toIndex:(int)index {
    
    //index in from the end ot the subviews - subview order is oposite of list order
    [self.layerContainerView insertSubview:layer.imageView atIndex:self.layerContainerView.subviews.count - 1 - index];
    
}

- (void)viewController:(SDLayersViewController*)viewController didAddLayer:(SDDrawingLayer*)layer {
        
    [self initializeNewLayer:layer];    
    self.activeLayerIndex = self.layers.count - 1;
    
    //add to undo stack so undoing a drawing op doesn't also undo the new layer
    [self addDrawingToUndoStack];
    
}

- (void)viewController:(SDLayersViewController*)viewController didActivateLayer:(SDDrawingLayer*)layer {
    
    self.activeLayerIndex = [self.layers indexOfObject:layer];
    
}

- (void)viewController:(SDLayersViewController*)viewController didChangeLayerVisibility:(SDDrawingLayer*)layer {
    
    [self setupLayerVisibility:layer];
    
}

- (void)viewController:(SDLayersViewController*)viewController didChangeLayerTransparency:(SDDrawingLayer*)layer {
    
    [self setupLayerVisibility:layer];
    
}

#pragma mark - UIImagePickerController delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
        
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self dismissCurrentPopover];
    }
    else {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }    
    
    UIAlertView *alert = [UIAlertView alertViewWithTitle:@"Import" message:@"How would you like to import the photo?"];
    [alert addButtonWithTitle:@"Full Size" handler:^{
        
        self.activeImageView.image = info[UIImagePickerControllerOriginalImage];
        [self addDrawingToUndoStack];
        
    }];
    [alert addButtonWithTitle:@"Trace Size" handler:^{
        
        self.photoTool.photo = info[UIImagePickerControllerOriginalImage];
        
        [self showInfoHUD:@"Trace a destination rectangle"];
        
    }];
    [alert show];
    
}

#pragma mark - File handling - Load / Save / Delete drawings

- (void)initializeDrawing {
    
    if (!self.drawingID) {
        
        [self initializeNewDrawing];
        
    } else {
        [self loadDrawingFromID];
    }
    
    [self addDrawingToUndoStack];
    
    [self updateDrawingTitle];
    
}

- (void)initializeNewDrawing {
    
    self.drawingID = [NSString UUIDString];
    self.isNewDrawing = YES;
    [self addNewLayer];
    
}

- (void)loadDrawingFromID {
    
    NSString *photoDirectory = [self photoDirectory];
    
    [self loadDrawingLayers:photoDirectory];
    [self loadDrawingTitle:photoDirectory];
    
}

- (void)loadDrawingLayers:(NSString*)photoDirectory {
    
    NSString *layersFileName = [photoDirectory stringByAppendingPathComponent:kSDFileLayersFile];
    
    self.layers = [[NSKeyedUnarchiver unarchiveObjectWithFile:layersFileName] mutableCopy];
    
    [self.layerContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    //iterate backward, setupImageViewForLayer will add at an inverted z-order
    for (int i = self.layers.count - 1; i >= 0; i--) {
        
        SDDrawingLayer *layer = self.layers[i];
        
        [self setupImageViewForLayer:layer];
        [self setupLayerVisibility:layer];
        
        NSString *layerImageName = [[photoDirectory stringByAppendingPathComponent:layer.layerID] stringByAppendingPathExtension:@"png"];
        
        //don't load with UIImage directly, causes an error saving as we move these files
        layer.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfFile:layerImageName]];
        
    }
    
}

- (void)loadDrawingTitle:(NSString*)photoDirectory {
    
    NSString *textFilePath = [photoDirectory stringByAppendingPathComponent:kSDFileTitleFile];
    self.drawingTitle = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:textFilePath] encoding:NSUTF8StringEncoding error:nil];
    
}

- (void)saveCurrentDrawing {
    
    [self saveDrawingToDirectory:[self photoDirectory] saveFlatCopy:YES];
    
}

- (void)saveDrawingToDirectory:(NSString*)photoDirectory saveFlatCopy:(BOOL)saveFlatCopy {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    //backup the current drawing files
    NSString *backupPhotoDirectory = [NSString stringWithFormat:@"%@_bak", photoDirectory];
    [fileManager moveItemAtPath:photoDirectory toPath:backupPhotoDirectory error:nil];
    
    [fileManager createDirectoryAtPath:photoDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    
    [self saveDrawingLayers:photoDirectory];
    [self saveDrawingTitle:photoDirectory];
    
    if (saveFlatCopy) {
        [self saveFlatDrawing:[photoDirectory stringByAppendingPathComponent:kSDFileFlatDrawing]];
    }
    
    //delete the backup drawing files now that drawing is saved
    [fileManager removeItemAtPath:backupPhotoDirectory error:nil];
    
}

- (void)saveFlatDrawing:(NSString*)photoFileName {
    
    UIImage *flatImage = [self getFlattenedImageOfDrawing];
    
    NSData *photoData = UIImagePNGRepresentation(flatImage);
    [photoData writeToFile:photoFileName atomically:YES];
    
}

- (UIImage*)getFlattenedImageOfDrawing {
    
    // create a new bitmap image context
    UIGraphicsBeginImageContextWithOptions(self.layerContainerView.bounds.size, NO, 0.0);
                
    // reversed as the z-order of the layer image views is the reverse of the layers array order
    for (int i = self.layers.count - 1; i >= 0; i--) {
        SDDrawingLayer *layer = (SDDrawingLayer*)self.layers[i];
        if (layer.visible) {
            [layer.imageView.image drawInRect:layer.imageView.bounds blendMode:kCGBlendModeNormal alpha:1.0 - (layer.transparency / 100.0)];
        }
    }
        
    // get a UIImage from the image context
    UIImage *flatImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // clean up drawing environment
    UIGraphicsEndImageContext();
    
    return flatImage;
    
}

- (void)saveDrawingLayers:(NSString*)photoDirectory {
    
    NSString *layersFileName = [photoDirectory stringByAppendingPathComponent:kSDFileLayersFile];
    
    [NSKeyedArchiver archiveRootObject:self.layers toFile:layersFileName];
    
    for (SDDrawingLayer* layer in self.layers) {
        
        NSString *layerImageName = [[photoDirectory stringByAppendingPathComponent:layer.layerID] stringByAppendingPathExtension:@"png"];
        NSData *photoData = UIImagePNGRepresentation(layer.imageView.image);
        [photoData writeToFile:layerImageName atomically:YES];
        
    }
    
}

- (void)saveDrawingTitle:(NSString*)photoDirectory {
    
    NSString *textFilePath = [photoDirectory stringByAppendingPathComponent:kSDFileTitleFile];
    [self.drawingTitle writeToFile:textFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
}

- (void)deleteCurrentDrawing {
        
    [[NSFileManager defaultManager] removeItemAtPath:[self photoDirectory] error:nil];
    
}

#pragma mark - Touch handling

- (BOOL)shouldTrackTouch:(UITouch*)touch {
    
    //don't track when showing map view
    if (self.presentedViewController) {
        return NO;
    }
    
    CGPoint touchLocation = [touch locationInView:self.layerContainerView];
    if ((touchLocation.y < 0) || (touchLocation.y > self.layerContainerView.frame.size.height)) {
        return NO;
    }
    
    return YES;
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    //do not respond to touch if the title UITextField is visible
    if (self.titleTextField && !self.titleTextField.hidden) {
        return;
    }    
    
    UITouch *touch = [touches anyObject];
    
    if (![self shouldTrackTouch:touch]) {
        return;
    }    
    
    if ([self tracingPhotoDestination]) {
        
        [self.photoTool touchBegan:touch inImageView:self.activeImageView withSettings:self.toolSettings];
        
    } else {
        
        SDDrawingTool *drawingTool = [self activeTool];
        if (drawingTool) {
            [drawingTool touchBegan:touch inImageView:self.activeImageView withSettings:self.toolSettings];
        }
        
    }
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    //do not respond to touch if the title UITextField is visible
    if (self.titleTextField && !self.titleTextField.hidden) {
        return;
    }
    
    UITouch *touch = [touches anyObject];
    
    if (![self shouldTrackTouch:touch]) {
        return;
    }
    	
    if ([self tracingPhotoDestination]) {
        
        [self.photoTool touchMoved:touch];
        
    } else  {
        
        SDDrawingTool *drawingTool = [self activeTool];
        if (drawingTool) {
            [drawingTool touchMoved:touch];
        }
        
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    //do not respond to touch if the title UITextField is visible
    if (self.titleTextField && !self.titleTextField.hidden) {
        //resign first responder status for title UITextField
        [self.titleTextField resignFirstResponder];
        return;
    }    
    
    UITouch *touch = [touches anyObject];
    
    if (![self shouldTrackTouch:touch]) {
        return;
    }
    
    if ([self tracingPhotoDestination]) {
                
        [self.photoTool touchEnded:touch];   
        
    } else {
        
        SDDrawingTool *drawingTool = [self activeTool];
        if (drawingTool) {
            
            [drawingTool touchEnded:touch];    
            
        }
        
    }
    
}

#pragma mark - Undo stack

// add the current drawing to the undo stack
- (void)addDrawingToUndoStack {
    
    NSString *undoFilesDirectory = [self undoFilesDirectory];
    NSString *undoFileDirectory = [undoFilesDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", ++self.undoStackLocation]];
        
    self.undoStackCount = self.undoStackLocation + 1;
       
    /* this could be improved by getting copies of the current layers and current
     layer images in local variables and then passing those into a refactored
     save method in the block below
     with the current code, on slower devices, drawing operations that happen in
     quick succession may be undone in one step 
     
     use background priority so this has the least impact on drawing operations*/
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        //this will run on a background thread
        [[NSFileManager defaultManager] createDirectoryAtPath:undoFileDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
        
        [self saveDrawingToDirectory:undoFileDirectory saveFlatCopy:NO];
        
        //dispatch async to keep UI responsive
        dispatch_async(dispatch_get_main_queue(), ^{
            //this will run on the main thread
            [self updateFileSizeLabel];
        });
        
    });
    
}

// load the image for the current undo stack position
- (BOOL)loadImageFromUndoStack {
    
    NSString *undoFilesDirectory = [self undoFilesDirectory];
    NSString *undoFileDirectory = [undoFilesDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", self.undoStackLocation]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:undoFileDirectory]) {
        [self loadDrawingLayers:undoFileDirectory];
        self.activeLayerIndex = 0;
        return YES;
    } else {
        return NO;
    }
    
}

- (void)undoDrawingStep {
    
    if (self.undoStackLocation > 0) {
        self.undoStackLocation--;
        
        if (self.isNewDrawing && (self.undoStackLocation == 0)) {
            //if this is a new drawing and we've undone to location 0, clear the image
            //we don't have a 0.png as we started with an empty drawing
            self.activeImageView.image = nil;
        } else if (![self loadImageFromUndoStack]) {
            //rever to old location if there was no undo image
            self.undoStackLocation++;
        }
    }
    
}

- (void)redoDrawingStep {
    
    if (self.undoStackLocation < self.undoStackCount - 1) {
        self.undoStackLocation++;
        
        if (![self loadImageFromUndoStack]) {
            //rever to old location if there was no undo image
            self.undoStackLocation--;
        }
    }
    
}

- (void)resetUndoStack {
    
    [self deletePersistedUndoCopies];
    self.undoStackLocation = -1;
    self.undoStackCount = 0;
    
}

// clear the undo stack contents persisted to file
- (void)deletePersistedUndoCopies {
    
    NSString *undoFilesDirectory = [self undoFilesDirectory];
    
    [[NSFileManager defaultManager] removeItemAtPath:undoFilesDirectory error:nil];
    
}

#pragma mark - Tools handling

- (BOOL)tracingPhotoDestination {
    return (self.photoTool.photo != nil);
}

- (SDDrawingTool*)activeTool {
    
    for (SDDrawingTool *tool in self.drawingTools) {
        if ([tool.toolName isEqualToString:self.toolSettings.drawingTool]) {
            return tool;
        }
    }
    
    return nil;
    
}

- (void)initializeTools {
    
    
    self.drawingTools = [[NSMutableArray alloc] init];
    
    //pen tool
    SDDrawingTool *tool = [[SDPenTool alloc] initWithCompletion:^{
        
        [self addDrawingToUndoStack];
        
    }];
    tool.toolName = @"Pen";
    tool.imageName = @"pen-ink-mini.png";
    [self.drawingTools addObject:tool];
    
    //brush tool
    tool = [[SDBrushTool alloc] initWithCompletion:^{
        
        [self addDrawingToUndoStack];
        
    }];
    tool.toolName = @"Brush";
    tool.imageName = @"paint-brush-mini.png";
    [self.drawingTools addObject:tool];
    
    //line tool
    tool = [[SDLineTool alloc] initWithCompletion:^{
        
        [self addDrawingToUndoStack];
        
    }];
    tool.toolName = @"Line";
    tool.imageName = @"ruler-triangle-mini.png";
    [self.drawingTools addObject:tool];
    
    //text tool
    tool = [[SDTextTool alloc] initWithCompletion:^{
        
        [self addDrawingToUndoStack];
        
    }];
    tool.toolName = @"Text";
    tool.imageName = @"text-capital-mini.png";
    [self.drawingTools addObject:tool];
    
    //rectangle stroke tool
    tool = [[SDRectangleStrokeTool alloc] initWithCompletion:^{
        
        [self addDrawingToUndoStack];
        
    }];
    tool.toolName = @"Rectangle (stroke)";
    tool.imageName = @"multiple-mini.png";
    [self.drawingTools addObject:tool];
    
    //rectangle fill tool
    tool = [[SDRectangleFillTool alloc] initWithCompletion:^{
        
        [self addDrawingToUndoStack];
        
    }];
    tool.toolName = @"Rectangle (fill)";
    tool.imageName = @"multiple-mini.png";
    [self.drawingTools addObject:tool];
    
    //ellipse stroke tool
    tool = [[SDEllipseStrokeTool alloc] initWithCompletion:^{
        
        [self addDrawingToUndoStack];
        
    }];
    tool.toolName = @"Ellipse (stroke)";
    tool.imageName = @"circle-mini.png";
    [self.drawingTools addObject:tool];
    
    //ellipse fill tool
    tool = [[SDEllipseFillTool alloc] initWithCompletion:^{
        
        [self addDrawingToUndoStack];
        
    }];
    tool.toolName = @"Ellipse (fill)";
    tool.imageName = @"circle-mini.png";
    [self.drawingTools addObject:tool];
    
    //fill tool
    tool = [[SDFillTool alloc] initWithCompletion:^{
        
        [self addDrawingToUndoStack];
        
    }];
    tool.toolName = @"Fill (bucket)";
    tool.imageName = @"paint-mini.png";
    [self.drawingTools addObject:tool];
    
    //eraser tool
    tool = [[SDEraserTool alloc] initWithCompletion:^{
        
        [self addDrawingToUndoStack];
        
    }];
    tool.toolName = @"Eraser";
    tool.imageName = @"eraser-mini.png";
    [self.drawingTools addObject:tool];    
    
    //photo tool
    self.photoTool = [[SDPhotoTool alloc] initWithCompletion:^{
        
        [self addDrawingToUndoStack];
        
    }];
    
    if (self.toolListCustomization) {
        self.toolListCustomization(self.drawingTools);
    }
    
}

#pragma mark - Layer handling

- (UIImageView*)activeImageView {
    
    return ((SDDrawingLayer*)self.layers[self.activeLayerIndex]).imageView;
    
}

- (void)addNewLayer {
    
    SDDrawingLayer *newLayer = [[SDDrawingLayer alloc] init];
    [self.layers addObject:newLayer];
    
    [self initializeNewLayer:newLayer];
    
    self.activeLayerIndex = self.layers.count - 1;
    
}

- (void)initializeNewLayer:(SDDrawingLayer*)layer {
    
    layer.layerID = [NSString UUIDString];
    layer.layerName = [NSString stringWithFormat:@"Layer #%d", self.layers.count];
    layer.visible = YES;
    
    [self setupImageViewForLayer:layer];
    
}

- (void)setupImageViewForLayer:(SDDrawingLayer*)layer {
    
    UIImageView *layerView = [[UIImageView alloc] initWithFrame:self.layerContainerView.bounds];
    //absolutely necessary - layer may be added in viewDidLoad before frames are final
    layerView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    //add subview rather than inserting - newly added layers are in front
    [self.layerContainerView addSubview:layerView];
    layer.imageView = layerView;
    
}

- (void)setupLayerVisibility:(SDDrawingLayer*)layer {
    
    if (layer.visible) {
        layer.imageView.hidden = NO;
    } else {
        layer.imageView.hidden = YES;
    }
    
    layer.imageView.alpha = 1.0 - (layer.transparency / 100.00);
    
}

- (void)initializeLayers {
    
    self.layers = [[NSMutableArray alloc] init];
    
}

#pragma mark - View life cycle

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    [self dismissCurrentPopover];
    
    [self.toolSettings saveToUserDefaults];
    
}

#pragma mark - Memory management

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initializeLayers];
    
    [self resetUndoStack];
    
    self.toolSettings = [[SDToolSettings alloc] init];
    [self.toolSettings loadFromUserDefaults];
    
    [self updateColorButtons];
    
    [self setupViewBackground];
    
    [self initializeDrawing];
    
    [self initializeTools];
    
    [self updateDrawingToolButton];
    [self updateDrawingToolTitle];
    
    [self updateFileInfoControls];
    
    //additional customization of the view via a block
    if (self.customization) {
        self.customization(self);
    }
    
}

- (void)viewDidUnload {
    [self setLayerContainerView:nil];
    [self setFileSizeLabel:nil];
    [self setTopToolbar:nil];
    [self setTitleTextField:nil];
    [self setTitleButton:nil];
    [self setShareButton:nil];
    [self setBottomToolbar:nil];
    [self setToolTitleLabel:nil];
    [super viewDidUnload];
}

@end
