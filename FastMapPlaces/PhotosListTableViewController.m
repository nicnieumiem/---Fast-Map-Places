//
//  PhotosListTableViewController.m
//  FastMapPlaces
//
//  Created by nicnieumiem.pl on 4/11/13.
//  
//

#import "PhotosListTableViewController.h"
#import "FlickrDataAnnotation.h"
#import "FlickrFetcher.h"
#import "ImageFetcher.h"
#import "PhotoViewController.h"
#import "MapViewController.h"

@interface PhotosListTableViewController ()

@end

@implementation PhotosListTableViewController

-(NSString *)getTitle:(NSDictionary *)photo {
    NSString *title = [photo objectForKey:FLICKR_PHOTO_TITLE];
    NSString *subtitle = [self getSubtitle:photo];
    return [title isEqualToString:@""] ? (!subtitle || [subtitle isEqualToString:@""] ? @"Unknown" : subtitle): title;
}

-(NSString *)getSubtitle:(NSDictionary *)photo {
    NSString *subtitle = [photo valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];
    return subtitle;
}

-(void)getThumbnailForCell:(UITableViewCell *)cell usingPhotoData:(NSDictionary *)photo {
    NSURL *thumbnailUrl = [FlickrFetcher urlForPhoto:photo format:FlickrPhotoFormatSquare];
    [ImageFetcher.sharedInstance getImageUsingURL:thumbnailUrl completed:^(UIImage *image, NSData *data){
        if(!cell.imageView) {
            return;
        }
        if(image) {
            cell.imageView.image = image;
            [cell setNeedsLayout];
        }
    }];
}

#pragma mark - prepare annotations for map view - <MKAnnotation> elements
-(NSArray *)mapAnnotations {
    NSMutableArray *annotations = [[NSMutableArray alloc] initWithCapacity:[self.photos count]];
    for(NSDictionary *photo in self.photos) {
        [annotations addObject:[FlickrDataAnnotation annotationForData:photo usingTitle:[self getTitle:photo] andSubtitle:[self getSubtitle:photo] usingPinPadding:YES usingThumbnail:YES]];
    }
    return annotations;
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.photos count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Photo Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Photo Cell"];
    }
    NSDictionary *photo = [self.photos objectAtIndex:indexPath.row];
    cell.textLabel.text = [self getTitle:photo];
    cell.detailTextLabel.text = [self getSubtitle:photo];
    
    if(cell.imageView.image) cell.imageView.image = nil;
    
    [self getThumbnailForCell:cell usingPhotoData:photo];
    
    return cell;
}

- (void)setPhotos:(NSArray *)photos {
    if(_photos != photos) {
        _photos = photos;
    }
    [self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([[segue destinationViewController] respondsToSelector:@selector(setPhoto:)]) {
        NSIndexPath *path = [self.tableView indexPathForSelectedRow];
        NSDictionary *photo = [self.photos objectAtIndex:path.row];
        [segue.destinationViewController setTitle:[self getTitle:photo]];
        [segue.destinationViewController setPhoto:photo];
    }
    else if([[segue destinationViewController] respondsToSelector:@selector(setAnnotations:)]) {
        if(self.photos) {
            [[segue destinationViewController] setAnnotations:[self mapAnnotations]];
        }
        [[segue destinationViewController] setActivityIndicator:self.activityIndicator];
    }
}


@end
