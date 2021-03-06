//
//  ViewController.m
//  Pandora
//
//  Created by Mac Pro_C on 12-12-26.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//
#import "ViewController.h"
#import "PDRToolSystem.h"
#import "PDRToolSystemEx.h"

#define kStatusBarHeight 20.f

@implementation ViewController
@synthesize defalutStausBarColor;
- (void)loadView
{
    [super loadView];
    PDRCore *h5Engine = [PDRCore Instance];
    
    _isFullScreen = [UIApplication sharedApplication].statusBarHidden;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNeedEnterFullScreenNotification:)
                                                 name:PDRNeedEnterFullScreenNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSetStatusBarBackgroundNotification:)
                                                 name:PDRNeedSetStatusBarBackgroundNotification
                                               object:nil];
    CGRect newRect = self.view.bounds;
    
    if ( [self reserveStatusbarOffset] && [PTDeviceOSInfo systemVersion] > PTSystemVersion6Series) {
        if ( !_isFullScreen ) {
            newRect.origin.y += kStatusBarHeight;
            newRect.size.height -= kStatusBarHeight;
        }
        self.defalutStausBarColor = [UIColor whiteColor];
        NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
        NSString *statusBarBackground = [infoPlist objectForKey:@"StatusBarBackground"];
        if ( [statusBarBackground isKindOfClass:[NSString class]] ) {
            UIColor *newsetColor = [UIColor colorWithCSS:statusBarBackground];
            if ( newsetColor ) {
                self.defalutStausBarColor = newsetColor;
            }
        }
        _statusBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, newRect.size.width, kStatusBarHeight)];
        _statusBarView.backgroundColor = self.defalutStausBarColor;
        _statusBarView.autoresizingMask =  UIViewAutoresizingFlexibleWidth;
        [self.view addSubview:_statusBarView];
    }
    //self.view.autoresizingMask =  UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _containerView = [[UIView alloc] initWithFrame:newRect];
    _containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_containerView];
    ///1113
    h5Engine.coreDeleagete = self;
    [h5Engine setContainerView:_containerView];
    //[h5Engine setContainerView:self.view];
    [h5Engine showLoadingPage];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[PDRCore Instance] start];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PDRNeedEnterFullScreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PDRNeedSetStatusBarBackgroundNotification object:nil];
    // Release any retained subviews of the main view.
}
#pragma mark -
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration
{
    [[PDRCore Instance] handleSysEvent:PDRCoreSysEventInterfaceOrientation
                            withObject:[NSNumber numberWithInt:toInterfaceOrientation]];
    if ([PTDeviceOSInfo systemVersion] >= PTSystemVersion8Series) {
        [[UIApplication sharedApplication] setStatusBarHidden:_isFullScreen ];
    }
}

- (BOOL)shouldAutorotate
{
    return TRUE;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return [[PDRCore Instance].settings supportedInterfaceOrientations];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ( [PDRCore Instance].settings ) {
        return [[PDRCore Instance].settings supportsOrientation:interfaceOrientation];
    }
    return UIInterfaceOrientationPortrait == interfaceOrientation;
}

- (BOOL)prefersStatusBarHidden
{
    return _isFullScreen;/*
                          NSString *model = [UIDevice currentDevice].model;
                          if (UIUserInterfaceIdiomPhone == UI_USER_INTERFACE_IDIOM()
                          && (NSOrderedSame == [@"iPad" caseInsensitiveCompare:model]
                          || NSOrderedSame == [@"iPad Simulator" caseInsensitiveCompare:model])) {
                          return YES;
                          }
                          return NO;*/
}
#pragma mark -
- (BOOL)reserveStatusbarOffset {
    return [PDRCore Instance].settings.reserveStatusbarOffset;
}

#pragma mark -
-(UIColor*)getStatusBarBackground {
    return _statusBarView.backgroundColor;
}
#pragma mark -
- (void)handleNeedEnterFullScreenNotification:(NSNotification*)notification
{
    NSNumber *isHidden = [notification object];
    if ( _isFullScreen == [isHidden boolValue] ) {
        return;
    }
        
    _isFullScreen = [isHidden boolValue];
    [[UIApplication sharedApplication] setStatusBarHidden:_isFullScreen withAnimation:_isFullScreen?NO:YES];
    if ( [PTDeviceOSInfo systemVersion] > PTSystemVersion6Series ) {
        [self setNeedsStatusBarAppearanceUpdate];
    }// else {
 //   return;
    //  }
    CGRect newRect = self.view.bounds;
    if ( [PTDeviceOSInfo systemVersion] <= PTSystemVersion6Series ) {
        newRect = [UIApplication sharedApplication].keyWindow.bounds;
        if ( _isFullScreen ) {
            [UIView beginAnimations:nil context:nil];
            self.view.frame = newRect;
            [UIView commitAnimations];
        } else {
            UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
            if ( UIDeviceOrientationLandscapeLeft == interfaceOrientation
                || interfaceOrientation == UIDeviceOrientationLandscapeRight ) {
                newRect.size.width -=kStatusBarHeight;
            } else {
                newRect.origin.y += kStatusBarHeight;
                newRect.size.height -=kStatusBarHeight;
            }
            [UIView beginAnimations:nil context:nil];
            self.view.frame = newRect;
            [UIView commitAnimations];
        }

    } else {
        if ( [self reserveStatusbarOffset] ) {
            _statusBarView.hidden = _isFullScreen;
            if ( !_isFullScreen ) {
                newRect.origin.y += kStatusBarHeight;
                newRect.size.height -= kStatusBarHeight;
            }
        }
        _containerView.frame = newRect;
    }
    [[PDRCore Instance] handleSysEvent:PDRCoreSysEventInterfaceOrientation
                            withObject:[NSNumber numberWithInt:0]];
}

- (void)handleSetStatusBarBackgroundNotification:(NSNotification*)notification
{
    UIColor *newColor = [notification object];
    if ( newColor ) {
        _statusBarView.backgroundColor = newColor;
    } else {
        _statusBarView.backgroundColor = self.defalutStausBarColor;
    }
}

- (void)didReceiveMemoryWarning{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [[PDRCore Instance] handleSysEvent:PDRCoreSysEventReceiveMemoryWarning withObject:nil];
}

- (void)dealloc {
    self.defalutStausBarColor = nil;
    [_statusBarView release];
    [_containerView release];
    [super dealloc];
}
@end
