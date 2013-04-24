//
//  PhotoViewController.m
//  FastMapPlaces
//
//  Created by nicnieumiem.pl on 4/11/13.
//
//

#import "PhotoViewController.h"
#import "MapViewController.h"
#import "FlickrFetcher.h"
#import "FlickrDataAnnotation.h"
#import "ImageFetcher.h"

#define MIN_ZOOM 0.2
#define MAX_ZOOM 5.0
#define MAX_RECENT_PHOTOS 20

@interface PhotoViewController () <UIScrollViewDelegate, UISplitViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *downloadIndicator;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *titleBarButtonItem;
@end

@implementation PhotoViewController

- (void)storePhoto {
    BOOL found=NO,needsUpdate=NO;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *recentPhotos = [[defaults arrayForKey:DEFAULTS_RECENT_PHOTOS_KEY] mutableCopy];
    
    
    if(!recentPhotos) {
        recentPhotos = [NSMutableArray array];
    }
    
    for (NSDictionary *entry in recentPhotos) {
        if([[entry objectForKey:FLICKR_PHOTO_ID] isEqualToString:[self.photo objectForKey:FLICKR_PHOTO_ID]]) {
            found = YES;
            NSInteger entryFoundAtIndex = [recentPhotos indexOfObject:entry];
            if(entryFoundAtIndex) {
                [recentPhotos removeObjectAtIndex:entryFoundAtIndex];
                [recentPhotos insertObject:self.photo atIndex:0];
                needsUpdate = YES;
            }
            break;
        }
    }
    if(!found) {
        if([recentPhotos count] >= MAX_RECENT_PHOTOS) {
            [recentPhotos removeLastObject];
        }
        [recentPhotos insertObject:self.photo atIndex:0];
        needsUpdate = YES;
    }
    if(needsUpdate) {
        [defaults setObject:[recentPhotos copy] forKey:DEFAULTS_RECENT_PHOTOS_KEY];
        [defaults synchronize];
    }
}

-(void)updateViewWithImage:(UIImage *)image {
    [self.imageView setImage:image];
    
    self.scrollView.contentSize = self.imageView.image.size;
    self.imageView.frame = CGRectMake(0, 0, self.imageView.image.size.width, self.imageView.image.size.height);
    
    float zoomScale = self.scrollView.frame.size.width / self.imageView.frame.size.width;
    
    [self.scrollView setMinimumZoomScale:MIN_ZOOM];
    [self.scrollView setMaximumZoomScale:MAX_ZOOM];

    [self.scrollView setZoomScale:zoomScale];
}

- (void)loadPhoto {
    NSURL *photoURL = [FlickrFetcher urlForPhoto:self.photo format:FlickrPhotoFormatLarge];
    NSString *photoID = [self.photo objectForKey:FLICKR_PHOTO_ID];
    [self.downloadIndicator startAnimating];
    [ImageFetcher.sharedInstance getImageUsingURL:photoURL usingCacheForKey:[self.photo objectForKey:FLICKR_PHOTO_ID] completed:^(UIImage *image, NSData *data){
        if([photoID isEqualToString:[self.photo objectForKey:FLICKR_PHOTO_ID]]) {
            [self updateViewWithImage:image];
            [self storePhoto];
        }
        [self.downloadIndicator stopAnimating];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    // load photo
    [super viewWillAppear:animated];
    if(!self.imageView.image) {
        if(self.photo) [self loadPhoto];
    }
    if(self.title) {
        if(self.titleBarButtonItem) {
            self.titleBarButtonItem.title = self.title;
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.scrollView.delegate = self;
    if(self.splitViewController) {
        self.splitViewController.delegate = self;
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

-(void)viewWillLayoutSubviews {
    if(self.imageView.image) {
        float zoomScaleAfterOrientationChangle = self.view.bounds.size.width / self.imageView.image.size.width;
        [self.scrollView setZoomScale:zoomScaleAfterOrientationChangle];
    }    
}

-(void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)pc {
    barButtonItem.title = @"Display UI";
    NSMutableArray *toolbarItems = [self.toolbar.items mutableCopy];
    [toolbarItems insertObject:barButtonItem atIndex:0];
    self.toolbar.items = toolbarItems;
}

-(void)splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
    NSMutableArray *toolbarItems = [self.toolbar.items mutableCopy];
    [toolbarItems removeObject:barButtonItem];
    self.toolbar.items = toolbarItems;
}


@end
