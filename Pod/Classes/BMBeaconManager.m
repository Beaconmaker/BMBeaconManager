//
//  BMBeaconManager.m
//  Ranked
//
//  Created by John Kueh on 5/10/2015.
//  Copyright © 2015 Beaconmaker. All rights reserved.
//

#import "BMBeaconManager.h"
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@interface BMBeaconManager () <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation BMBeaconManager

+ (BMBeaconManager *)sharedManager {
    static dispatch_once_t onceToken;
    static BMBeaconManager *sharedManager = nil;
    dispatch_once(&onceToken, ^{
        sharedManager = [[BMBeaconManager alloc] init];
    });
    return sharedManager;
}

+ (CLBeacon *)nearestBeacon:(NSArray *)beacons {
    NSPredicate *beaconAccuracyPredicate = [NSPredicate predicateWithFormat:@"SELF.accuracy >= 0"];
    NSArray *filteredBeacons = [beacons filteredArrayUsingPredicate:beaconAccuracyPredicate];
    
    NSSortDescriptor *accuracySortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"accuracy" ascending:YES];
    NSArray *sortedBeacons = [filteredBeacons sortedArrayUsingDescriptors:@[accuracySortDescriptor]];
    
    CLBeacon *nearestBeacon = [sortedBeacons firstObject];
    DDLogVerbose(@"Filtered Beacons: Nearest Beacon #%@/%@ Distance: %.2f Signal: %ld", nearestBeacon.major, nearestBeacon.minor, nearestBeacon.accuracy, (long) nearestBeacon.rssi);
    return nearestBeacon;
}

+ (CLBeacon *)furthestBeacon:(NSArray *)beacons {
    NSPredicate *beaconAccuracyPredicate = [NSPredicate predicateWithFormat:@"SELF.accuracy >= 0"];
    NSArray *filteredBeacons = [beacons filteredArrayUsingPredicate:beaconAccuracyPredicate];
    
    NSSortDescriptor *accuracySortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"accuracy" ascending:YES];
    NSArray *sortedBeacons = [filteredBeacons sortedArrayUsingDescriptors:@[accuracySortDescriptor]];
    
    CLBeacon *furthestBeacon = [sortedBeacons lastObject];
    DDLogVerbose(@"Filtered Beacons: Nearest Beacon #%@/%@ Distance: %.2f Signal: %ld", furthestBeacon.major, furthestBeacon.minor, furthestBeacon.accuracy, (long) furthestBeacon.rssi);
    return furthestBeacon;
}

+ (NSArray *)filterBeacons:(NSArray *)beacons byMajor:(NSNumber *)major byMinor:(NSNumber *)minor {
    NSPredicate *majorPredicate = [NSPredicate predicateWithFormat:@"SELF.major = %d", [major intValue]];
    NSPredicate *minorPredicate = [NSPredicate predicateWithFormat:@"SELF.minor = %d", [minor intValue]];
    NSMutableArray *predicateArray;
    if ([major integerValue] >= 0) {
        [predicateArray addObject:majorPredicate];
    }
    if ([minor integerValue] >= 0) {
        [predicateArray addObject:minorPredicate];
    }
    NSCompoundPredicate *beaconsFilterPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicateArray];
    NSArray *filteredBeacons = [beacons filteredArrayUsingPredicate:beaconsFilterPredicate];
    DDLogVerbose(@"Filtered Beacons: - %ld Beacons found after filtering", (long) beacons.count);
    return filteredBeacons;
}

+ (BOOL)canMonitorAndRangeBeaconsInForeground {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    if (status == kCLAuthorizationStatusNotDetermined || status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
        return NO;
    } else {
        return YES;
    }
}

+ (BOOL)canMonitorBeaconsInBackground {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    if (status == kCLAuthorizationStatusNotDetermined || status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        return NO;
    } else {
        return YES;
    }
}

- (id)init {
    self = [super init];
    if (self) {
        self.locationManager = [CLLocationManager new];
        self.locationManager.delegate = self;
    }
    return self;
}

- (void)setRegions:(NSArray *)regions {
    _regions = regions;
}

- (void)requestForegroundMonitoringAndRangingAuthorization {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (![BMBeaconManager canMonitorAndRangeBeaconsInForeground]) {
        if (status == kCLAuthorizationStatusNotDetermined) {
            [self.locationManager requestWhenInUseAuthorization];
        }
        else if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
            [UIAlertController showAlertInViewController:[self topMostViewController] withTitle:@"Enable Location Services" message:@"To use this feature, this app needs Location services. \n\n 1. Click on the Settings button below \n 2. Set 'Location' to 'While Using...' \n3. Come back into this app" cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@[@"Settings", @"Cancel"] tapBlock:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action, NSInteger buttonIndex) {
                if (buttonIndex == 2) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                }
            }];
        }
    };
}

- (void)requestBackgroundMonitoringAuthorization {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (![BMBeaconManager canMonitorBeaconsInBackground]) {
        if (status == kCLAuthorizationStatusNotDetermined) {
            [self.locationManager requestAlwaysAuthorization];
        }
        else if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
            [UIAlertController showAlertInViewController:[self topMostViewController] withTitle:@"Enable Location Services" message:@"To use this feature, this app needs permission to obtain your location in the background. \n\n 1. Click on the Settings button below \n 2. Set 'Location' to 'Always' \n3. Come back into this app" cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@[@"Settings", @"Cancel"] tapBlock:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action, NSInteger buttonIndex) {
                if (buttonIndex == 2) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                }
            }];
        }
    };
}

