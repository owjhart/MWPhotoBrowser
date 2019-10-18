//
//  ZoomingScrollView.m
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <DACircularProgress/DACircularProgressView.h>
#import <PhotosUI/PhotosUI.h>
#import "MWCommon.h"
#import "MWZoomingScrollView.h"
#import "MWPhotoBrowser.h"
#import "MWPhoto.h"
#import "MWPhotoBrowserPrivate.h"
#import "UIImage+MWPhotoBrowser.h"

// Private methods and properties
@interface MWZoomingScrollView () {
    
    MWPhotoBrowser __weak *_photoBrowser;
	MWTapDetectingView *_tapView; // for background taps
	MWTapDetectingImageView *_photoImageView;
    MWTapDetectingLivePhotoView *_livePhotoView;
    UIImageView *_loadingError;
    UIImageView *_livePhotoBadge;
    CGFloat _maxSafeAreaInsetTop;
}

@end

@implementation MWZoomingScrollView

- (id)initWithPhotoBrowser:(MWPhotoBrowser *)browser {
    if ((self = [super init])) {
        
        // Setup
        _index = NSUIntegerMax;
        _photoBrowser = browser;
        
		// Tap view for background
		_tapView = [[MWTapDetectingView alloc] initWithFrame:self.bounds];
		_tapView.tapDelegate = self;
		_tapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_tapView.backgroundColor = [UIColor systemBackgroundColor];
		[self addSubview:_tapView];
		
		// Image view
		_photoImageView = [[MWTapDetectingImageView alloc] initWithFrame:CGRectZero];
		_photoImageView.tapDelegate = self;
		_photoImageView.contentMode = UIViewContentModeCenter;
		_photoImageView.backgroundColor = [UIColor systemBackgroundColor];
		[self addSubview:_photoImageView];
        
        // Live photo view
        _livePhotoView = [[MWTapDetectingLivePhotoView alloc] initWithFrame:CGRectZero];
        _livePhotoView.tapDelegate = self;
        _livePhotoView.hidden = YES;
        _livePhotoBadge.hidden = YES;
        _livePhotoView.contentMode = UIViewContentModeCenter;
        _livePhotoView.backgroundColor = [UIColor systemBackgroundColor];
        [self addSubview:_livePhotoView];
        
        // Live photo badge
        
        _livePhotoBadge = [[UIImageView alloc] initWithImage:[[PHLivePhotoView
        livePhotoBadgeImageWithOptions:PHLivePhotoBadgeOptionsOverContent] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _livePhotoBadge.tintColor = [UIColor labelColor];
        _livePhotoBadge.hidden = YES;

        _maxSafeAreaInsetTop = self.safeAreaInsets.top;

        _livePhotoBadge.frame = [self frameForLivePhotoBadge];
        _livePhotoBadge.translatesAutoresizingMaskIntoConstraints = NO;
        _livePhotoBadge.autoresizingMask = UIViewAutoresizingNone;
        [self addSubview:_livePhotoBadge];

		// Setup
		self.backgroundColor = [UIColor systemBackgroundColor];
		self.delegate = self;
		self.showsHorizontalScrollIndicator = NO;
		self.showsVerticalScrollIndicator = NO;
		self.decelerationRate = UIScrollViewDecelerationRateFast;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.showLivePhotoIcon = YES;
        self.previewLivePhotos = YES;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)prepareForReuse {
    [self hideImageFailure];
    self.photo = nil;
    self.captionView = nil;
    self.playButton = nil;
    _photoImageView.hidden = YES;
    _photoImageView.image = nil;
    _livePhotoView.hidden = YES;
    _livePhotoBadge.hidden = YES;
    _livePhotoView.livePhoto = nil;
    _index = NSUIntegerMax;
}

- (BOOL)displayingVideo {
    return [_photo respondsToSelector:@selector(isVideo)] && _photo.isVideo;
}

#pragma mark - Image

- (void)setPhoto:(id<MWPhoto>)photo {
    // Cancel any loading on old photo
    if (_photo && photo == nil) {
        if ([_photo respondsToSelector:@selector(cancelAnyLoading)]) {
            [_photo cancelAnyLoading];
        }
    }
    _photo = photo;
    
    if (_photo.isLivePhoto) {
        
        if (self.showLivePhotoIcon) {
            _livePhotoBadge.hidden = NO;
        }
        
        PHLivePhoto *livePhoto = [_photoBrowser livePhotoForPhoto:_photo];
        
        if (livePhoto) {
            [self displayLivePhoto];
        } else {
            [self prepareToShow];
        }
        
    } else {
        
        UIImage *img = [_photoBrowser imageForPhoto:_photo];
        
        if (img) {
            [self displayImage];
        } else {
            [self prepareToShow];
        }
    }
}

// Get and display image
- (void)displayImage {
	if (_photo && _photoImageView.image == nil) {
		
		// Reset
		self.maximumZoomScale = 1;
		self.minimumZoomScale = 1;
		self.zoomScale = 1;
		self.contentSize = CGSizeMake(0, 0);
		
		// Get image from browser as it handles ordering of fetching
		UIImage *img = [_photoBrowser imageForPhoto:_photo];
		if (img) {
			// Set image
			_photoImageView.image = img;
			_photoImageView.hidden = NO;
			
			// Setup photo frame
			CGRect photoImageViewFrame;
			photoImageViewFrame.origin = CGPointZero;
			photoImageViewFrame.size = img.size;
			_photoImageView.frame = photoImageViewFrame;
			self.contentSize = photoImageViewFrame.size;

			// Set zoom to minimum zoom
			[self setMaxMinZoomScalesForCurrentBounds];
			
		} else  {

            // Show image failure
            [self displayImageFailure];
			
		}
		[self setNeedsLayout];
	}
}

- (void)displayLivePhoto {
    
    if (_photo && _livePhotoView.livePhoto == nil) {
        
        // Reset
        self.maximumZoomScale = 1;
        self.minimumZoomScale = 1;
        self.zoomScale = 1;
        self.contentSize = CGSizeMake(0, 0);
        
        // Get image from browser as it handles ordering of fetching
        
        PHLivePhoto *livePhoto = [_photoBrowser livePhotoForPhoto:_photo];
        
        if (livePhoto) {
            _livePhotoView.livePhoto = livePhoto;
            _livePhotoView.hidden = NO;
            if (self.showLivePhotoIcon) {
                _livePhotoBadge.hidden = NO;
            }
            _livePhotoView.frame = CGRectMake(0, 0, livePhoto.size.width, livePhoto.size.height);
            if (self.previewLivePhotos) {
                [_livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleHint];
            }
            self.contentSize = _livePhotoView.frame.size;
            
            [self setMaxMinZoomScalesForCurrentBounds];
        } else {
            [self displayImageFailure];
        }
        
        [self setNeedsLayout];
    }
}

// Image failed so just show black!
- (void)displayImageFailure {
    _photoImageView.image = nil;
    
    // Show if image is not empty
    if (![_photo respondsToSelector:@selector(emptyImage)] || !_photo.emptyImage) {
        if (!_loadingError) {
            _loadingError = [UIImageView new];
            _loadingError.image = [UIImage imageForResourcePath:@"MWPhotoBrowser.bundle/ImageError" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
            _loadingError.userInteractionEnabled = NO;
            _loadingError.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
            UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
            [_loadingError sizeToFit];
            [self addSubview:_loadingError];
        }
        _loadingError.frame = CGRectMake(floorf((self.bounds.size.width - _loadingError.frame.size.width) / 2.),
                                         floorf((self.bounds.size.height - _loadingError.frame.size.height) / 2),
                                         _loadingError.frame.size.width,
                                         _loadingError.frame.size.height);
    }
}

- (void)hideImageFailure {
    if (_loadingError) {
        [_loadingError removeFromSuperview];
        _loadingError = nil;
    }
}

#pragma mark -

- (void)prepareToShow {
    self.zoomScale = 0;
    self.minimumZoomScale = 0;
    self.maximumZoomScale = 0;
    [self hideImageFailure];
}

#pragma mark - Setup

- (CGFloat)initialZoomScaleWithMinScaleImageSize:(CGSize)imageSize {
    CGFloat zoomScale = self.minimumZoomScale;
    if ((_livePhotoView || _photoImageView) && _photoBrowser.zoomPhotosToFill) {
        // Zoom image to fill if the aspect ratios are fairly similar
        CGSize boundsSize = self.bounds.size;
        CGFloat boundsAR = boundsSize.width / boundsSize.height;
        CGFloat imageAR = imageSize.width / imageSize.height;
        CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
        CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
        // Zooms standard portrait images on a 3.5in screen but not on a 4in screen.
        if (ABS(boundsAR - imageAR) < 0.17) {
            zoomScale = MAX(xScale, yScale);
            // Ensure we don't zoom in or out too far, just in case
            zoomScale = MIN(MAX(self.minimumZoomScale, zoomScale), self.maximumZoomScale);
        }
    }
    return zoomScale;
}

- (void)setMaxMinZoomScalesForCurrentBounds {
    
    // Reset
    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.zoomScale = 1;
    
    UIView *view;
    CGSize imageSize;
    
    if (_livePhotoView.livePhoto) {
        view = _livePhotoView;
        imageSize = _livePhotoView.livePhoto.size;
    } else if (_photoImageView.image) {
        view = _photoImageView;
        imageSize = _photoImageView.image.size;
    } else {
        return;
    }
    
    // Reset position
    view.frame = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height);
    
    // Sizes
    CGSize boundsSize = self.bounds.size;
    
    // Calculate Min
    CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
    CGFloat minScale = MIN(xScale, yScale);                 // use minimum of these to allow the image to become fully visible
    
    // Calculate Max
    CGFloat maxScale = 3;

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        // Let them go a bit bigger on a bigger screen!
        maxScale = 4;
    }
    
    // Image is smaller than screen so no zooming!
    if (xScale >= 1 && yScale >= 1) {
        minScale = 1.0;
    }
    
    // Set min/max zoom
    self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;
    
    // Initial zoom
    self.zoomScale = [self initialZoomScaleWithMinScaleImageSize:imageSize];
    
    // If we're zooming to fill then centralise
    if (self.zoomScale != minScale) {
        
        // Centralise
        self.contentOffset = CGPointMake((imageSize.width * self.zoomScale - boundsSize.width) / 2.0,
                                         (imageSize.height * self.zoomScale - boundsSize.height) / 2.0);
        
    }
    
    // Disable scrolling initially until the first pinch to fix issues with swiping on an initally zoomed in photo
    self.scrollEnabled = NO;
    
    // If it's a video then disable zooming
    if ([self displayingVideo]) {
        self.maximumZoomScale = self.zoomScale;
        self.minimumZoomScale = self.zoomScale;
    }
    
    // Layout
    [self setNeedsLayout];
}

#pragma mark - Layout

- (CGRect)frameForLivePhotoBadge
{
    CGRect frame = _livePhotoBadge.frame;
    frame.origin.y = self.contentOffset.y + 8 + _maxSafeAreaInsetTop;
    frame.origin.x = self.contentOffset.x + 8;
    return frame;
}

- (void)layoutSubviews {
	
	// Update tap view frame
	_tapView.frame = self.bounds;
	
	// Position indicators (centre does not seem to work!)
	if (_loadingError)
        _loadingError.frame = CGRectMake(floorf((self.bounds.size.width - _loadingError.frame.size.width) / 2.),
                                         floorf((self.bounds.size.height - _loadingError.frame.size.height) / 2),
                                         _loadingError.frame.size.width,
                                         _loadingError.frame.size.height);

    if (self.safeAreaInsets.top > _maxSafeAreaInsetTop) {
        _maxSafeAreaInsetTop = self.safeAreaInsets.top;
    }

	// Super
	[super layoutSubviews];

    if (!self.tracking && !self.dragging && !self.decelerating && !self.zooming && !self.zoomBouncing) {
        _livePhotoBadge.frame = [self frameForLivePhotoBadge];
    }

    UIView *viewToCenter = self.photo.isLivePhoto ? _livePhotoView : _photoImageView;
    
    // Center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = viewToCenter.frame;
    
    // Horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
	} else {
        frameToCenter.origin.x = 0;
	}
    
    // Vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
	} else {
        frameToCenter.origin.y = 0;
	}
    
	// Center
	if (!CGRectEqualToRect(viewToCenter.frame, frameToCenter))
		viewToCenter.frame = frameToCenter;
	
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.photo.isLivePhoto ? _livePhotoView : _photoImageView;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[_photoBrowser cancelControlHiding];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    self.scrollEnabled = YES; // reset
	[_photoBrowser cancelControlHiding];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	[_photoBrowser hideControlsAfterDelay];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    _livePhotoBadge.frame = [self frameForLivePhotoBadge];
}

