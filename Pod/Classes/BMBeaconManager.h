//
//  BMBeaconManager.h
//  Ranked
//
//  Created by John Kueh on 5/10/2015.
//  Copyright © 2015 Beaconmaker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIAlertController+Blocks.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

@import CoreLocation;

@protocol BMBeaconManagerDelegate <NSObject>
@optional
- (void)didRangeBeacons:(NSArray *)beacons;
- (void)didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region;
- (void)didEnterRegion:(CLRegion *)region;
- (void)didExitRegion:(CLRegion *)region;
- (void)didChangeAuthorizationStatus:(CLAuthorizationStatus)status;

- (void)didUpdateNearestBeacon:(CLBeacon *)beacon;
@end

@interface BMBeaconManager : NSObject

@property (strong, nonatomic) NSArray *regions;

+ (BMBeaconManager *)sharedManager;

// Helper methods
+ (CLBeacon *)nearestBeacon:(NSArray *)beacons;
+ (CLBeacon *)furthestBeacon:(NSArray *)beacons;
+ (NSArray *)filterBeacons:(NSArray *)beacons byMajor:(NSNumber *)major byMinor:(NSNumber *)minor;
+ (BOOL)canMonitorAndRangeBeaconsInForeground;
+ (BOOL)canMonitorBeaconsInBackground;

- (void)requestForegroundMonitoringAndRangingAuthorization;
/*  1. Remember to add NSLocationWhenInUseUsageDescription into Info.plist
        - e.g We need you to allow location permission to enable us to show you whats nearby. You can disable this setting anytime you want.
*/

- (void)requestBackgroundMonitoringAuthorization;
/*  1. Remember to add NSLocationAlwaysUsageDescription into Info.plist
        - e.g We need you to allow location permission to enable automatic check ins. You can disable this        setting anytime you want.
    2. Remember to request for User's permission to send notification if you want to schedule it in the background:
        - [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings
                                  settingsForTypes:UIUserNotificationTypeAlert
                                  categories:nil]]; 
*/

// Monitoring/ranging methods
- (void)startMonitoring;
- (void)stopMonitoring;

- (void)startRanging;
- (void)stopRanging;

@property (nonatomic, weak) id <BMBeaconManagerDelegate> delegate;
@end
