/*
 Copyright 2017 Aram Sargsyan
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "RoomsListViewController.h"
#import "RoomTableViewCell.h"
@import MobileCoreServices;

@interface RoomsListViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSExtensionContext *shareExtensionContext;
@property (nonatomic) NSArray <MXRoom *> *rooms;
@property (nonatomic) UITableView *mainTableView;

@end


@implementation RoomsListViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureTableView];
}

#pragma mark - Public

+ (instancetype)listViewControllerWithContext:(NSExtensionContext *)context
{
    RoomsListViewController *listViewController = [[self class] new];
    listViewController.shareExtensionContext = context;
    return listViewController;
}

- (void)updateWithRooms:(NSArray <MXRoom *>*)rooms
{
    self.rooms = rooms;
    [self.mainTableView reloadData];
}

#pragma mark - Views

- (void)configureTableView
{
    self.mainTableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    self.mainTableView.dataSource = self;
    self.mainTableView.delegate = self;
    [self.mainTableView registerNib:[RoomTableViewCell nib] forCellReuseIdentifier:[RoomTableViewCell defaultReuseIdentifier]];
    
    [self.view addSubview:self.mainTableView];
    self.mainTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.mainTableView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
    widthConstraint.active = YES;
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.mainTableView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
    heightConstraint.active = YES;
    NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:self.mainTableView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    centerXConstraint.active = YES;
    NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:self.mainTableView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    centerYConstraint.active = YES;
}

#pragma mark - Private

- (void)sendToRoom:(MXRoom *)room
{
    NSString *UTTypeImage = (__bridge NSString *)kUTTypeImage;
    NSString *UTTypeVideo = (__bridge NSString *)kUTTypeVideo;
    
    for (NSExtensionItem *item in self.shareExtensionContext.inputItems)
    {
        for (NSItemProvider *itemProvider in item.attachments)
        {
            
            if ([itemProvider hasItemConformingToTypeIdentifier:UTTypeImage])
            {
                NSString *mimeType;
                if ([itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypeJPEG])
                {
                    mimeType = @"image/jpeg";
                }
                else if ([itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypePNG])
                {
                    mimeType = @"image/png";
                }
                [itemProvider loadItemForTypeIdentifier:UTTypeImage options:nil completionHandler:^(NSData *imageData, NSError * _Null_unspecified error)
                 {
                     //send the image
                     UIImage *image = [[UIImage alloc] initWithData:imageData];
                     [room sendImage:imageData withImageSize:image.size mimeType:mimeType andThumbnail:image localEcho:nil success:^(NSString *eventId)
                      {
                          [self.shareExtensionContext completeRequestReturningItems:@[item] completionHandler:nil];
                      }
                         failure:^(NSError *error)
                      {
                          
                      }];
                 }];
            }
            else if ([itemProvider hasItemConformingToTypeIdentifier:UTTypeVideo])
            {
                [itemProvider loadItemForTypeIdentifier:UTTypeVideo options:nil completionHandler:^(NSData *videoItem, NSError * _Null_unspecified error)
                 {
                     //send the video
                 }];
            }
            
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.rooms.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RoomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[RoomTableViewCell defaultReuseIdentifier]];
    MXRoom *room = self.rooms[indexPath.row];
    
    [cell render:room];
    if (!room.summary.displayname.length && !cell.titleLabel.text.length)
    {
        cell.titleLabel.text = NSLocalizedStringFromTable(@"room_displayname_no_title", @"Vector", nil);
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [RoomTableViewCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Send to %@", self.rooms[indexPath.row].riotDisplayname] message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"cancel", @"Vector", nil) style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    
    UIAlertAction *sendAction = [UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"send", @"Vector", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self sendToRoom:self.rooms[indexPath.row]];
    }];
    [alertController addAction:sendAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
