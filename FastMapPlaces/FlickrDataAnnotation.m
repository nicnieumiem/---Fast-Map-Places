//
//  FlickrDataAnnotation.m
//  FastMapPlaces
//
//  Created by nicnieumiem.pl on 4/11/13.
//
//

#import "FlickrDataAnnotation.h"
#import "FlickrFetcher.h"

@implementation FlickrDataAnnotation

+(FlickrDataAnnotation *)annotationForData:(NSDictionary *)data usingTitle:(NSString *)title andSubtitle:(NSString *)subtitle usingPinPadding:(BOOL)usePadding usingThumbnail:(BOOL)useThumbnail {
    FlickrDataAnnotation *annotation = [[FlickrDataAnnotation alloc] init];
    annotation.data = data;
    annotation.title = title;
    annotation.subtitle = subtitle;
    annotation.usePinPadding = usePadding;
    annotation.useAnnotationThumbnail = useThumbnail;
    
    return annotation;
}

-(CLLocationCoordinate2D)coordinate {
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = [[self.data objectForKey:FLICKR_LATITUDE] doubleValue];
    coordinate.longitude = [[self.data objectForKey:FLICKR_LONGITUDE] doubleValue];
    return coordinate;
}


@end
