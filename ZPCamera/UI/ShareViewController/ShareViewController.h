#import <UIKit/UIKit.h>

@interface ShareViewController : UIViewController

@property (nonatomic, strong) UIImage *photo;

- (instancetype)initWithTitleText:(NSString *)text sampleFile:(NSDictionary *)dictionary;
- (void)closeButtonTap;

@end
