#import <UIKit/UIKit.h>
#import "RecordSession.h"
#import "ShareViewController.h"

typedef enum {
    PhotoType,
    VideoType
} PlayType;

@interface PlayerViewController : UIViewController

@property (strong, nonatomic) RecordSession *recordSession;
@property (strong, nonatomic) UIImage *photo;
//@property (strong, nonatomic) NSString *filterName;
@property (nonatomic, assign) NSUInteger scaleButtonState;
@property (nonatomic, assign) PlayType playType;

@end
