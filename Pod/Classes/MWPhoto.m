//
//  MWPhoto.m
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 17/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <SDWebImage/SDWebImageManager.h>
#import <SDWebImage/SDWebImageOperation.h>
#import "MWPhoto.h"
#import "MWPhotoBrowser.h"
#import "MWLivePhotoManager.h"

@interface MWPhoto () {

    BOOL _loadingInProgress;
    id <SDWebImageOperation> _webImageOperation;
        
}

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSURL *photoURL;
@property (nonatomic) CGSize assetTargetSize;

// Live photos management
@property (nonatomic) PHLivePhoto *livePhoto;
@property (nonatomic) NSURL *livePhotoImageWebURL;
@property (nonatomic) NSURL *livePhotoMovieWebURL;

- (void)imageLoadingComplete;

@end

@implementation MWPhoto

//--------------------------------------------------------------------------------------------------
#pragma mark - Class Methods

+ (MWPhoto *)photoWithImage:(UIImage *)image {
	return [[MWPhoto alloc] initWithImage:image];
}

+ (MWPhoto *)photoWithURL:(NSURL *)url {
    return [[MWPhoto alloc] initWithURL:url];
}

+ (MWPhoto *)videoWithURL:(NSURL *)url {
    return [[MWPhoto alloc] initWithVideoURL:url];
}

+ (MWPhoto *)photoWithLivePhotoImageURL:(NSURL *)imageURL movieURL:(NSURL *)movieURL {
    return [[MWPhoto alloc] initWithLivePhotoImageURL:imageURL movieURL:movieURL];
}

//--------------------------------------------------------------------------------------------------
#pragma mark - Init

- (id)init {
    if ((self = [super init])) {
        self.emptyImage = YES;
    }
    return self;
}

- (id)initWithImage:(UIImage *)image {
    if ((self = [super init])) {
        self.image = image;
    }
    return self;
}

- (id)initWithURL:(NSURL *)url {
    if ((self = [super init])) {
        self.photoURL = url;
    }
    return self;
}

- (id)initWithVideoURL:(NSURL *)url {
    if ((self = [super init])) {
        self.videoURL = url;
        self.isVideo = YES;
        self.emptyImage = YES;
    }
    return self;
}

- (id)initWithLivePhotoImageURL:(NSURL *)imageURL movieURL:(NSURL *)movieURL {
    if (self = [super init]) {
        self.isLivePhoto = YES;
        self.livePhotoImageWebURL = imageURL;
        self.livePhotoMovieWebURL = movieURL;
    }
    return self;
}

//--------------------------------------------------------------------------------------------------
#pragma mark - Video

- (void)setVideoURL:(NSURL *)videoURL {
    _videoURL = videoURL;
    self.isVideo = YES;
}

- (void)getVideoURL:(void (^)(NSURL *url))completion {
    if (_videoURL) {
        completion(_videoURL);
    }
    return completion(nil);
}

//--------------------------------------------------------------------------------------------------
#pragma mark - MWPhoto Protocol Methods

- (void)loadUnderlyingImageAndNotify {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    if (_loadingInProgress) return;
    _loadingInProgress = YES;
    @try {
        if (self.underlyingImage) {
            [self imageLoadingComplete];
        } else {
            [self performLoadUnderlyingImageAndNotify];
        }
    }
    @catch (NSException *exception) {
        self.underlyingImage = nil;
        _loadingInProgress = NO;
        [self imageLoadingComplete];
    }
    @finally {
    }
}

// Set the underlyingImage
- (void)performLoadUnderlyingImageAndNotify {
    
    // Get underlying image
    if (_image) {
        
        // We have UIImage!
        self.underlyingImage = _image;
        [self imageLoadingComplete];
        
    } else if (_photoURL) {

        // Check what type of url it is
        if ([_photoURL isFileReferenceURL]) {
            
            // Load from local file async
            [self _performLoadUnderlyingImageAndNotifyWithLocalFileURL: _photoURL];
            
        } else {
            
            // Load async from web (using SDWebImage)
            [self _performLoadUnderlyingImageAndNotifyWithWebURL: _photoURL];
            
        }
    
    } else {
        
        // Image is empty
        [self imageLoadingComplete];
        
    }
}

//--------------------------------------------------------------------------------------------------
#pragma mark - MWPhoto protocol methods for Live Photos

