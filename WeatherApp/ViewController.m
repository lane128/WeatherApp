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
#define UIColorFromRGB(rgbValue) \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0x00FF00) >>  8))/255.0 \
blue:((float)((rgbValue & 0x0000FF) >>  0))/255.0 \
alpha:0.6]


@interface ViewController()<CLLocationManagerDelegate>
@property (strong ,nonatomic) CLLocationManager *locationManager;
@property (nonatomic) double systemVersion;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel;
@property (weak, nonatomic) IBOutlet UIImageView *weatherIcon;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIcon;

@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.loadingIcon.hidden=true;
    self.view.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"day"]];
    
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
    
    //set the activity indicator style
    self.loadingIcon.activityIndicatorViewStyle=UIActivityIndicatorViewStyleWhiteLarge;
    
    [self reFresh];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)reFreshData:(id)sender {
    [self reFresh];
}

- (void) reFresh{
    [self.locationManager startUpdatingLocation];
    self.loadingIcon.hidden=false;
    [self.loadingIcon startAnimating];
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

//add request weather info method
- (void) updateWeatherInfo:(double)latitude withLongitude:(double)longtitude{
    AFHTTPRequestOperationManager *netManager=[[AFHTTPRequestOperationManager alloc] init];
    NSString *reqURL=[NSString stringWithFormat:WEATHER_REQUEST_URL,latitude,longtitude];
    NSLog(@"%@",reqURL);
    [netManager GET:reqURL parameters:nil success:
     ^(AFHTTPRequestOperation *operation, id responseObject) {
         NSDictionary *responseData=responseObject;
         //update weather info.
         [self bindWeatherInfo:responseData];
     }failure:
     ^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"%@",error.description);
     }];
}

//bind response weather data info to the view.
- (void) bindWeatherInfo:(NSDictionary *) data{
    NSMutableString *countryInfo;
    int tempDoubleType;
    //bind temperatureLabel
    if (data[@"main"]!=NULL&&data[@"main"][@"temp"]!=NULL) {
        //check the country info (US use the F,others use C)
        if (data[@"sys"]!=NULL&&data[@"sys"][@"country"]!=NULL) {
            countryInfo=[NSMutableString stringWithFormat:@"%@",data[@"sys"][@"country"]];
        }else{
            countryInfo=[NSMutableString stringWithFormat:@"%@",@"N/A"];
        }
        tempDoubleType=[data[@"main"][@"temp"] doubleValue];
        if ([countryInfo isEqual:@"US"]) {
            tempDoubleType=round(((tempDoubleType-273.15)*1.8)+32);
            self.temperatureLabel.text= [NSString stringWithFormat:@"%i°F",tempDoubleType];
        }else{
            tempDoubleType=round(tempDoubleType-273.15);
            self.temperatureLabel.text= [NSString stringWithFormat:@"%i°C",tempDoubleType];
        }
    }else{
        self.temperatureLabel.text= @"N/A";
    }
    //bind locatioinLabel
    if (data[@"name"]!=NULL) {
        self.locationLabel.text=[NSString stringWithFormat:@"%@",data[@"name"]];
    }else{
        self.locationLabel.text=@"N/A";
    }
    
    //bind image icon of weather
    int weatherId=0;
    if (data[@"sys"]!=NULL&&data[@"sys"][@"id"]) {
        weatherId=[data[@"sys"][@"id"] intValue];
        //stop the indicator
        [self.loadingIcon stopAnimating];
        //use animation to change the weather icon
        self.weatherIcon.hidden=true;
        self.loadingIcon.hidden=true;
        [self bindWeatherIcon:weatherId];
        
        [UIView transitionWithView:self.weatherIcon duration:1.5 options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
            self.weatherIcon.hidden=false;
            
        } completion:nil];
        
        
    }
    //check the weather is sunset or sunrise
    BOOL isNight=false;
    NSDate *nowTime=[[NSDate alloc] init];
    int secFrom1970=round([nowTime timeIntervalSince1970]);
    if (data[@"sys"]!=NULL&&data[@"sys"][@"sunrise"]&&data[@"sys"][@"sunset"]) {
        int sunriseSec=round([data[@"sys"][@"sunrise"] integerValue]);
        int sunsetSec=round([data[@"sys"][@"sunset"] integerValue]);
        if (secFrom1970<sunriseSec||secFrom1970>sunsetSec) {
            isNight=true;
            self.view.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"night"]];
        }else{
            self.view.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"day"]];
        }
    }
    
    
}

//check the kind of weather and bind icon method
- (void) bindWeatherIcon:(int) weatherId{
    if (weatherId<300) {
        self.weatherIcon.image=[UIImage imageNamed:@"thunder"];
    }else if (weatherId<400){
        self.weatherIcon.image=[UIImage imageNamed:@"showder"];
    }else if (weatherId<600){
        self.weatherIcon.image=[UIImage imageNamed:@"rain"];
    }else if (weatherId<700){
        self.weatherIcon.image=[UIImage imageNamed:@"snow"];
    }else if (weatherId<800){
        self.weatherIcon.image=[UIImage imageNamed:@"cloud"];
    }else if (weatherId<900){
        self.weatherIcon.image=[UIImage imageNamed:@"cloud"];
    }else{
        //some weather I don't have Icon....(to do...)
    }
}

//check the device system version method
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
