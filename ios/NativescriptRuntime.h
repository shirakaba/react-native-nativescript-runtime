#import <React/RCTBridgeModule.h>

@interface NativescriptRuntime : NSObject <RCTBridgeModule>

@property int messageCount;
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSDictionary*> *pendingMessages;

@end
