//
//  VisitVideoCallDelegate.m
//  VisitIosHealthSdk
//
//  Created by Yash on 08/03/22.
//

#import <Foundation/Foundation.h>
#import <VisitIosHealthSdk-Swift.h>
#import "VisitVideoCallDelegate.h"
#import "VisitIosHealthController.h"

@implementation VisitVideoCallDelegate

- (void) segueToVideoCall:(NSString *)accessToken roomName:(NSString *)roomName doctorName:(NSString *)doctorName doctorProfileImg:(NSString *)doctorProfileImg{
    NSBundle* podBundle = [NSBundle bundleForClass:[VisitIosHealthController class]];
    NSURL* bundleUrl = [podBundle URLForResource:@"VisitIosHealthSdk" withExtension:@"bundle"];
    NSBundle* bundle = [NSBundle bundleWithURL:bundleUrl];
    NSLog(@"bundleUrl is, %@",podBundle);
    VideoCallViewController* videoCallController = [[VideoCallViewController alloc] initWithNibName:@"VideoCallView" bundle:bundle];
    [bundle loadNibNamed:@"VideoCallView" owner:videoCallController options:nil];
    videoCallController.modalPresentationStyle = 0;
    [self presentViewController:videoCallController animated:true completion:^{[videoCallController connectWithAccessToken:accessToken roomName:roomName doctorName:doctorName doctorProfileImg:doctorProfileImg];}];
}

@end
