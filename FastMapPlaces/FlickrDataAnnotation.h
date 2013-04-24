//
//  FlickrDataAnnotation.h
//  FastMapPlaces
//
//  Created by nicnieumiem.pl on 4/11/13.
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface FlickrDataAnnotation : NSObject <MKAnnotation>

@property (nonatomic, strong) NSDictionary *data;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *subtitle;
@property BOOL usePinPadding;
@property BOOL useAnnotationThumbnail;

// nice factory method for creating annotations using photo, title and subtitle data
+(FlickrDataAnnotation *)annotationForData:(NSDictionary *)data usingTitle:(NSString *)title andSubtitle:(NSString *)subtitle usingPinPadding:(BOOL)usePadding usingThumbnail:(BOOL)useThumbnail;


@end
