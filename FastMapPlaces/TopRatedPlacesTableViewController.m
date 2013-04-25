//
//  TopRatedPlacesTableViewController.m
//  FastMapPlaces
//
//  Created by nicnieumiem.pl on 4/10/13.
//
//

#import "TopRatedPlacesTableViewController.h"
#import "FlickrFetcher.h"
#import "FlickrDataAnnotation.h"
#import "PhotosInPlaceViewController.h"
#import "MapViewController.h"

@interface TopRatedPlacesTableViewController ()

@property (nonatomic,strong) NSDictionary *sectionData;
@property (nonatomic,strong) NSArray *sectionHeaders;
// activity indicator during Flickr fetching operations
@property (nonatomic,strong) UIActivityIndicatorView *tabBarActivityIndicator;

@end

@implementation TopRatedPlacesTableViewController

-(UIActivityIndicatorView *)tabBarActivityIndicator {
    if(!_tabBarActivityIndicator) {
        _tabBarActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        // activity indicator should rotate above the first item in UITabBar
        // skipping object at index 0 (which is _UITabBarBackgroundView)
        UIView *topRatedBarButtonItemView = [self.tabBarController.tabBar.subviews objectAtIndex:1];
        // get first item frame
        CGRect topRatedBarButtonItemFrame = topRatedBarButtonItemView.frame;
        _tabBarActivityIndicator.frame = CGRectMake(topRatedBarButtonItemFrame.origin.x, topRatedBarButtonItemFrame.origin.y, _tabBarActivityIndicator.frame.size.width, _tabBarActivityIndicator.frame.size.height);
        
        [self.tabBarController.tabBar addSubview:_tabBarActivityIndicator];
    }
    return _tabBarActivityIndicator;
}

-(void)startReloadButtonIndicator {
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [indicator startAnimating];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:indicator];
}

-(void)stopReloadButtonIndicator:(id)sender {
    if(sender) {
        self.navigationItem.leftBarButtonItem = sender;
    } else {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Reload" style:UIBarButtonItemStyleBordered target:self action:@selector(reload:)];
    }
}

- (IBAction)reload:(id)sender {
    // start indicators
    [self.tabBarActivityIndicator startAnimating];
    [self startReloadButtonIndicator];
    
    dispatch_queue_t reloadQ = dispatch_queue_create("Flickr reloader", NULL);
    dispatch_async(reloadQ, ^{
        [self fetchTopPlaces];
        [self prepareSectionData];
            
        // use main queue for UI operations
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self.tabBarActivityIndicator stopAnimating];
            [self stopReloadButtonIndicator:sender];
        });
    });
}

-(NSString *)getCity:(NSString *)placeDescription {
    NSRange firstComma = [placeDescription rangeOfString:@","];
    return [placeDescription substringToIndex:firstComma.location];
}

-(NSString *)getRegion:(NSString *)placeDescription {
    NSString *subtitle = nil;
    NSRange firstComma = [placeDescription rangeOfString:@","];
    NSRange nextComma = [[placeDescription substringFromIndex:firstComma.location + 2] rangeOfString:@","];
    if(nextComma.location != NSNotFound) {
        // region
        subtitle = [NSString stringWithFormat:@"%@", [[placeDescription substringFromIndex:firstComma.location + 2] substringToIndex:nextComma.location]];
    }
    else {
        return @"";
    }
    return subtitle;
}

-(NSString *)getCountry:(NSString *)placeDescription {
    NSRange lastComma = [placeDescription rangeOfString:@"," options:NSBackwardsSearch];
    return [placeDescription substringFromIndex:lastComma.location + 2];
}

- (void)fetchTopPlaces {
    // create sorted array of place descriptions
    NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:FLICKR_PLACE_NAME ascending:YES selector:(@selector(caseInsensitiveCompare:))]];
    
    self.places = [[FlickrFetcher topPlaces] sortedArrayUsingDescriptors:sortDescriptors];
}

-(void)prepareSectionData {
    NSMutableDictionary *photosByCountry = [NSMutableDictionary dictionary];
    for(NSDictionary *place in self.places) {
        NSString *country = [self getCountry:[place objectForKey:FLICKR_PLACE_NAME]];
        NSMutableArray *places = [photosByCountry objectForKey:country];
        if(!places) {
            places = [NSMutableArray array];
            [photosByCountry setObject:places forKey:country];
        }
        [places addObject:place];
    }
    // sorting countries
    self.sectionHeaders = [[photosByCountry allKeys] sortedArrayUsingSelector:@selector(compare:)];
    self.sectionData = photosByCountry;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Top places";
    
    // Animate the activity indicators
    [self startReloadButtonIndicator];
    [self.tabBarActivityIndicator startAnimating];
    
    
    // move Flickr data fetching off the main thread (non-blocking UI)
    dispatch_queue_t fetchQ = dispatch_queue_create("Flickr fetcher", NULL);
    
    // Use the fetch queue to asynchronously get the list of Top Places
    dispatch_async(fetchQ, ^{
        [self fetchTopPlaces];
        [self prepareSectionData];
        
        // all the UI-related operations should be performed on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self.tabBarActivityIndicator stopAnimating];
            [self stopReloadButtonIndicator:nil];
        });
    });
    
    self.clearsSelectionOnViewWillAppear = NO;
}

#pragma mark - prepare annotations for map view - <MKAnnotation> elements
-(NSArray *)mapAnnotations {
    NSMutableArray *annotations = [[NSMutableArray alloc] initWithCapacity:[self.places count]];
    for(NSDictionary *place in self.places) {
        NSString *placeDescription = [place objectForKey:FLICKR_PLACE_NAME];
        [annotations addObject:[FlickrDataAnnotation annotationForData:place usingTitle:[self getCity:placeDescription] andSubtitle:[[self getRegion:placeDescription] stringByAppendingFormat:@", %@", [self getCountry:placeDescription]] usingPinPadding:NO usingThumbnail:NO]];
    }
    return annotations;
}

#pragma mark - segues management
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([[segue destinationViewController] respondsToSelector:@selector(setPlace:)]) {
        // PhotoListTableViewController subclass
        NSIndexPath *path = [self.tableView indexPathForSelectedRow];
        NSArray *places = [self.sectionData objectForKey:[self.sectionHeaders objectAtIndex:path.section]];
        NSDictionary *place = [places objectAtIndex:path.row];
        [[segue destinationViewController] setPlace:place];
        [[segue destinationViewController] setActivityIndicator:self.tabBarActivityIndicator];
        [[segue destinationViewController] setTitle:[self getCity:[place objectForKey:FLICKR_PLACE_NAME]]];
    }
    else if([[segue destinationViewController] respondsToSelector:@selector(setAnnotations:)]) {
        // MapViewController
        if(self.places) {
            [[segue destinationViewController] setAnnotations:[self mapAnnotations]];
        }
        [[segue destinationViewController] setActivityIndicator:self.tabBarActivityIndicator];
    }
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.sectionData count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.sectionData objectForKey:[self.sectionHeaders objectAtIndex:section]] count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.sectionHeaders objectAtIndex:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Top Rated Places";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Top Rated Places"];
    }
    
    NSInteger section = indexPath.section;
    NSDictionary *placeData = [[self.sectionData objectForKey:[self.sectionHeaders objectAtIndex:section]] objectAtIndex:indexPath.row];
    
    // get cell title (city name) and subtitle (region or empty string)
    NSString *placeDescription = [placeData objectForKey:FLICKR_PLACE_NAME];
    cell.textLabel.text = [self getCity:placeDescription];
    cell.detailTextLabel.text = [self getRegion:placeDescription];
    return cell;
}



@end
