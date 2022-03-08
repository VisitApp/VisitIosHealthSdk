#import <Foundation/Foundation.h>

@protocol VisitVideoCallDelegate

@end

@interface VisitVideoCallDelegate : UIViewController

-(void)segueToVideoCall:(NSString*) accessToken roomName:(NSString*) roomName doctorName:(NSString*) doctorName doctorProfileImg:(NSString*) doctorProfileImg;

@end
