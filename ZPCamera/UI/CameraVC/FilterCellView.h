#import <UIKit/UIKit.h>

@interface FilterCellView : UICollectionViewCell

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIImageView *dotImgView;
@property (nonatomic, strong) CALayer *labelBGLayer;
@property (nonatomic, strong) CALayer *backgroundLayer;
@property (nonatomic, strong) CALayer *overlayLayer;

- (void)configWithFilter:(NSDictionary *)filter;

@end
