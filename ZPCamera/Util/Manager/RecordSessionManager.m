#import "RecordSessionManager.h"
#import "RecordSession.h"
#define kUserDefaultsStorageKey @"RecordSessions"

@implementation RecordSessionManager

- (void)modifyMetadatas:(void(^)(NSMutableArray *metadatas))block {
    NSMutableArray *metadatas = [[self savedRecordSessions] mutableCopy];
    
    if (metadatas == nil) {
        metadatas = [NSMutableArray new];
    }

    block(metadatas);
    
    [[NSUserDefaults standardUserDefaults] setObject:metadatas forKey:kUserDefaultsStorageKey];
}

- (void)saveRecordSession:(RecordSession *)recordSession {
    [self modifyMetadatas:^(NSMutableArray *metadatas) {
        
        NSInteger insertIndex = -1;
        
        for (int i = 0; i < metadatas.count; i++) {
            NSDictionary *otherRecordSessionMetadata = [metadatas objectAtIndex:i];
            if ([otherRecordSessionMetadata[SCRecordSessionIdentifierKey] isEqualToString:recordSession.identifier]) {
                insertIndex = i;
                break;
            }
        }
        
        NSDictionary *metadata = recordSession.dictionaryRepresentation;
        
        if (insertIndex == -1) {
            [metadatas addObject:metadata];
        } else {
            [metadatas replaceObjectAtIndex:insertIndex withObject:metadata];
        }
    }];
}

- (void)removeRecordSession:(RecordSession *)recordSession {
    [self modifyMetadatas:^(NSMutableArray *metadatas) {
        
        for (int i = 0; i < metadatas.count; i++) {
            NSDictionary *otherRecordSessionMetadata = [metadatas objectAtIndex:i];
            if ([otherRecordSessionMetadata[SCRecordSessionIdentifierKey] isEqualToString:recordSession.identifier]) {
                i--;
                [metadatas removeObjectAtIndex:i];
                break;
            }
        }
    }];
}

- (BOOL)isSaved:(RecordSession *)recordSession {
    NSArray *sessions = [self savedRecordSessions];
    
    for (NSDictionary *session in sessions) {
        if ([session[SCRecordSessionIdentifierKey] isEqualToString:recordSession.identifier]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)removeRecordSessionAtIndex:(NSInteger)index {
    [self modifyMetadatas:^(NSMutableArray *metadatas) {
        [metadatas removeObjectAtIndex:index];
    }];
}

- (NSArray *)savedRecordSessions {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsStorageKey];
}

static RecordSessionManager *_sharedInstance;

+ (RecordSessionManager *)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [RecordSessionManager new];
    });
    
    return _sharedInstance;
}

@end
