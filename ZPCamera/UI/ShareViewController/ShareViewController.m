#import "ShareViewController.h"
#import "OpenShareHeader.h"

typedef enum { kWechatSession = 0, kWechatTimeline, kQZone, kQQ } SharePlatformType;

@interface ShareViewController ()

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSDictionary *dictionary;

@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) NSArray *shareArray;

@end

@implementation ShareViewController

- (instancetype)initWithTitleText:(NSString *)text
                      sampleFile:(NSDictionary *)dictionary {
    if (self = [super init]) {
        _text = text;
        _dictionary = dictionary;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.layer.cornerRadius = 5.f;
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.layer.masksToBounds = YES;
    [self addCloseButton];
    [self addTitleLabel];
    
    self.shareArray = @[@{@"image": @"wechat", @"title": @"微信好友", @"type": @(kWechatSession)}, @{@"image": @"timeline", @"title": @"朋友圈", @"type": @(kWechatTimeline)}, @{@"image": @"qq", @"title": @"QQ好友", @"type": @(kQQ)}, @{@"image": @"qzone", @"title": @"QQ空间", @"type": @(kQZone)}];
    
    NSInteger lineCount = 2;
    CGFloat width = self.view.frame.size.width - 60 * kScale;
    CGFloat buttonWidth = IS_IPHONE_6P ? 58 : 52;
    CGFloat gap = (width - buttonWidth * lineCount) / 3.0;
    CGFloat buttonHeight = ceil(buttonWidth * kScale) + 10;
    for (int i = 0; i < self.shareArray.count; i++) {
        NSDictionary *shareDict = self.shareArray[i];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setImage:[UIImage imageNamed:shareDict[@"image"]] forState:UIControlStateNormal];
        [button setTitle:shareDict[@"title"] forState:UIControlStateNormal];
        [button setTitleColor:UIColorFromRGB(0x777777) forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:13];
        button.frame = CGRectMake(gap + (buttonWidth + gap) * (i % lineCount), 55 + (buttonHeight + 18) * (i / lineCount), buttonWidth, buttonHeight);
        button.tag = i;
        [button addTarget:self action:@selector(shareAction:) forControlEvents:UIControlEventTouchUpInside];
        
        CGSize imageSize = button.imageView.frame.size;
        CGSize titleSize = button.titleLabel.frame.size;
        CGFloat padding = IS_IPHONE_6P ? 11 : 6.0;
        CGFloat totalHeight = (imageSize.height + titleSize.height + padding);
        
        button.imageEdgeInsets = UIEdgeInsetsMake(- (totalHeight - imageSize.height), 0.0f, 0.0f, - titleSize.width);
        button.titleEdgeInsets = UIEdgeInsetsMake(0.0f, - imageSize.width - 3, - (totalHeight - titleSize.height), 0.0f);
        button.contentEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, titleSize.height, 0.0f);
        
        [self.view addSubview:button];
    }
    
}

#pragma mark - Private Instance methods
- (void)addCloseButton {
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    [closeButton setEnlargeEdgeWithTop:5 right:5 bottom:5 left:5];
    closeButton.frame = CGRectMake(10 * kScale, 10 * kScale, 21, 21);
    [closeButton addTarget:self action:@selector(closeButtonTap) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:closeButton];
}

- (void)addTitleLabel {
    UILabel *label = [[UILabel alloc] init];
    label.text = self.text;
    label.font = [UIFont systemFontOfSize:15];
    label.textColor = UIColorFromRGB(0x000000);
    [label sizeToFit];
    label.centerX = (ScreenWidth - 60 * kScale) / 2.0;
    CGRect rect = label.frame;
    rect.origin.y = 12 * kScale;
    label.frame = rect;
    
    [self.view addSubview:label];
}

- (void)closeButtonTap {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)shareAction:(UIButton *)UIButton {
    NSInteger index = UIButton.tag;
    NSDictionary *shareDict = self.shareArray[index];
    SharePlatformType type = (SharePlatformType)[shareDict[@"type"] integerValue];
    
    OSMessage *msg = [[OSMessage alloc] init];
    msg.title = @"Osho 相机";
    msg.image = self.photo;
    msg.thumbnail = [self.photo scaleImageToSize:CGSizeMake(60,60)];
    msg.desc = @"";
    
    switch (type) {
        case kWechatSession: {
            if ([OpenShare isWeixinInstalled]) {
                [OpenShare shareToWeixinSession:msg Success:^(OSMessage *message) {
                    
                } Fail:^(OSMessage *message, NSError *error) {
                    
                }];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"未检测到微信客户端" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil] show];
            }
            
        }
            break;
        case kWechatTimeline: {
            if ([OpenShare isWeixinInstalled]) {
                [OpenShare shareToWeixinTimeline:msg Success:^(OSMessage *message) {
                    
                } Fail:^(OSMessage *message, NSError *error) {
                    
                }];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"未检测到微信客户端" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil] show];
            }
            
        }
            break;
        case kQQ: {
            if ([OpenShare isQQInstalled]) {
                [OpenShare shareToQQFriends:msg Success:^(OSMessage *message) {
                    
                } Fail:^(OSMessage *message, NSError *error) {
                   
                }];
            } else {
                 [[[UIAlertView alloc] initWithTitle:@"未检测到 QQ 客户端" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil] show];
            }
            
        }
            break;
        case kQZone: {
            if ([OpenShare isQQInstalled]) {
                [OpenShare shareToQQZone:msg Success:^(OSMessage *message) {
                    
                } Fail:^(OSMessage *message, NSError *error) {
                    
                }];
            } else {
                 [[[UIAlertView alloc] initWithTitle:@"未检测到 QQ 客户端" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil] show];
            }
            
        }
            break;
            
        default:
            break;
    }
}

@end
