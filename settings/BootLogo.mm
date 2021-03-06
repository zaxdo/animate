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

/* So why go with a PSViewController instead of a PSListController? It's because of the nature of this
 * pref bundle. We need to dynamicly decide what content is displayed based off of a directory listing.
 *
 */
#import <ImageIO/ImageIO.h>
#import <Preferences/PSViewController.h>
#import "animationPreviewViewController.h"

@interface BootLogoListController: PSViewController <UITableViewDelegate, UITableViewDataSource> {
    //an array of folders for possible boot logos.
    NSMutableArray *bootLogos;

    //the settings Dictionary
    NSMutableDictionary *plistDictionary;

    //The identifier of the currently selected logo.
    NSString *currentlySelected;

     //do I really need to explain this one?
    UITableView *_logoTable;
    UIBarButtonItem *previewButton;

}

+ (void) load;

- (id) initForContentSize:(CGSize)size;
- (id) view;
- (id) navigationTitle;
- (void) themesChanged;

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView;
- (id) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (id) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void) tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;
- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL) tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL) tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath;

@end

@implementation BootLogoListController

//Our title...
- (NSString*) title {
    return @"Boot Animation";
}

//just to be safe. Return the tableview if someone asks.
- (UIView*) view {
    return _logoTable;
}


+ (void) load {
    //every good party needs a pool!
    @autoreleasepool {}
}

//The bulk of the initiation done here.
- (id) initForContentSize:(CGSize)size {

    if ((self = [super init]) != nil) {
        bootLogos = [[NSMutableArray alloc] init];
        previewButton = [[UIBarButtonItem alloc] initWithTitle:@"Preview" style:UIBarButtonItemStylePlain target:self action:@selector(playPreview)];

        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/BootLogos/org.chronic-dev.animate.plist"]) {
            //NSDictionary *plistDictionary = [[NSDictionary dictionaryWithContentsOfFile:@"/Library/BootLogos/org.chronic-dev.animate.plist"] retain];
            //not using a dict atm... seems to be saving problems.
            NSError *error;
            currentlySelected = [[NSString alloc] initWithContentsOfFile:@"/Library/BootLogos/org.chronic-dev.animate.plist" encoding:NSUTF8StringEncoding error:&error];
        }

        if(currentlySelected == nil)
            currentlySelected = @"default";

        [self reloadPossibleLogos];

        _logoTable = [[UITableView alloc] initWithFrame: (CGRect){{0,0}, size} style:UITableViewStyleGrouped];
        [_logoTable setDataSource:self];
        [_logoTable setDelegate:self];
        if ([self respondsToSelector:@selector(setView:)])
            [self setView:_logoTable];
    }
    return self;
}

-(void)playPreview{
    animationPreviewViewController *preview = [[animationPreviewViewController alloc] initWithAnimationName:currentlySelected];
    [super pushController:preview];
}
-(void)convertGIFsToPNGs {
    NSError *err = nil;
    NSArray *contents = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/BootLogos/" error:&err] pathsMatchingExtensions:@[@"gif"]];
    for (NSString *item in contents) {
        NSString *path = [@"/Library/BootLogos/" stringByAppendingPathComponent:item];
        NSData *imageData = [NSData dataWithContentsOfFile:path];

        CGImageSourceRef imgsrc = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
        size_t frames = CGImageSourceGetCount(imgsrc);
        NSString *dirname = [[path lastPathComponent] stringByDeletingPathExtension];
        NSString *base = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:dirname];
        [[NSFileManager defaultManager] createDirectoryAtPath:base withIntermediateDirectories:NO attributes:nil error:nil];
        for (int i = 0; i < frames; i++) {
            UIImage *img = [UIImage imageWithCGImage:CGImageSourceCreateImageAtIndex(imgsrc, i, NULL)];
            [UIImagePNGRepresentation(img) writeToFile:[base stringByAppendingPathComponent:[NSString stringWithFormat:@"%i.png", i]] atomically:YES];
        }
        [[NSFileManager defaultManager] removeItemAtPath: path error:nil];
    }
}
-(void)reloadPossibleLogos{
    [self convertGIFsToPNGs];
    [bootLogos removeAllObjects];
    id file = nil;
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager]
                                         enumeratorAtPath:@"/Library/BootLogos/"];

    while ((file = [enumerator nextObject]))
    {
        BOOL isDirectory=NO;
        [[NSFileManager defaultManager]
         fileExistsAtPath:[NSString
                           stringWithFormat:@"%@/%@",@"/Library/BootLogos",file]
         isDirectory:&isDirectory];
        if (isDirectory && ![file isEqualToString:@"default"] && ![file isEqualToString:@"apple"]) {
            [bootLogos addObject:file];
        }

    }

}


//something changed, not sure what.. but lets reload the data anyways.
- (void) reloadSpecifiers{
[_logoTable reloadData];
}

//Headers are always a nice touch.
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if(section == 0)
        return @"Built in";
    else
        return @"Extras";
}

- (void)viewWillAppear:(BOOL)animated{
    [self reloadPossibleLogos];
    if([currentlySelected isEqualToString:@"default"] || [currentlySelected isEqualToString:@"apple"]){

        self.navigationItem.rightBarButtonItem = nil;
    }else{
        self.navigationItem.rightBarButtonItem = previewButton;
    }
    [_logoTable reloadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}


#pragma mark - Table view data source

/*
 *All of this should be very self explanatory..
 */

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if([bootLogos count] > 0)
        return 2;
    else
        return 1;

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0)
        return 2;
    else
        return [bootLogos count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    if(indexPath.section == 0){
        if(indexPath.row == 0){
            cell.textLabel.text = @"Apple Logo";
            if([currentlySelected isEqualToString:@"apple"])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }else if(indexPath.row == 1){
            cell.textLabel.text = @"Chronic Dev";
            if([currentlySelected isEqualToString:@"default"])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }else if(indexPath.section == 1){
        cell.textLabel.text = [bootLogos objectAtIndex:indexPath.row];
        if([cell.textLabel.text isEqualToString:currentlySelected])
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
        if(section == 1 || [bootLogos count] <= 0){
            return @"Copyright (C) 2011 Chronic-Dev Team \n\n 2014 William Vabrinskas Compiled for 64 bit architecture";
        }

    return nil;
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0){
        if(indexPath.row == 0){
            currentlySelected = @"apple";
        }else if(indexPath.row == 1){
            currentlySelected = @"default";
        }
        self.navigationItem.rightBarButtonItem = nil;
    }else{
        currentlySelected = [bootLogos objectAtIndex:indexPath.row];
        self.navigationItem.rightBarButtonItem = previewButton;
    }

    NSError *error = nil;
    [currentlySelected writeToFile:@"/Library/BootLogos/org.chronic-dev.animate.plist" atomically:true encoding:NSUTF8StringEncoding error:&error];



    if(error){
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"we were unable to save your changes. \n\n sorry.." delegate:nil cancelButtonTitle:@"darn!" otherButtonTitles:nil];
        [errorAlert show];
    }
    [_logoTable reloadData];

}


@end