#pragma mark - Tap Detection

- (void)handleSingleTap:(CGPoint)touchPoint {
	[_photoBrowser performSelector:@selector(toggleControls) withObject:nil afterDelay:0.2];
}

- (void)handleDoubleTap:(CGPoint)touchPoint {
    
    // Dont double tap to zoom if showing a video
    if ([self displayingVideo]) {
        return;
    }
	
	// Cancel any single tap handling
	[NSObject cancelPreviousPerformRequestsWithTarget:_photoBrowser];
    
    CGSize imageSize;
    
    if (self.photo.isLivePhoto) {
        imageSize = _livePhotoView.livePhoto.size;
    } else {
        imageSize = _photoImageView.image.size;
    }
	
	// Zoom
	if (self.zoomScale != self.minimumZoomScale
        && self.zoomScale != [self initialZoomScaleWithMinScaleImageSize:imageSize]) {
		
		// Zoom out
		[self setZoomScale:self.minimumZoomScale animated:YES];
		
	} else {
		
		// Zoom in to twice the size
        CGFloat newZoomScale = ((self.maximumZoomScale + self.minimumZoomScale) / 2);
        CGFloat xsize = self.bounds.size.width / newZoomScale;
        CGFloat ysize = self.bounds.size.height / newZoomScale;
        [self zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];

	}
	
	// Delay controls
	[_photoBrowser hideControlsAfterDelay];
}