- (void)startMonitoring {
    // Clear all previously monitored regions
    for (CLBeaconRegion *region in self.locationManager.monitoredRegions) {
        [self.locationManager stopMonitoringForRegion:region];
    }
    for (CLBeaconRegion *region in self.regions) {
        region.notifyOnEntry = YES;
        region.notifyOnExit = YES;
        region.notifyEntryStateOnDisplay = YES;
        [self.locationManager stopMonitoringForRegion:region];
        [self.locationManager startMonitoringForRegion:region];
        [self.locationManager requestStateForRegion:region];
        DDLogVerbose(@"(Monitoring) Started for CLBeaconRegion with UUID: %@", region.proximityUUID);
    }
}

- (void)stopMonitoring {
    for (CLBeaconRegion *region in self.regions) {
        [self.locationManager stopMonitoringForRegion:region];
        DDLogVerbose(@"(Monitoring) Stopped for CLBeaconRegion with UUID: %@", region.proximityUUID);
    }
}

- (void)startRanging {
    for (CLBeaconRegion *region in self.regions) {
        [self.locationManager stopRangingBeaconsInRegion:region];
        [self.locationManager startRangingBeaconsInRegion:region];
        DDLogVerbose(@"(Ranging) Started for CLBeaconRegion with UUID: %@", region.proximityUUID);
    }
}

- (void)stopRanging {
    for (CLBeaconRegion *region in self.regions) {
        [self.locationManager stopRangingBeaconsInRegion:region];
        DDLogVerbose(@"(Ranging) Stopped for CLBeaconRegion with UUID: %@", region.proximityUUID);
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    
    DDLogVerbose(@"<---- didRangeBeacons - %ld Beacons found in Region: %@", (long) beacons.count, region.identifier);
    
    for (CLBeacon *beacon in beacons) {
        DDLogVerbose(@" Maj:#%@ / Min:%@, Acc: %.2f:, RSSI: %ld", beacon.major, beacon.minor, beacon.accuracy, (long)beacon.rssi);
    }
    
    if ([self.delegate respondsToSelector:@selector(didRangeBeacons:)]) {
        [self.delegate didRangeBeacons:beacons];
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    DDLogError(@"<---- monitoringDidFailForRegion - %@. Reason: %@", region.identifier, error.localizedDescription);
    [self.locationManager stopMonitoringForRegion:region];
    [self stopMonitoring];
    
    if ([BMBeaconManager canMonitorAndRangeBeaconsInForeground]) {
        [self.locationManager startMonitoringForRegion:region];
        [self startMonitoring];
    }
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error {
    DDLogError(@"<---- rangingBeaconsDidFailForRegion - %@. Reason: %@", region.identifier, error.localizedDescription);
    [self.locationManager stopRangingBeaconsInRegion:region];
    [self stopRanging];
    
    if ([BMBeaconManager canMonitorAndRangeBeaconsInForeground]) {
        [self.locationManager startRangingBeaconsInRegion:region];
        [self startRanging];
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    DDLogVerbose(@"<---- didEnterRegion: %@", region.identifier);
    if ([self.delegate respondsToSelector:@selector(didEnterRegion:)]) {
        [self.delegate didEnterRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    DDLogVerbose(@"<---- didExitRegion: %@", region.identifier);
    if ([self.delegate respondsToSelector:@selector(didExitRegion:)]) {
        [self.delegate didExitRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    DDLogVerbose(@"<---- didStartMonitoringForRegion: %@", region.identifier);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            DDLogVerbose(@"<---- didChangeAuthorizationStatusTo: NotDetermined");
            break;
        case kCLAuthorizationStatusDenied:
            DDLogVerbose(@"<---- didChangeAuthorizationStatusTo: Denied");
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            DDLogVerbose(@"<---- didChangeAuthorizationStatusTo: WhenInUse");
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
            DDLogVerbose(@"<---- didChangeAuthorizationStatusTo: Always");
            break;
        default:
            break;
    }
    if ([self.delegate respondsToSelector:@selector(didChangeAuthorizationStatus:)]) {
        [self.delegate didChangeAuthorizationStatus:status];
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    switch (state) {
        case CLRegionStateInside:
            DDLogVerbose(@"<---- didDetermineState: Inside, for region: %@", region.identifier);
            break;
        case CLRegionStateOutside:
            DDLogVerbose(@"<---- didDetermineState: Outside, for region: %@", region.identifier);
            break;
        case CLRegionStateUnknown:
            DDLogVerbose(@"<---- didDetermineState: Unknown, for region: %@", region.identifier);
            break;
        default:
            DDLogVerbose(@"<---- didDetermineState: -, for region: %@", region.identifier);
    }
    if ([self.delegate respondsToSelector:@selector(didDetermineState:forRegion:)]) {
        [self.delegate didDetermineState:state forRegion:region];
    }
}

#pragma mark UIViewController Helper methods (for showing UIAlertController)
- (UIViewController *)topMostViewController {
    UIWindow *topWindow = [UIApplication sharedApplication].keyWindow;
    UIViewController *topViewController = topWindow.rootViewController;
    
    if (topViewController == nil) {
        // The windows in the array are ordered from back to front by window level; thus,
        // the last window in the array is on top of all other app windows.
        for (UIWindow *window in [[UIApplication sharedApplication].windows reverseObjectEnumerator]) {
            topViewController = window.rootViewController;
            if (topViewController)
                break;
        }
    }
    
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    return topViewController;
}

@end
