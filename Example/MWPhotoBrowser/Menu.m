//
//  Menu.m
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 21/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <Photos/Photos.h>
#import "Menu.h"
#import "SDImageCache.h"
#import "MWCommon.h"

@implementation Menu

#pragma mark -
#pragma mark Initialization

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
		self.title = @"MWPhotoBrowser";
        
        // Clear cache for testing
        [[SDImageCache sharedImageCache] clearDiskOnCompletion:nil];
        [[SDImageCache sharedImageCache] clearMemory];
        [[NSFileManager defaultManager]
         removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"MWLivePhotos"]
         error:nil];
        
        _segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Push", @"Modal", nil]];
        _segmentedControl.selectedSegmentIndex = 0;
        [_segmentedControl addTarget:self action:@selector(segmentChange) forControlEvents:UIControlEventValueChanged];
        
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:_segmentedControl];
        self.navigationItem.rightBarButtonItem = item;
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
        
    }
    return self;
}

- (void)segmentChange {
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark View

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	// Create
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    cell.accessoryType = _segmentedControl.selectedSegmentIndex == 0 ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;

    // Configure
	switch (indexPath.row) {
		case 0: {
            cell.textLabel.text = @"Single photo";
            cell.detailTextLabel.text = @"with caption";
            break;
        }
		case 1: {
            cell.textLabel.text = @"Multiple photos and video";
            cell.detailTextLabel.text = @"with captions";
            break;
        }
		case 2: {
            cell.textLabel.text = @"Web photos";
            cell.detailTextLabel.text = @"photos from web";
            break;
        }
        case 3: {
            cell.textLabel.text = @"Single video";
            cell.detailTextLabel.text = @"with auto-play";
            break;
        }
        case 4: {
            cell.textLabel.text = @"Web videos";
            cell.detailTextLabel.text = @"videos from web";
            break;
        }
		case 5: {
            cell.textLabel.text = @"Live Photos";
            cell.detailTextLabel.text = @"with preview and icon";
            break;
        }
		default: break;
	}
    return cell;
	
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	// Browser
	NSMutableArray *photos = [[NSMutableArray alloc] init];
    MWPhoto *photo;
    BOOL displayActionButton = YES;
    BOOL displayNavArrows = NO;
    BOOL autoPlayOnAppear = NO;
	switch (indexPath.row) {
        case 0: {
            // Single Photo
            photo = [MWPhoto photoWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"photo2" ofType:@"jpg"]]];
            photo.caption = @"The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England.";
			[photos addObject:photo];
			break;
        }
		case 1: {
            // Local Photos and Videos
            photo = [MWPhoto photoWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"photo5" ofType:@"jpg"]]];
            photo.caption = @"Fireworks";
			[photos addObject:photo];
            photo = [MWPhoto photoWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"photo2" ofType:@"jpg"]]];
            photo.caption = @"The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England.";
			[photos addObject:photo];
            photo = [MWPhoto photoWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"photo3" ofType:@"jpg"]]];
            photo.caption = @"York Floods";
            [photos addObject:photo];
            photo = [MWPhoto photoWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"video_thumb" ofType:@"jpg"]]];
            photo.videoURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"]];
            photo.caption = @"Big Buck Bunny";
            [photos addObject:photo];
            photo = [MWPhoto photoWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"photo4" ofType:@"jpg"]]];
            photo.caption = @"Campervan";
			[photos addObject:photo];
			break;
        }
        case 2: {
            // Web Photos
			[photos addObject:[MWPhoto photoWithURL:[NSURL URLWithString:@"http://farm4.static.flickr.com/3567/3523321514_371d9ac42f_b.jpg"]]];
			[photos addObject:[MWPhoto photoWithURL:[NSURL URLWithString:@"http://farm4.static.flickr.com/3629/3339128908_7aecabc34b_b.jpg"]]];
			[photos addObject:[MWPhoto photoWithURL:[NSURL URLWithString:@"http://farm4.static.flickr.com/3364/3338617424_7ff836d55f_b.jpg"]]];
			[photos addObject:[MWPhoto photoWithURL:[NSURL URLWithString:@"http://farm4.static.flickr.com/3590/3329114220_5fbc5bc92b_b.jpg"]]];
			[photos addObject:[MWPhoto photoWithURL:[NSURL URLWithString:@"http://farm3.static.flickr.com/2449/4052876281_6e068ac860_b.jpg"]]];

            // Options
			break;
        }
        case 3: {
            
            // Single video
            photo = [MWPhoto photoWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"video_thumb" ofType:@"jpg"]]];
            photo.videoURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"]];
            [photos addObject:photo];
            autoPlayOnAppear = YES;
            break;
            
        }
		case 4: {
            
            // Web Videos
            
            photo = [MWPhoto photoWithURL:[[NSURL alloc] initWithString:@"https://scontent.cdninstagram.com/hphotos-xpt1/t51.2885-15/e15/11192696_824079697688618_1761661_n.jpg"]];
            photo.videoURL = [[NSURL alloc] initWithString:@"https://scontent.cdninstagram.com/hphotos-xpa1/t50.2886-16/11200303_1440130956287424_1714699187_n.mp4"];
            [photos addObject:photo];

            photo = [MWPhoto photoWithURL:[[NSURL alloc] initWithString:@"https://scontent.cdninstagram.com/hphotos-xaf1/t51.2885-15/e15/11240463_963135443745570_1519872157_n.jpg"]];
            photo.videoURL = [[NSURL alloc] initWithString:@"https://scontent.cdninstagram.com/hphotos-xfa1/t50.2886-16/11237510_945154435524423_2137519922_n.mp4"];
            [photos addObject:photo];
            
            photo = [MWPhoto photoWithURL:[[NSURL alloc] initWithString:@"https://scontent.cdninstagram.com/hphotos-xaf1/t51.2885-15/e15/11313531_1625089227727682_169403963_n.jpg"]];
            photo.videoURL = [[NSURL alloc] initWithString:@"https://scontent.cdninstagram.com/hphotos-xfa1/t50.2886-16/11336249_1783839318509644_116225363_n.mp4"];
            [photos addObject:photo];
            break;
        }
		case 5: {
            
            // Add a Live Photo
            
            NSURL *movieURL = [NSURL URLWithString:
                               @"http://s3.amazonaws.com/kekanto_pics/live_pics/18/18.mov"];
            NSURL *imageURL = [NSURL URLWithString:
                               @"http://s3.amazonaws.com/kekanto_pics/live_pics/18/18.jpg"];
            photo = [MWPhoto photoWithLivePhotoImageURL:imageURL movieURL:movieURL];
            photo.caption = @"A cool live photo";
            [photos addObject:photo];
            
            // Photos
            photo = [MWPhoto photoWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"photo5" ofType:@"jpg"]]];
            photo.caption = @"White Tower";
            [photos addObject:photo];
            photo = [MWPhoto photoWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"photo2" ofType:@"jpg"]]];
            photo.caption = @"The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England.";
            [photos addObject:photo];
            photo = [MWPhoto photoWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"photo3" ofType:@"jpg"]]];
            photo.caption = @"York Floods";
            [photos addObject:photo];
            photo = [MWPhoto photoWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"photo4" ofType:@"jpg"]]];
            photo.caption = @"Campervan";
            [photos addObject:photo];

            // Options
            displayNavArrows = YES;
            break;
        }
		default: break;
	}
    self.photos = photos;
	
	// Create browser
	MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    browser.displayActionButton = displayActionButton;
    browser.displayNavArrows = displayNavArrows;
    browser.zoomPhotosToFill = YES;
    browser.enableSwipeToDismiss = NO;
    browser.autoPlayOnAppear = autoPlayOnAppear;
    [browser setCurrentPhotoIndex:0];
    
    // Show
    if (_segmentedControl.selectedSegmentIndex == 0) {
        // Push
        [self.navigationController pushViewController:browser animated:YES];
    } else {
        // Modal
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:browser];
        nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentViewController:nc animated:YES completion:nil];
    }
    
    // Release
	
	// Deselect
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return _photos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _photos.count)
        return [_photos objectAtIndex:index];
    return nil;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    NSLog(@"Did start viewing photo at index %lu", (unsigned long)index);
}

- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    // If we subscribe to this method we must dismiss the view controller ourselves
    NSLog(@"Did finish modal presentation");
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end