- (void)loadUnderlyingLivePhotoAndNotify {
    
    BOOL isMainThread = [[NSThread currentThread] isMainThread];
    NSAssert(isMainThread, @"This method must be called on the main thread.");
    
    if (_loadingInProgress) {
        return;
    }
    
    _loadingInProgress = YES;
    
    @try {
        if (self.underlyingLivePhoto) {
            [self livePhotoLoadingComplete];
        } else {
            [self performLoadUnderlyingLivePhotoAndNotify];
        }
    }
    @catch (NSException *exception) {
        self.underlyingLivePhoto = nil;
        _loadingInProgress = NO;
        [self livePhotoLoadingComplete];
    }
    @finally {
        
    }
}

- (void)performLoadUnderlyingLivePhotoAndNotify {
    if (self.livePhoto) {
        self.underlyingLivePhoto = self.livePhoto;
        [self livePhotoLoadingComplete];
    } else if (self.livePhotoImageWebURL && self.livePhotoMovieWebURL) {
        [self
         _performLoadUnderlyingLivePhotoAndNotifyWithImageURL:self.livePhotoImageWebURL
         movieURL:self.livePhotoMovieWebURL];
    }
}

//--------------------------------------------------------------------------------------------------
#pragma mark - Utils

// Load from local file
- (void)_performLoadUnderlyingImageAndNotifyWithWebURL:(NSURL *)url {
    @try {
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        
        _webImageOperation = [manager loadImageWithURL:url options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {

            if (expectedSize > 0) {
                float progress = receivedSize / (float)expectedSize;
                NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithFloat:progress], @"progress",
                                      self, @"photo", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:MWPHOTO_PROGRESS_NOTIFICATION object:dict];
            }
        } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {

            if (error) {
                MWLog(@"SDWebImage failed to download image: %@", error);
            }
            self->_webImageOperation = nil;
            self.underlyingImage = image;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self imageLoadingComplete];
            });
        }];
    } @catch (NSException *e) {
        MWLog(@"Photo from web: %@", e);
        _webImageOperation = nil;
        [self imageLoadingComplete];
    }
}

// Load from local file
- (void)_performLoadUnderlyingImageAndNotifyWithLocalFileURL:(NSURL *)url {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            @try {
                self.underlyingImage = [UIImage imageWithContentsOfFile:url.path];
                if (!self->_underlyingImage) {
                    MWLog(@"Error loading photo from path: %@", url.path);
                }
            } @finally {
                [self performSelectorOnMainThread:@selector(imageLoadingComplete) withObject:nil waitUntilDone:NO];
            }
        }
    });
}

- (void)_performLoadUnderlyingLivePhotoAndNotifyWithImageURL:(NSURL *)imageURL movieURL:(NSURL *)movieURL {
    
    if (!imageURL || !movieURL) {
        MWLog(@"Error: URLs must have one movie and one image URLs.");
        return;
    }
    
    [[MWLivePhotoManager sharedManager]
     livePhotoWithImageURL:imageURL
     movieURL:movieURL
     progress:^(NSInteger receivedBytes, NSInteger expectedBytes) {
         
         CGFloat progress = (CGFloat)receivedBytes / (CGFloat)expectedBytes;
         
         [[NSNotificationCenter defaultCenter]
          postNotificationName:MWPHOTO_PROGRESS_NOTIFICATION
          object:@{
              @"progress": @(progress),
              @"photo": self
          }];
     }
     completion:^(PHLivePhoto *livePhoto, NSError *error) {
         
         self.underlyingLivePhoto = livePhoto;
         [self livePhotoLoadingComplete];
         
     }];
}

// Release if we can get it again from path or url
- (void)unloadUnderlyingImage {
    _loadingInProgress = NO;
	self.underlyingImage = nil;
}

- (void)unloadUnderlyingLivePhoto {
    _loadingInProgress = NO;
    self.underlyingLivePhoto = nil;
}

- (void)imageLoadingComplete {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    // Complete so notify
    _loadingInProgress = NO;
    // Notify on next run loop
    [self performSelector:@selector(postCompleteNotification) withObject:nil afterDelay:0];
}

- (void)livePhotoLoadingComplete {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    
    _loadingInProgress = NO;
    [self performSelector:@selector(postCompleteNotification) withObject:nil afterDelay:0];
}

- (void)postCompleteNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:MWPHOTO_LOADING_DID_END_NOTIFICATION
                                                        object:self];
}

- (void)cancelAnyLoading {
    if (self.isLivePhoto) {
        [[MWLivePhotoManager sharedManager] cancelAnyLoading];
        _loadingInProgress = NO;
    }
    else if (_webImageOperation != nil) {
        [_webImageOperation cancel];
        _loadingInProgress = NO;
    }
}

@end
