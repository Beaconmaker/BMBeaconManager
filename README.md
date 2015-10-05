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