// Image View
- (void)imageView:(UIImageView *)imageView singleTapDetected:(UITouch *)touch { 
    [self handleSingleTap:[touch locationInView:imageView]];
}
- (void)imageView:(UIImageView *)imageView doubleTapDetected:(UITouch *)touch {
    [self handleDoubleTap:[touch locationInView:imageView]];
}

// Live Photo View
- (void)livePhotoView:(PHLivePhotoView *)livePhotoView singleTapDetected:(UITouch *)touch {
    [self handleSingleTap:[touch locationInView:livePhotoView]];
}

- (void)livePhotoView:(PHLivePhotoView *)livePhotoView doubleTapDetected:(UITouch *)touch {
    [self handleDoubleTap:[touch locationInView:livePhotoView]];
}

// Background View
- (void)view:(UIView *)view singleTapDetected:(UITouch *)touch {
    // Translate touch location to image view location
    CGFloat touchX = [touch locationInView:view].x;
    CGFloat touchY = [touch locationInView:view].y;
    touchX *= 1/self.zoomScale;
    touchY *= 1/self.zoomScale;
    touchX += self.contentOffset.x;
    touchY += self.contentOffset.y;
    [self handleSingleTap:CGPointMake(touchX, touchY)];
}
- (void)view:(UIView *)view doubleTapDetected:(UITouch *)touch {
    // Translate touch location to image view location
    CGFloat touchX = [touch locationInView:view].x;
    CGFloat touchY = [touch locationInView:view].y;
    touchX *= 1/self.zoomScale;
    touchY *= 1/self.zoomScale;
    touchX += self.contentOffset.x;
    touchY += self.contentOffset.y;
    [self handleDoubleTap:CGPointMake(touchX, touchY)];
}

@end
