//
//  PhotosInPlaceViewController.m
//  FastMapPlaces
//
//  Created by nicnieumiem.pl on 4/11/13.
//
//

#import "PhotosInPlaceViewController.h"
#import "FlickrFetcher.h"

@implementation PhotosInPlaceViewController

- (void)fetchPhotosInPlace:(NSDictionary *)place {
    // initialize the queue used to download from flickr
    dispatch_queue_t fetchPhotoQ = dispatch_queue_create("Flickr photo fetcher", NULL);
    [self.activityIndicator startAnimating];
    dispatch_async(fetchPhotoQ,^{
        NSArray *fetchedPhotos = [FlickrFetcher photosInPlace:self.place maxResults:MAX_PHOTOS];
        self.photos = fetchedPhotos;
        // use the main queue to prepare for segue
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self.activityIndicator stopAnimating];
        });
    });

}

- (void)viewDidLoad {
    [super viewDidLoad];
    if(self.place) {
        [self fetchPhotosInPlace:self.place];
    }
}

@end
