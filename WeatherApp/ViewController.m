//
//  ViewController.m
//  WeatherApp
//
//  Created by Lane on 8/18/15.
//  Copyright (c) 2015 Lane. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking/AFNetworking.h"
@import CoreLocation;

#define WEATHER_REQUEST_URL @"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f"


@interface ViewController()<CLLocationManagerDelegate>
@property (strong ,nonatomic) CLLocationManager *locationManager;
@property (nonatomic) double systemVersion;
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //init the locationManager and set the accuracy
    self.locationManager=[[CLLocationManager alloc] init];
    
    //set the locationManager delegate to the class(#important!)
    //#need add 'NSLocationAlwaysUsageDescription' in Info.plist file.#//
    //#or the notification to use location would not show!!#//
    self.locationManager.delegate=self;
    
    self.locationManager.desiredAccuracy=kCLLocationAccuracyBest;
    if ([self isIOS8]) {
        [self.locationManager requestAlwaysAuthorization];
    }
    [self.locationManager startUpdatingLocation];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    CLLocation *theLocation=locations[locations.count-1];
    if (theLocation.horizontalAccuracy>0) {
        NSLog(@"%f   %f",theLocation.coordinate.latitude,theLocation.coordinate.longitude);
        [self updateWeatherInfo:theLocation.coordinate.latitude withLongitude:theLocation.coordinate.longitude];
        [self.locationManager stopUpdatingLocation];
    }
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"%@",error);
}

//add update weather info method
- (void) updateWeatherInfo:(double)latitude withLongitude:(double)longtitude{
    AFHTTPRequestOperationManager *netManager=[[AFHTTPRequestOperationManager alloc] init];
    NSString *reqURL=[NSString stringWithFormat:WEATHER_REQUEST_URL,latitude,longtitude];
    NSLog(@"%@",reqURL);
    [netManager GET:reqURL parameters:nil success:
     ^(AFHTTPRequestOperation *operation, id responseObject) {
         NSDictionary *responseData=responseObject;
         NSLog(@"%@",responseData);
     }failure:
     ^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"%@",error.description);
     }];
}

//check the device system version
- (BOOL) isIOS8{
    UIDevice *myDevice=[UIDevice currentDevice];
    self.systemVersion=[myDevice.systemVersion doubleValue];
    NSLog(@"systemVersion is %@",myDevice.systemVersion);
    if (self.systemVersion>8.0) {
        return true;
    }else{
        return false;
    }
}

@end
