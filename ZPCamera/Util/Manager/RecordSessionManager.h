#import <Foundation/Foundation.h>
#import "RecoderManager.h"

@interface RecordSessionManager : NSObject

- (void)saveRecordSession:(RecordSession *)recordSession;

- (void)removeRecordSession:(RecordSession *)recordSession;

- (BOOL)isSaved:(RecordSession *)recordSession;

- (void)removeRecordSessionAtIndex:(NSInteger)index;

- (NSArray *)savedRecordSessions;

+ (RecordSessionManager *)sharedInstance;

@end
