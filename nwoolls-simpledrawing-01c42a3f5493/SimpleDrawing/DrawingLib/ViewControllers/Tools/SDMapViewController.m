//
//  SDMapViewController.m
//  SimpleDrawing
//
//  Created by Nathanial Woolls on 10/22/12.
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

#import "SDMapViewController.h"

#import "SDMapViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "SDMapAnnotation.h"
#import "MBProgressHUD.h"
#import <QuartzCore/QuartzCore.h>

@interface SDMapViewController () <UISearchBarDelegate>

#pragma mark - IBOutlets

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIToolbar *bottomToolbar;

@end

@implementation SDMapViewController

- (UIImage*)imageOfMap {
    
    UIGraphicsBeginImageContextWithOptions(((UIView*)self.mapView).frame.size, NO, 0.0);
    [self.mapView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
    
}

- (void)dismissKeyboard {
    
    for(UIView *subView in self.searchBar.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            UITextField *searchField = (UITextField *)subView;
            [searchField resignFirstResponder];
        }
    }
    
}

- (void)showErrorHUD:(NSString*)message {
    
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:hud];
    
    hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hud_error.png"]];
    
    // Set custom view mode
    hud.mode = MBProgressHUDModeCustomView;
    
    hud.labelText = message;
    hud.removeFromSuperViewOnHide = YES;
    
    [hud show:YES];
    [hud hide:YES afterDelay:2.0];
    
}

- (void)showCoordinateOnMapView:(CLLocationCoordinate2D)coordinate withAddress:(NSString*)address {
    
    SDMapAnnotation *annotation = [[SDMapAnnotation alloc] initWithCoordinate:coordinate andTitle:address];
    
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    span.latitudeDelta = 0.2;
    span.longitudeDelta = 0.2;
    
    region.span = span;
    region.center = coordinate;
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    [self.mapView addAnnotation:annotation];
    [self.mapView setRegion:region animated:TRUE];
    [self.mapView regionThatFits:region];
    
}

#pragma mark - IBActions

- (IBAction)cancelTapped:(id)sender {
    
    [self.delegate viewController:self wasDismissed:NO];
    
    [self dismissModalViewControllerAnimated:YES];
    
}

- (IBAction)doneTapped:(id)sender {
    
    [self.delegate viewController:self wasDismissed:YES];
    
    [self dismissModalViewControllerAnimated:YES];
    
}

- (IBAction)mapStyleSegmentChanged:(id)sender {
    
    UISegmentedControl *segmentedControl = (UISegmentedControl*)sender;
    
    if (segmentedControl.selectedSegmentIndex == 0) {
        self.mapView.mapType = MKMapTypeStandard;
    } else if (segmentedControl.selectedSegmentIndex == 1) {
        self.mapView.mapType = MKMapTypeSatellite;
    } else if (segmentedControl.selectedSegmentIndex == 2) {
        self.mapView.mapType = MKMapTypeHybrid;
    }
    
}

#pragma mark - Keyboard handling

//allow the kb to be dismissed even though this is a modal form
- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}

#pragma mark - UISearchBar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
    NSString *address = searchBar.text;
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    [geocoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error) {

        if (error) {            
            [self showErrorHUD:@"Not Found"];            
            return;
        }
        
        CLPlacemark *placemark = placemarks[0];                
        [self showCoordinateOnMapView:placemark.region.center withAddress:address];
        
        [self dismissKeyboard];
        
    }];
    
}

#pragma mark - Memory management

- (void)viewDidUnload {
    
    [self setMapView:nil];
    [self setSearchBar:nil];
    [self setBottomToolbar:nil];
    
    [super viewDidUnload];
    
}

@end
