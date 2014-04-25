//
//  DeviceAlbumViewController.m
//  PhotoPickerPlus-SampleApp
//
//  Created by ARANEA on 8/5/13.
//  Copyright (c) 2013 Chute. All rights reserved.
//

#import "GCAlbumsTableViewController.h"
#import "GCAssetsCollectionViewController.h"
#import "GCAssetsTableViewController.h"
#import "GCAccountMediaViewController.h"
#import "GCAccountAlbum.h"
#import "GCAlbumTableViewCell.h"
#import "GCPhotoPickerConfiguration.h"

#import "GetChute.h"

#import "MBProgressHUD.h"
#import <AssetsLibrary/AssetsLibrary.h>


@interface GCAlbumsTableViewController ()

@property (strong, nonatomic) ALAssetsLibrary *assetsLibrary;
@property (strong, nonatomic) NSMutableArray *tempAlbums;
@property (strong, nonatomic) NSMutableArray *elementCount;

@end

@implementation GCAlbumsTableViewController

@synthesize albums, assetsLibrary,elementCount,tempAlbums;

@synthesize successBlock, cancelBlock;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Albums";
    
    if(self.isItDevice) {
        [self getAlbumsFromDevice];
        [self.navigationItem setRightBarButtonItem:[self setCancelButton]];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.albums count];
}

- (GCAlbumTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    GCAlbumTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[GCAlbumTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if([self isItDevice])
    {
        ALAssetsGroup *albumForCell = [albums objectAtIndex:indexPath.row];
        NSString *albumName = [albumForCell valueForProperty:ALAssetsGroupPropertyName];
        NSString *numOfAssets = [elementCount objectAtIndex:indexPath.row];
        
        cell.imageView.image = [UIImage imageWithCGImage:[albumForCell posterImage]];
        cell.titleLabel.text = [NSString stringWithFormat:@"%@  (%@)", albumName,numOfAssets];
    }
    else
    {
        GCAccountAlbum *albumForCell = [self.albums objectAtIndex:indexPath.row];
        cell.imageView.image = [UIImage imageNamed:@"album_default.png"];
        cell.titleLabel.text = [NSString stringWithFormat:@"%@",albumForCell.name];
        
    }
//    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
   
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.isItDevice)
    {
        NSDictionary *defaultLayouts = [[GCPhotoPickerConfiguration configuration] defaultLayouts];
        
        if ([[defaultLayouts objectForKey:@"asset_layout"] isEqualToString:@"tableView"]) {
            
            GCAssetsTableViewController *atVC = [GCAssetsTableViewController new];
            [atVC setIsMultipleSelectionEnabled:self.isMultipleSelectionEnabled];
            [atVC setSuccessBlock:[self successBlock]];
            [atVC setCancelBlock:[self cancelBlock]];
            [atVC setIsItDevice:self.isItDevice];
            [atVC setAssetGroup:[self.albums objectAtIndex:indexPath.row]];
            
            [self.navigationController pushViewController:atVC animated:YES];
        }
        
        else {
        
            GCAssetsCollectionViewController *acVC = [[GCAssetsCollectionViewController alloc] initWithCollectionViewLayout:[GCAssetsCollectionViewController setupLayout]];
            [acVC setIsMultipleSelectionEnabled:self.isMultipleSelectionEnabled];
            [acVC setSuccessBlock:self.successBlock];
            [acVC setCancelBlock:self.cancelBlock];
            [acVC setIsItDevice:self.isItDevice];
            [acVC setAssetGroup:[self.albums objectAtIndex:indexPath.row]];

            [self.navigationController pushViewController:acVC animated:YES];
        }
    }
    
    else
    {
        GCAccountAlbum *accAlbum = [self.albums objectAtIndex:indexPath.row];
        GCAccountMediaViewController *amVC = [GCAccountMediaViewController new];
        [amVC setAccountID:self.accountID];
        [amVC setAlbumID:accAlbum.id];
        [amVC setServiceName:self.serviceName];
        [amVC setIsItDevice:self.isItDevice];
        [amVC setIsMultipleSelectionEnabled:self.isMultipleSelectionEnabled];
        [amVC setSuccessBlock:self.successBlock];
        [amVC setCancelBlock:self.cancelBlock];
        
        [self.parentViewController.navigationController pushViewController:amVC animated:YES];
    }
}

#pragma mark - Custom Methods

- (void)getAlbumsFromDevice
{
    elementCount = [[NSMutableArray array] init];
    
    if (!assetsLibrary) {
        assetsLibrary = [[ALAssetsLibrary alloc] init];
    }
    if (!albums) {
        tempAlbums = [[NSMutableArray alloc] init];
    } else {
        [tempAlbums removeAllObjects];
    }

    ALAssetsLibraryGroupsEnumerationResultsBlock listGroupBlock =  ^(ALAssetsGroup *group, BOOL *stop) {
        if(group != nil) {
            //Add the album to the array
            [tempAlbums addObject: group];
            
            if ([[[GCPhotoPickerConfiguration configuration] mediaTypesAvailable] isEqualToString:@"Photos"])
                [group setAssetsFilter:[ALAssetsFilter allPhotos]];
            if ([[[GCPhotoPickerConfiguration configuration] mediaTypesAvailable] isEqualToString:@"Videos"])
                [group setAssetsFilter:[ALAssetsFilter allVideos]];
            if ([[[GCPhotoPickerConfiguration configuration] mediaTypesAvailable] isEqualToString:@"All Media"])
                [group setAssetsFilter:[ALAssetsFilter allAssets]];
            [elementCount addObject: [NSNumber numberWithInt:group.numberOfAssets]];
            
        } else
        {
            [self setAlbums:tempAlbums];
            [self.tableView reloadData];
        }
    
    };
    
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:listGroupBlock failureBlock:^(NSError *error) {
        GCLogError([error localizedDescription]);
    }];
    
}

- (UIBarButtonItem *)setCancelButton
{
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];

    return cancelButton;
}

- (void)cancel
{
    if (self.cancelBlock)
        [self cancelBlock]();
}

#pragma mark - Setters

- (void)setAccountID:(NSString *)accountID
{
    if(![_accountID isEqualToString:accountID])
        _accountID = accountID;
}

- (void)setIsMultipleSelectionEnabled:(BOOL)isMultipleSelectionEnabled
{
    if(_isMultipleSelectionEnabled != isMultipleSelectionEnabled)
        _isMultipleSelectionEnabled = isMultipleSelectionEnabled;
}

- (void)setIsItDevice:(BOOL)isItDevice
{
    if(_isItDevice != isItDevice)
        _isItDevice = isItDevice;
}

- (void)setServiceName:(NSString *)serviceName
{
    if(_serviceName != serviceName)
        _serviceName = serviceName;
}

@end