/**
 * GreenPois0n Medicine - animate.mm
 * Copyright (C) 2011 Chronic-Dev Team
 * Copyright (C) 2011 Nicolas Haunold
 * Copyright (C) 2011 Justin Williams
 * Copyright (C) 2011 Alex Mault
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/



#import "animationPreviewViewController.h"
#define framerate 10.0

@implementation animationPreviewViewController


NSInteger firstNumSort(id str1, id str2, void *context) {
    int num1 = [str1 integerValue];
    int num2 = [str2 integerValue];

    if (num1 < num2)
        return NSOrderedAscending;
    else if (num1 > num2)
        return NSOrderedDescending;

    return NSOrderedSame;
}



-(id)initWithAnimationName:(NSString*)animation {
    self = [super init];
    if(self){
        [self.view setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
        currentFrame = 0;
        displayLayer = [self.view layer];
        currentAnimation = animation;
        imagesArr = [[NSMutableArray alloc] init];
        NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithFormat:@"/Library/BootLogos/%@/", currentAnimation] error:nil];
        NSArray *onlyPNGs = [dirContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.png'"]];
        onlyPNGs = [onlyPNGs sortedArrayUsingFunction:firstNumSort context:NULL];
        unsigned int j = 0;
        for (j = 0; j < [onlyPNGs count]; j++) {
            CGDataProviderRef dpr = CGDataProviderCreateWithFilename([[NSString stringWithFormat:@"/Library/BootLogos/%@/%@", currentAnimation, [onlyPNGs objectAtIndex:j]] UTF8String]);
            CGImageRef img = CGImageCreateWithPNGDataProvider(dpr, NULL, true, kCGRenderingIntentDefault);

            [imagesArr addObject:CFBridgingRelease(img)];
            CGDataProviderRelease(dpr);

            UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"restart" style:UIBarButtonItemStylePlain target:self action:@selector(beginAnimation)];

            self.navigationItem.rightBarButtonItem = button;
        }

    }
    return self;
}



//Our title...
- (NSString*) title {
    return @"Preview";
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

-(void)viewDidAppear:(BOOL)animated{
    [self beginAnimation];

}

-(void)beginAnimation{
    if(animationTimer){
        [animationTimer invalidate];
        animationTimer = nil;
        currentFrame = 0;
    }
    animationTimer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:(1/framerate) target:self selector:@selector(stepAnimation:) userInfo:nil repeats:true];
    [[NSRunLoop currentRunLoop] addTimer:animationTimer forMode:NSDefaultRunLoopMode];

}

-(void)stepAnimation:(NSTimer*)theTimer{
   // just to make sure our timer doesn't mess anything up...
    if(currentFrame >= [imagesArr count])
        return;

    CGImageRef bootimg = (__bridge CGImageRef)[imagesArr objectAtIndex:currentFrame];
    //CGContextDrawImage(c, CGRectMake(0, 0, screenWidth, screenHeight), bootimg);
    displayLayer.contents = (__bridge id)bootimg;

    if(currentFrame < [imagesArr count]-1){
        currentFrame++;
    }else{
        //we are done with the animation... we really don't need to do anything.
        //but I figured i'd break out a case anyways.
    }
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}



@end
