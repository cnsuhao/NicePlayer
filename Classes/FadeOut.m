//
//  FadeOut.m
//  NicePlayer
//
//  Created by Robert Chin on 2/11/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "FadeOut.h"
#import "Preferences.h"
#import "NiceWindow.h"

#define INITIAL_FADE_DURATION	5.0
#define ALPHA_VALUE_DELTA		0.04
#define TIMER_INTERVAL			0.01

static id fadeOutInstance = nil;

@implementation FadeOut

+(id)fadeOut
{
    if(!fadeOutInstance)
        fadeOutInstance = [FadeOut new];
    return fadeOutInstance;
}

-(id)init
{
    if(self = [super init]){
        windowSet = [[NSMutableSet set] retain];
        faderTimer = nil;
    }
    return self;
}

-(id)initialFadeForDict:(id)aDictionary
{
    if([[Preferences mainPrefs] showInitialOverlays]){
        return [NSTimer scheduledTimerWithTimeInterval:INITIAL_FADE_DURATION
                                                target:self
                                              selector:@selector(doInitialFadeForDict:)
                                              userInfo:aDictionary
                                               repeats:NO];
    } else {
        id anObject, e = [[aDictionary objectForKey:@"Fade"] objectEnumerator];
        while(anObject = [e nextObject]){
            [anObject setAlphaValue:0.0];
        }
        return nil;
    }
}

-(void)doInitialFadeForDict:(NSTimer *)aTimer
{
    if([[Preferences mainPrefs] fadeOverlays]){
        [windowSet unionSet:[[aTimer userInfo] objectForKey:@"Fade"]];
        [self destroyAndCreateTimer];
    } else {
        id anObject, e = [[aTimer userInfo] objectEnumerator];
        while(anObject = [e nextObject]){
            [anObject setAlphaValue:0.0];
        }
    }
    [[[aTimer userInfo] objectForKey:@"Window"] initialFadeComplete];
}

-(void)addWindow:(id)anObject
{
    if([[Preferences mainPrefs] fadeOverlays]){
        [windowSet addObject:anObject];
        [self destroyAndCreateTimer];
    } else
        [anObject setAlphaValue:0.0];
}

-(void)removeWindow:(id)anObject
{
    [windowSet removeObject:anObject];
}

-(void)destroyAndCreateTimer
{
    if(([windowSet count] > 0) && (faderTimer == nil)){
        faderTimer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL
                                                      target:self
                                                    selector:@selector(updateAlphaValues)
                                                    userInfo:nil
                                                     repeats:YES];
    }
    if(([windowSet count] == 0) && (faderTimer != nil)){
        [faderTimer invalidate];
        faderTimer = nil;
    }
}

-(void)updateAlphaValues
{
    id anObject, e = [windowSet objectEnumerator];
    while(anObject = [e nextObject]){
        float newValue = [anObject alphaValue] - ALPHA_VALUE_DELTA;
        newValue = (newValue < 0.0) ? 0.0 : newValue;
        [anObject setAlphaValue:newValue];
    }
    [self testForRemoval];
    [self destroyAndCreateTimer];
}

-(void)testForRemoval
{
    id newSet = [[NSMutableSet set] retain];
    id anObject, e = [windowSet objectEnumerator];
    while(anObject = [e nextObject]){
        if([anObject alphaValue] > 0.0)
            [newSet addObject:anObject];
    }
    
    [windowSet release];
    windowSet = newSet;
}

@end
