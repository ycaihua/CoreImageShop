//
//  SCMediaDisplayerView.m
//  CoreImageShop
//
//  Created by Simon CORSIN on 16/05/14.
//
//

#import <AVFoundation/AVFoundation.h>
#import "SCMediaDisplayerView.h"

@interface SCMediaDisplayerView() {
    NSImageView *_imageView;
    AVPlayer *_player;
    NSButton *_playButton;
    AVPlayerLayer *_playerLayer;
}

@end

@implementation SCMediaDisplayerView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self registerForDraggedTypes:@[NSFilenamesPboardType]];
        
        self.layerUsesCoreImageFilters = YES;
        [self setWantsLayer:YES];
        _imageView = [[NSImageView alloc] init];
        _player = [[AVPlayer alloc] init];
        _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        _player.volume = 0;
        
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [self.layer addSublayer:_playerLayer];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playReachedEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        
        [_imageView unregisterDraggedTypes];
        
        [self addSubview:_imageView];
        
        _playButton = [[NSButton alloc] init];
        _playButton.frame = CGRectMake(5, 5, 40, 20);
        _playButton.alphaValue = 0;
        
        self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
        _playButton.target = self;
        _playButton.action = @selector(playPressed:);

    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)playReachedEnd:(NSNotification *)not {
    [_player seekToTime:kCMTimeZero];
}

- (void)mouseDown:(NSEvent *)theEvent {
    [super mouseDown:theEvent];
    
    NSPoint point = [self convertPoint:theEvent.locationInWindow fromView:theEvent.window.contentView];
    
    NSNotification *notification = [NSNotification notificationWithName:kMediaDisplayerClickNotification object:self userInfo:@{
                                                                                                                                kMediaDisplayerClickLocationKey : [NSValue valueWithPoint:point]
                                                                                                                                }];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor grayColor] setFill];
    NSRectFill(dirtyRect);
    
    [super drawRect:dirtyRect];
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldSize {
    [super resizeWithOldSuperviewSize:oldSize];
    
    _playerLayer.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    _imageView.frame = self.bounds;
}

- (NSArray *)fileUrlsForDraggingInfo:(id<NSDraggingInfo>)sender {
    NSPasteboard *pasteboard = [sender draggingPasteboard];
    NSArray *fileURLs = [pasteboard readObjectsForClasses:@[[NSURL class] ] options:@{NSPasteboardURLReadingFileURLsOnlyKey: @YES}];

    return fileURLs;
}


- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    NSPasteboard *pasteboard = [sender draggingPasteboard];
    NSArray *fileURLs = [pasteboard readObjectsForClasses:@[[NSURL class] ] options:@{NSPasteboardURLReadingFileURLsOnlyKey: @YES}];
    
    if (fileURLs.count == 1) {
        return NSDragOperationLink;
    }
    
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSURL *url = [[self fileUrlsForDraggingInfo:sender] firstObject];
    
    self.mediaUrl = url;
    
    return YES;
}

- (void)playPressed:(id)sender {
    if (_player.rate > 0) {
        [_player pause];
    } else {
        [_player play];
    }
    [self updatePlayButton];
}

- (void)updatePlayButton {
    if (_player.currentItem == nil){
        [_playButton removeFromSuperview];
    } else {
        if (_playButton.superview == nil) {
            [self addSubview:_playButton];
        }
        if (_player.rate > 0) {
            _playButton.title = @"Pause";
        } else {
            _playButton.title = @"Play";
        }
    }
}

- (void)setMediaUrl:(NSURL *)mediaUrl {
    _mediaUrl = mediaUrl;
    AVAsset *asset = [AVURLAsset URLAssetWithURL:mediaUrl options:nil];
    if (asset.isPlayable) {
        _imageView.image = nil;
        [_player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithAsset:asset]];
        [_player play];
    } else {
        [_player replaceCurrentItemWithPlayerItem:nil];
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:mediaUrl];
        
        if (image != nil) {
            _imageView.image = image;
            [self display];
        } else {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Invalid file" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Only video or images are accepted"];
            [alert runModal];
        }
    }
    
    [self updatePlayButton];
}

- (void)setFilterGroup:(SCFilterGroup *)filterGroup {
    _filterGroup = filterGroup;
    
    [self.layer setFilters:filterGroup.coreImageFilters];
}

@end
