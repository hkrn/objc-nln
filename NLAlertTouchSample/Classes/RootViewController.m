//
//  RootViewController.m
//  NLNotification
//
//  Created by hkrn on 10/10/11.
//  Copyright hkrn 2010. All rights reserved.
//

#import "RootViewController.h"

@implementation RootViewController

#pragma mark -
#pragma mark View lifecycle

- (void)toggleNetworkActivity:(BOOL)value
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = value;
}

- (void)viewDidLoad {
    if (authentication == nil)
        authentication = [[NLNAuthentication alloc] init];
    if (userLoader == nil)
        userLoader = [[NLNUserLoader alloc] init];
    if (threadConnection == nil)
        threadConnection = [[NLNThreadConnection alloc] init];
    if (streams == nil)
        streams = [[NSMutableArray alloc] init];
    lastModified = [[NSDate date] timeIntervalSince1970];
    [userLoader loadUserWithDelegate:self didFinishSelector:@selector(user:error:)];
    //[authentication authenticateWithEmail:@"test@examle.com" password:@"password" delegate:self didFinishSelector:@selector(ticket:error:)];
    [self toggleNetworkActivity:YES];
    [super viewDidLoad];
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
 */

#pragma mark -
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [streams count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    NLNStream *stream = [streams objectAtIndex:indexPath.row];
    NSData *data = [[NSData alloc] initWithContentsOfURL:stream.community.thumbnailURL];
    UIImage *image = [[UIImage alloc] initWithData:data];
    int point = 17;
    UIFont *font = [UIFont systemFontOfSize:point];
    CGSize size = [stream.title sizeWithFont:font];
    while (size.width >= 250) {
        --point;
        font = [UIFont systemFontOfSize:point];
        size = [stream.title sizeWithFont:font];
    }
    cell.imageView.image = image;
    cell.textLabel.text = stream.title;
    cell.textLabel.font = font;
    [image release];
    [data release];
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIApplication *app = [UIApplication sharedApplication];
    NLNStream *stream = [streams objectAtIndex:indexPath.row];
    NSString *url = [[NSString alloc] initWithFormat:@"nicolive://%@", stream.streamId];
    NSURL *streamURL = [[NSURL alloc] initWithString:url];
    if ([app canOpenURL:streamURL]) {
        [app openURL:streamURL];
    }
    else {
        NSURL *infoURL = [[NSURL alloc] initWithString:@"http://live.nicovideo.jp/iphone/"];
        [app openURL:infoURL];
        [infoURL release];
    }
    [streamURL release];
    [url release];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
}

#pragma mark -
#pragma mark NLN Delegate Methods

- (void)ticket:(NSString *)aTicket error:(NSError *)error
{
    if (error != nil) {
        NSLog(@"%@", [error localizedDescription]);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[error domain]
                                                        message:[error localizedDescription]
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    else {
        NSLog(@"ticket:%@", aTicket);
        [userLoader loadUserWithTicket:aTicket delegate:self didFinishSelector:@selector(user:error:)];
    }
}

- (void)user:(NLNUser *)theUser error:(NSError *)error
{
    if (error != nil) {
        NSLog(@"user:error: %@: %@", [error domain], [error localizedDescription]);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[error domain]
                                                        message:[error localizedDescription]
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    else {
        NSLog(@"id:%d hash:%@ name:%@ prefecture:%d age:%d sex:%@ premium:%d",
              theUser.userId,
              theUser.hash,
              theUser.name,
              theUser.prefecture,
              theUser.age,
              theUser.sex,
              theUser.isPremium
              );
        user = [theUser retain];
        [threadConnection connectMessageServer:user.server
                                      delegate:self
                             didFinishSelector:@selector(stream:error:)
                                  streamFilter:@selector(filterStream:community:)];
        [self toggleNetworkActivity:NO];
    }
}

- (void)stream:(NLNStream *)theStream error:(NSError *)error
{
    if (error != nil) {
        NSLog(@"stream:error: %@: %@", [error domain], [error localizedDescription]);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[error domain]
                                                        message:[error localizedDescription]
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else if (theStream != nil) {
        /*
        NSLog(@"id:%@ title:%@ provider:%@ default:%@ name:%@ description:%@ thumbnail:%@",
              theStream.streamId,
              theStream.title,
              theStream.providerType,
              theStream.defaultCommunityId,
              theStream.community.name,
              theStream.community.description,
              [theStream.community.thumbnailURL absoluteString]
              );
         */
        [streams insertObject:theStream atIndex:0];
        [self toggleNetworkActivity:NO];
        [self.tableView reloadData];
    }
}

- (id)filterStream:(NSString *)streamID community:(NSString *)communityID
{
    NSTimeInterval current = [[NSDate date] timeIntervalSince1970];
    [user isMemberOfCommunityWithId:communityID];
    if (current - lastModified >= 2) {
        lastModified = current;
        [self toggleNetworkActivity:YES];
        return [NSNumber numberWithBool:YES];
    }
    return [NSNumber numberWithBool:NO];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    NSUInteger count = [streams count];
    NSUInteger threshold = 15;
    if (count > threshold) {
        [streams removeObjectsInRange:NSMakeRange(threshold, count - threshold)];
        [self.tableView reloadData];
        NSLog(@"Removed cached objects: %d to %d", count, [streams count]);
    }
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
}

- (void)dealloc {
    [authentication release];
    [userLoader release];
    [threadConnection release];
    [user release];
    [streams release];
    [super dealloc];
}

@end

