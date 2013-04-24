//
//  RecentPhotosTableViewController.m
//  FastMapPlaces
//
//  Created by nicnieumiem.pl on 4/12/13.
//
//

#import "RecentPhotosTableViewController.h"
#import "PhotoViewController.h"

@interface RecentPhotosTableViewController ()

@end

@implementation RecentPhotosTableViewController

- (NSArray *)getDefaultsPhotoData {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:DEFAULTS_RECENT_PHOTOS_KEY];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.title = @"Recent photos";
    self.photos = [self getDefaultsPhotoData];
}

@end
