# BMBeaconManager

BMBeaconManager is a LocationManager singleton that abstracts the handling of requesting user permissions for various types of ranging/monitoring and all the other kinks of CLLocationManager like resetting regions when monitoring has failed. 

## Installation with CocoaPods

BMBeaconManager is available on the Beaconmaker Github account. To install
it, simply add the following line to your Podfile:

```ruby
pod 'BMBeaconManager', :git => 'https://github.com/Beaconmaker/BMBeaconManager.git'
```

## Usage
1. Use ```#import "BMBeaconManager.h"``` in your implementation files.
2. Reference of public methods and delegate callbacks can be found in the BMBeaconManager.h header file.

### Checking/Requesting Location Permissions
- ```[BMBeaconManager canMonitorAndRangeBeaconsInForeground];```
- ```[BMBeaconManager canMonitorBeaconsInBackground];```
- ```[BMBeaconManager sharedManager] requestForegroundMonitoringAndRangingAuthorization];``` (requests for WhileInUse authorization and if user already denied it, show alert with deeplink to settings)
- ```[BMBeaconManager sharedManager] requestBackgroundMonitoringAuthorization];``` (requests for Always authorization and if user already denied it, show alert with deeplink to settings)

### Monitoring/Ranging Beacons
1. ```[BMBeaconManager sharedManager] setRegions:<<YOUR_ARRAY_OF_CL_REGIONS>>];```
2. ```[BMBeaconManager sharedManager] startMonitoring];```
3. ```[BMBeaconManager sharedManager] startRanging];```

### Delegate Callbacks
1. Make your ViewController conform to the BMBeaconManager Delegate Protocol ```@interface YourViewController () <BMBeaconManagerDelegate>```
2. Implement delegate callback methods
```
- (void)didChangeAuthorizationStatus:(CLAuthorizationStatus)status {}
- (void)didEnterRegion:(CLRegion *)region {}
- (void)didExitRegion:(CLRegion *)region {}
- (void)didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {}
- (void)didRangeBeacons:(NSArray *)beacons {}```

### Helper Methods
1. ```[BMBeaconManager nearestBeacon:<<ARRAY_OF_CL_BEACONS>>];``` (returns the nearest beacon from an array of beacons)
2. ```[BMBeaconManager furthestBeacon:<<ARRAY_OF_CL_BEACONS>>];``` (returns the furthest beacon from an array of beacons)
3. ```[BMBeaconManager filterBeacons:<<ARRAY_OF_CL_BEACONS>> byMajor:<<MAJOR_NSNUMBER>> byMinor:<<MINOR_NSNUMBER>>];``` (returns an array of beacons filtered using major/minor)