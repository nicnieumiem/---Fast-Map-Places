//
//  PhotoViewController.h
//  FastMapPlaces
//
//  Created by nicnieumiem.pl on 4/11/13.
//
//

#import <UIKit/UIKit.h>

#define DEFAULTS_RECENT_PHOTOS_KEY @"recentPhotosArray"

@interface PhotoViewController : UIViewController

@property (nonatomic, strong) NSDictionary *photo;

@end
