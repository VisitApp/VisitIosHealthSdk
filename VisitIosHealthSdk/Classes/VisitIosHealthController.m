//
//  VisitIosHealthController.m
//  ios-health
//
//  Created by Yash on 18/01/22.
//

#import "VisitIosHealthController.h"

@interface VisitIosHealthController ()

@end

@implementation VisitIosHealthController
//- (instancetype)init{
//    self = [super init];
//      if(self != nil) {
//        // do init stuff
//          NSLog(@"VisitIosHealthController init called");
//      //    // Do any additional setup after loading the view.
//      //      NSBundle* bun = [NSBundle bundleWithIdentifier:@"com.getvisitapp.visitIosHealthKit"];
//          NSBundle* podBundle = [NSBundle bundleForClass:[self class]];
//          NSURL* bundleUrl = [podBundle URLForResource:@"VisitIosHealthSdk" withExtension:@"bundle"];
//          NSBundle* bundle = [NSBundle bundleWithURL:bundleUrl];
//          UIStoryboard* storyboard;
//          storyboard = [UIStoryboard storyboardWithName:@"Loader" bundle:bundle];
//
//          storyboardVC = [storyboard instantiateInitialViewController];
//          storyboardVC.modalPresentationStyle = 0;
//          if (@available(iOS 13.0, *)) {
//              activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
//          } else {
//              // Fallback on earlier versions
//          }
//          activityIndicator.center = storyboardVC.view.center;
//          if (@available(iOS 13.0, *)) {
//              activityIndicator.color = UIColor.linkColor;
//          } else {
//              // Fallback on earlier versions
//          }
//          [storyboardVC.view addSubview:activityIndicator];
//          [activityIndicator startAnimating];
//          UIViewController *yourCurrentViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
//
//          while (yourCurrentViewController.presentedViewController)
//          {
//             yourCurrentViewController = yourCurrentViewController.presentedViewController;
//          }
//
//          [yourCurrentViewController presentViewController:storyboardVC animated:false completion:nil];
//      }
//    return self;
//}

- (void)viewDidLoad {
    [super viewDidLoad];
//    NSLog(@"VisitIosHealthController viewDidLoad called");
////    // Do any additional setup after loading the view.
////      NSBundle* bun = [NSBundle bundleWithIdentifier:@"com.getvisitapp.visitIosHealthKit"];
//    NSBundle* bun = [NSBundle bundleForClass:[self class]];
//    UIStoryboard* storyboard;
//    storyboard = [UIStoryboard storyboardWithName:@"Loader" bundle:bun];
//    storyboardVC = [storyboard instantiateInitialViewController];
//    storyboardVC.modalPresentationStyle = 0;
//    if (@available(iOS 13.0, *)) {
//        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
//    } else {
//        // Fallback on earlier versions
//    }
//    activityIndicator.center = storyboardVC.view.center;
//    if (@available(iOS 13.0, *)) {
//        activityIndicator.color = UIColor.linkColor;
//    } else {
//        // Fallback on earlier versions
//    }
//    [storyboardVC.view addSubview:activityIndicator];
//    [activityIndicator startAnimating];
//    UIViewController *yourCurrentViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
//
//    while (yourCurrentViewController.presentedViewController)
//    {
//       yourCurrentViewController = yourCurrentViewController.presentedViewController;
//    }
//
//    [yourCurrentViewController presentViewController:storyboardVC animated:false completion:nil];
//    [self presentViewController:storyboardVC animated:false completion:nil];
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    [config.userContentController
              addScriptMessageHandler:self name:@"visitIosView"];
    webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:config];
    [webView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:NSKeyValueObservingOptionNew context:NULL];
    calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierISO8601];
    calendar.timeZone = [NSTimeZone timeZoneWithName:@"IST"];
    gender = @"Not Set";
    [self.view addSubview:webView];
}

+ (HKHealthStore *)sharedManager {
    __strong static HKHealthStore *store = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[HKHealthStore alloc] init];
    });

    return store;
}

+ (NSString *)stringFromDate:(NSDate *)date {
    __strong static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    });

    return [formatter stringFromDate:date];
}

- (NSDate *)convertStringToDate:(NSString *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    NSLocale *posix = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [formatter setLocale:posix];
    return [formatter dateFromString:date];
}


- (void)requestAuthorization {
    
    if ([HKHealthStore isHealthDataAvailable] == NO) {
        // If our device doesn't support HealthKit -> return.
        return;
    }
    NSArray *writeTypes = @[[HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]];
    NSArray *readTypes = @[[HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount],
                           [HKSampleType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis],
                           [HKSampleType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex],
                           [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning]];
    
    [[VisitIosHealthController sharedManager] requestAuthorizationToShareTypes:[NSSet setWithArray:writeTypes] readTypes:[NSSet setWithArray:readTypes]
                                                                completion:^(BOOL success, NSError *error) {
        NSLog(@"requestAuthorizationToShareTypes executed");
        [self canAccessHealthKit:^(BOOL value){
            if(value){
                NSLog(@"the health kit permission granted");
                [self onHealthKitPermissionGranted];
            }else{
                NSLog(@"the health kit permission not granted");
                UIAlertController * alert = [UIAlertController
                                                 alertControllerWithTitle:@"Permission Denied"
                                                 message:@"Please go to Settings>Privacy>Health and approve the required permissions"
                                                 preferredStyle:UIAlertControllerStyleAlert];

                    //Add Buttons

                    UIAlertAction* yesButton = [UIAlertAction
                                                actionWithTitle:@"Go to Settings"
                                                style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                                                }];
                UIAlertAction* noButton = [UIAlertAction
                                           actionWithTitle:@"Cancel"
                                           style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction * action) {
                                               //Handle no, thanks button
                                           }];
                //Add your buttons to alert controller

                [alert addAction:yesButton];
                [alert addAction:noButton];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self presentViewController:alert animated:false completion:nil];
                });
            }
        }];
    }];
}

-(void) onHealthKitPermissionGranted{
    dispatch_group_t loadDetailsGroup=dispatch_group_create();
    __block NSString* numberOfSteps = 0;
    __block NSTimeInterval totalSleepTime = 0;
    NSLog(@"gender is, %@",gender);
    for (int i = 0; i<2; i++) {
        
        dispatch_group_enter(loadDetailsGroup);
        if(i==0){
            //  getting steps for current day
            [self fetchSteps:@"day" endDate:[NSDate date] callback:^(NSArray * result) {
                if([[result objectAtIndex:0] count]>0){
                    numberOfSteps = [[result objectAtIndex:0] objectAtIndex:0];
                }
                dispatch_group_leave(loadDetailsGroup);
            }];
        }else if (i==1){
            //  getting sleep pattern for the day past
            [self fetchSleepPattern:[NSDate date] frequency:@"day" callback:^(NSArray * result) {
                if([result count]>0){
                    for (NSDictionary* item in result) {
                        NSString* sleepValue = [item valueForKey:@"value"];
                        if([sleepValue isEqualToString:@"INBED"]||[sleepValue isEqualToString:@"ASLEEP"]){
                            NSDate* startDate = [item valueForKey:@"startDate"];
                            NSDate* endDate = [item valueForKey:@"endDate"];
                            NSTimeInterval duration = [endDate timeIntervalSinceDate:startDate] / 60;
                            totalSleepTime+=duration;
                            NSLog(@"Sleep value is, %@, while duration is %f",sleepValue,duration);
                    }
                    }
                }
                dispatch_group_leave(loadDetailsGroup);
            }];
        }
    }

    // Now outside the loop wait until everything is done. NOTE: this will
    // not block execution, the provided block will be called
    // asynchronously at a later point.
    dispatch_group_notify(loadDetailsGroup,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        self->gender= [self readGender];
        if([self->gender isEqualToString:@"Male"]){
            self->bmrCaloriesPerHour = 1662 / 24;
        }else{
            self->bmrCaloriesPerHour = 1493 / 24;
        }
        NSLog(@"the steps result is, %@",numberOfSteps);
        NSLog(@"total sleep time is %f",totalSleepTime);
        NSInteger sleepTime = totalSleepTime;
        //        -[WKWebView loadRequest:] must be used from main thread only
        if(!self->hasLoadedOnce){
            NSString *javascript = [NSString stringWithFormat:@"updateFitnessPermissions(true,'%@','%ld')",numberOfSteps, sleepTime];
            dispatch_async(dispatch_get_main_queue(), ^{
                self->hasLoadedOnce = true;
                [self->webView evaluateJavaScript:javascript completionHandler:^(NSString *result, NSError *error) {
                    if(error != nil) {
                        NSLog(@"SomeFunction Error: %@",error);
                        return;
                    }
                    NSLog(@"SomeFunction Success %@",result);
                }];
            });
        }
    });
}

+ (NSString *)buildISO8601StringFromDate:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    NSLocale *posix = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.locale = posix;
    dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZ";
    return [dateFormatter stringFromDate:date];
}


- (void)fetchSleepCategorySamplesForPredicate:(NSPredicate *)predicate
                                   limit:(NSUInteger)lim
                                   completion:(void (^)(NSArray *, NSError *))completion {


    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate
                                                                       ascending:true];


    // declare the block
    void (^handlerBlock)(HKSampleQuery *query, NSArray *results, NSError *error);
    // create and assign the block
    handlerBlock = ^(HKSampleQuery *query, NSArray *results, NSError *error) {
        if (!results) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }

        if (completion) {
            NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];

            dispatch_async(dispatch_get_main_queue(), ^{

                for (HKCategorySample *sample in results) {

                    NSInteger val = sample.value;

                    NSString *valueString;

                    switch (val) {
                      case HKCategoryValueSleepAnalysisInBed:
                        valueString = @"INBED";
                      break;
                      case HKCategoryValueSleepAnalysisAsleep:
                        valueString = @"ASLEEP";
                      break;
                     default:
                        valueString = @"UNKNOWN";
                     break;
                  }

                    NSDictionary *elem = @{
                            @"value" : valueString,
                            @"startDate" : sample.startDate,
                            @"endDate" : sample.endDate,
                    };

                    [data addObject:elem];
                }

                completion(data, error);
            });
        }
    };

    HKCategoryType *categoryType = [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:categoryType
                                                          predicate:predicate
                                                              limit:lim
                                                    sortDescriptors:@[timeSortDescriptor]
                                                     resultsHandler:handlerBlock];
    
    [[VisitIosHealthController sharedManager] executeQuery:query];
}


-(void) fetchDistanceWalkingRunning:(NSString*) frequency endDate:(NSDate*) endDate callback:(void(^)(NSArray*))callback{
    NSDateComponents *interval = [[NSDateComponents alloc] init];
    NSDate *startDate;
    interval.day = 1;
    NSDate *endDatePeriod;
    HKUnit *distanceUnit = [HKUnit meterUnit];
    if([frequency isEqualToString:@"day"]){
        endDatePeriod = endDate;
        startDate = [calendar dateByAddingUnit:NSCalendarUnitDay
                                                 value:0
                                                toDate:endDatePeriod
                                               options:0];
    }else if ([frequency isEqualToString:@"week"]){
        NSTimeInterval interval;
        [calendar rangeOfUnit:NSCalendarUnitWeekOfYear
                           startDate:&startDate
                            interval:&interval
                             forDate:endDate];
        endDatePeriod = [startDate dateByAddingTimeInterval:interval-1];
    }else if ([frequency isEqualToString:@"month"]){
        NSTimeInterval interval;
        [calendar rangeOfUnit:NSCalendarUnitMonth
                           startDate:&startDate
                            interval:&interval
                             forDate:endDate];
        endDatePeriod = [startDate dateByAddingTimeInterval:interval-1];
    }
    NSLog(@"startDate and endDate in fetchDistanceWalkingRunning is, %@, %@",startDate,endDatePeriod);
    NSDateComponents *anchorComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                                     fromDate:[NSDate date]];
    anchorComponents.hour = 0;
    NSDate *anchorDate = [calendar dateFromComponents:anchorComponents];
    HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    // Create the query
    HKStatisticsCollectionQuery *query = [[HKStatisticsCollectionQuery alloc] initWithQuantityType:quantityType
                                                                           quantitySamplePredicate:nil
                                                                                           options:HKStatisticsOptionCumulativeSum
                                                                                        anchorDate:anchorDate
                                                                                intervalComponents:interval];

    // Set the results handler
    query.initialResultsHandler = ^(HKStatisticsCollectionQuery *query, HKStatisticsCollection *results, NSError *error) {
        if (error) {
            // Perform proper error handling here
            NSLog(@"*** An error occurred while calculating the statistics: %@ ***",error.localizedDescription);
        }
        NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];
        
        [results enumerateStatisticsFromDate:startDate
                                      toDate:endDatePeriod
                                   withBlock:^(HKStatistics *result, BOOL *stop) {

                                       HKQuantity *quantity = result.sumQuantity;
                                       if (quantity) {
                                           int value = [[NSNumber numberWithInt:[quantity doubleValueForUnit:distanceUnit]] intValue];
                                           NSLog(@"in fetchDistanceWalkingRunning %d", value);
                                           
                                           [data addObject:[NSNumber numberWithInt:value]];
                                       }else{
                                           [data addObject:[NSNumber numberWithInt:0]];
                                       }
                                   }];
        callback(data);
    };

    [[VisitIosHealthController sharedManager] executeQuery:query];
}

-(bool)containsPositiveValue:(NSArray *)numberArray
{
    bool result = NO;

    for (NSNumber *obj in numberArray)
    {
        if([obj integerValue])
        {
            result = YES;
            break;
        }
    }

    return result;
}

-(void) fetchHourlyDistanceWalkingRunning:(NSDate*) endDate callback:(void(^)(NSArray*))callback{
    HKQuantityType *distanceType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *startDate = [[NSCalendar calendarWithIdentifier:NSCalendarIdentifierISO8601] startOfDayForDate:endDate];
        HKUnit *distanceUnit = [HKUnit meterUnit];
        NSDateComponents *interval = [[NSDateComponents alloc] init];
        interval.hour = 1;
        
        NSDate *anchorDate = [calendar startOfDayForDate:startDate];
        NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
        NSPredicate *userEnteredValuePredicate = [HKQuery predicateForObjectsWithMetadataKey:HKMetadataKeyWasUserEntered operatorType: NSNotEqualToPredicateOperatorType value: @YES];
        
        NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, userEnteredValuePredicate]];
        
        HKStatisticsCollectionQuery *query = [[HKStatisticsCollectionQuery alloc] initWithQuantityType:distanceType quantitySamplePredicate:compoundPredicate options:HKStatisticsOptionCumulativeSum anchorDate:anchorDate intervalComponents:interval];
        
        query.initialResultsHandler = ^(HKStatisticsCollectionQuery * _Nonnull query, HKStatisticsCollection * _Nullable result, NSError * _Nullable error) {
            if (error) {
                NSLog(@"*** An error occurred while calculating the statistics: %@ ***",
                      error.localizedDescription);
                return;
            }
            
            NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];
            NSMutableArray *distanceData = [NSMutableArray arrayWithCapacity:24];
            [result enumerateStatisticsFromDate:startDate toDate:endDate withBlock:^(HKStatistics * _Nonnull result, BOOL * _Nonnull stop) {
                HKQuantity *quantity = result.sumQuantity;
                if (quantity) {
                    int value =(int) [quantity doubleValueForUnit:distanceUnit];
                    [data addObject:[NSNumber numberWithInt:value]];
                } else {
                    [data addObject:[NSNumber numberWithInt:0]];
                }
            }];
            int count = 0;
            NSArray *newArray = [data filteredArrayUsingPredicate: [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
                return ( [evaluatedObject isKindOfClass:[NSNumber class]] && ([evaluatedObject integerValue] > 0) );
                return NO;
            }]];
            if([self containsPositiveValue:data]){
                for (NSNumber* dist in data) {
                    [distanceData insertObject:dist atIndex:count];
                    count++;
                }
            }
            callback(distanceData);
            NSLog(@"fetchDistanceWalkingRunning is,%@",data);
        };
        
        [[VisitIosHealthController sharedManager] executeQuery:query];
}

-(void) fetchSleepPattern:(NSDate *) endDate frequency:(NSString*) frequency callback:(void(^)(NSArray*))callback{
    NSDate *startDate;
    NSDate *endDatePeriod;
    if([frequency isEqualToString:@"day"]){
        NSTimeInterval interval;
        [calendar rangeOfUnit:NSCalendarUnitDay
                           startDate:&startDate
                            interval:&interval
                             forDate:endDate];
        endDatePeriod = [startDate dateByAddingTimeInterval:interval-1];
    }else if ([frequency isEqualToString:@"week"]){
        NSTimeInterval interval;
        [calendar rangeOfUnit:NSCalendarUnitWeekOfYear
                           startDate:&startDate
                            interval:&interval
                             forDate:endDate];
        endDatePeriod = [startDate dateByAddingTimeInterval:interval-1];
    }
    NSLog(@"startDate and endDate in fetchSleepPattern is, %@ %@",startDate,endDatePeriod);
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDatePeriod options:HKQueryOptionStrictStartDate];
    [self fetchSleepCategorySamplesForPredicate:predicate
                                              limit:HKObjectQueryNoLimit
                                         completion:^(NSArray *results, NSError *error) {
                                             if(results){
                                                 callback(results);
                                                 return;
                                             } else {
                                                 NSLog(@"error getting sleep samples: %@", error);
                                                 return;
                                             }
                                         }];
}

- (void)fetchQuantitySamplesOfType:(HKQuantityType *)quantityType
                              unit:(HKUnit *)unit
                         predicate:(NSPredicate *)predicate
                         ascending:(BOOL)asc
                             limit:(NSUInteger)lim
                        completion:(void (^)(NSArray *, NSError *))completion {

    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate
                                                                       ascending:asc];
    __block NSTimeInterval totalActivityDuration = 0;
    // declare the block
    void (^handlerBlock)(HKSampleQuery *query, NSArray *results, NSError *error);
    // create and assign the block
    handlerBlock = ^(HKSampleQuery *query, NSArray *results, NSError *error) {
        if (!results) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }

        if (completion) {
            NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];

            dispatch_async(dispatch_get_main_queue(), ^{

                for (HKQuantitySample *sample in results) {
                    HKQuantity *quantity = sample.quantity;
                    double value = [quantity doubleValueForUnit:unit];
                    if(value){
                        NSTimeInterval duration = [sample.endDate timeIntervalSinceDate:sample.startDate];
                        totalActivityDuration+=duration;
                        NSLog(@"fetchQuantitySamplesOfType duration %f",duration);
                    }
                }
                [data addObject:[NSString stringWithFormat:@"%f",totalActivityDuration/60]];
                completion(data, error);
            });
        }
    };

    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:quantityType
                                                           predicate:predicate
                                                               limit:lim
                                                     sortDescriptors:@[timeSortDescriptor]
                                                      resultsHandler:handlerBlock];

    [[VisitIosHealthController sharedManager] executeQuery:query];
}


- (void) getActivityTime:(NSDate*) endDate frequency:(NSString*) frequency callback:(void(^)(NSString*))callback{
    HKQuantityType *stepCountType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    NSDate *startDate;
    NSDate *endDatePeriod;
    if([frequency isEqualToString:@"day"]){
        NSTimeInterval interval;
        [calendar rangeOfUnit:NSCalendarUnitDay
                           startDate:&startDate
                            interval:&interval
                             forDate:endDate];
        endDatePeriod = [startDate dateByAddingTimeInterval:interval-1];
    }else if ([frequency isEqualToString:@"week"]){
        NSTimeInterval interval;
        [calendar rangeOfUnit:NSCalendarUnitWeekOfYear
                           startDate:&startDate
                            interval:&interval
                             forDate:endDate];
        endDatePeriod = [startDate dateByAddingTimeInterval:interval-1];
    }else if ([frequency isEqualToString:@"month"]){
        NSTimeInterval interval;
        [calendar rangeOfUnit:NSCalendarUnitMonth
                           startDate:&startDate
                            interval:&interval
                             forDate:endDate];
        endDatePeriod = [startDate dateByAddingTimeInterval:interval-1];
    }
    NSLog(@"startDate and endDate in getActivityTime is, %@ %@",startDate,endDatePeriod);
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDatePeriod options:HKQueryOptionStrictStartDate];
    NSPredicate *userEnteredValuePredicate = [HKQuery predicateForObjectsWithMetadataKey:HKMetadataKeyWasUserEntered operatorType: NSNotEqualToPredicateOperatorType value: @YES];
    
    NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, userEnteredValuePredicate]];
    [self fetchQuantitySamplesOfType:stepCountType unit:[HKUnit countUnit] predicate:compoundPredicate ascending:true limit:HKObjectQueryNoLimit completion:^(NSArray *results, NSError *error) {
            if (results) {
                NSLog(@"the results of getActivityTime %@",results);
                callback([results objectAtIndex:0]);
                return;
            } else {
                NSLog(@"error getting step count samples: %@", error);
                return;
            }
        }];
}

- (void)fetchHourlySteps:(NSDate*) endDate callback:(void(^)(NSArray*))callback{
    HKQuantityType *stepCountType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    HKUnit *stepsUnit = [HKUnit countUnit];
    NSDateComponents *interval = [[NSDateComponents alloc] init];
    interval.hour = 1;
    NSDate *startDate = [[NSCalendar calendarWithIdentifier:NSCalendarIdentifierISO8601] startOfDayForDate:endDate];
    NSDate *anchorDate = [calendar startOfDayForDate:startDate];
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
    NSPredicate *userEnteredValuePredicate = [HKQuery predicateForObjectsWithMetadataKey:HKMetadataKeyWasUserEntered operatorType: NSNotEqualToPredicateOperatorType value: @YES];
    
    NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, userEnteredValuePredicate]];
    
    HKStatisticsCollectionQuery *query = [[HKStatisticsCollectionQuery alloc] initWithQuantityType:stepCountType quantitySamplePredicate:compoundPredicate options:HKStatisticsOptionCumulativeSum anchorDate:anchorDate intervalComponents:interval];
    
    query.initialResultsHandler = ^(HKStatisticsCollectionQuery * _Nonnull query, HKStatisticsCollection * _Nullable result, NSError * _Nullable error) {
        if (error) {
            NSLog(@"*** An error occurred while calculating the statistics: %@ ***",
                  error.localizedDescription);
            return;
        }
        
        NSMutableArray *data = [NSMutableArray arrayWithCapacity:24];
        NSMutableArray *stepsData = [NSMutableArray arrayWithCapacity:24];
        NSMutableArray *calorieData = [NSMutableArray arrayWithCapacity:24];
        [result enumerateStatisticsFromDate:startDate toDate:endDate withBlock:^(HKStatistics * _Nonnull result, BOOL * _Nonnull stop) {
            HKQuantity *quantity = result.sumQuantity;
            
            if (quantity) {
                int value = (int)[quantity doubleValueForUnit:stepsUnit];
                [data addObject:[NSNumber numberWithInt:value]];
                int calories = value/21;
                calories+=self->bmrCaloriesPerHour;
                [calorieData addObject:[NSNumber numberWithInt:calories]];
            } else {
                [data addObject:[NSNumber numberWithInt:0]];
                [calorieData addObject:[NSNumber numberWithInt:0]];
            }
        }];
        int count = 0;
        for (NSNumber* steps in data) {
            [stepsData insertObject:steps atIndex:count];
            count++;
        }
        NSArray* finalData = @[stepsData, calorieData];
        callback(finalData);
    };
   
    [[VisitIosHealthController sharedManager] executeQuery:query];
}

-(NSDate *) lastMondayBeforeDate:(NSDate*)timeStamp {
   NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierISO8601];
   NSDateComponents *comps = [gregorian components:NSCalendarUnitWeekday fromDate:timeStamp];
   NSInteger weekday = [comps weekday];
   weekday = weekday==1 ? 6 : weekday-2; // start with 0 on Monday rather than 1 on Sunday
   NSTimeInterval secondsSinceMondayMidnight =
     (NSUInteger) [timeStamp timeIntervalSince1970] % 60*60*24 +
      weekday * 60*60*24;
   return [timeStamp dateByAddingTimeInterval:-secondsSinceMondayMidnight];
}

-(void) fetchSteps:(NSString*) frequency endDate:(NSDate*) endDate callback:(void(^)(NSArray*))callback{
    NSDateComponents *interval = [[NSDateComponents alloc] init];
    NSDate *startDate;
    interval.day = 1;
    NSDate *endDatePeriod;
    if([frequency isEqualToString:@"day"]){
        endDatePeriod = endDate;
        startDate = [calendar dateByAddingUnit:NSCalendarUnitDay
                                                 value:0
                                                toDate:endDatePeriod
                                               options:0];
    }else if ([frequency isEqualToString:@"week"]){
        NSTimeInterval interval;
        [calendar rangeOfUnit:NSCalendarUnitWeekOfYear
                           startDate:&startDate
                            interval:&interval
                             forDate:endDate];
        endDatePeriod = [startDate dateByAddingTimeInterval:interval-1];
    }else if ([frequency isEqualToString:@"month"]){
        NSTimeInterval interval;
        [calendar rangeOfUnit:NSCalendarUnitMonth
                           startDate:&startDate
                            interval:&interval
                             forDate:endDate];
        endDatePeriod = [startDate dateByAddingTimeInterval:interval-1];
    }
    NSLog(@"startDate and endDate in fetchSteps is, %@, %@",startDate,endDatePeriod);
    NSDateComponents *anchorComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                                     fromDate:[NSDate date]];
    anchorComponents.hour = 0;
    NSDate *anchorDate = [calendar dateFromComponents:anchorComponents];
    HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    // Create the query
    HKStatisticsCollectionQuery *query = [[HKStatisticsCollectionQuery alloc] initWithQuantityType:quantityType
                                                                           quantitySamplePredicate:nil
                                                                                           options:HKStatisticsOptionCumulativeSum
                                                                                        anchorDate:anchorDate
                                                                                intervalComponents:interval];

    // Set the results handler
    query.initialResultsHandler = ^(HKStatisticsCollectionQuery *query, HKStatisticsCollection *results, NSError *error) {
        if (error) {
            // Perform proper error handling here
            NSLog(@"*** An error occurred while calculating the statistics: %@ ***",error.localizedDescription);
        }
        NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];
        NSMutableArray *calorieData = [NSMutableArray arrayWithCapacity:1];
        [results enumerateStatisticsFromDate:startDate
                                      toDate:endDatePeriod
                                   withBlock:^(HKStatistics *result, BOOL *stop) {

                                       HKQuantity *quantity = result.sumQuantity;
                                       if (quantity) {
                                           int value = [[NSNumber numberWithInt:[quantity doubleValueForUnit:[HKUnit countUnit]]] intValue];
                                           int calories = value/21;
                                           calories+=self->bmrCaloriesPerHour;
                                           [calorieData addObject:[NSNumber numberWithInt:calories]];
                                           [data addObject:[NSNumber numberWithInt:value]];
                                       }
                                   }];
        NSLog(@"in stepsData and calorieData is %@,%@", data, calorieData);
        NSArray* finalData = @[data, calorieData];
        callback(finalData);
    };

    [[VisitIosHealthController sharedManager] executeQuery:query];
}

-(void) canAccessHealthKit: (void(^)(BOOL))callback {
    double value = 1;
    NSDate *startDate = [NSDate date];
    NSDate *endDate = [NSDate date];
    
    HKUnit *unit = [HKUnit countUnit];
    HKQuantity *quantity = [HKQuantity quantityWithUnit:unit doubleValue:value];
    HKQuantityType *type = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    HKQuantitySample *sample = [HKQuantitySample quantitySampleWithType:type quantity:quantity startDate:startDate endDate:endDate];
    
    [[VisitIosHealthController sharedManager] saveObject:sample withCompletion:^(BOOL success, NSError *error) {
            if (!success) {
                NSLog(@"An error occured saving the step count sample %@. The error was: %@.", sample, error);
                callback(NO);
            }else{
                [[VisitIosHealthController sharedManager] deleteObject:sample withCompletion:^(BOOL success, NSError * _Nullable error) {
                    if(!success){
                        callback(NO);
                    }else{
                        callback(YES);
                    }
                }];
            }
        }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == webView) {
        NSLog(@"%f", webView.estimatedProgress);
        // estimatedProgress is a value from 0.0 to 1.0
        // Update your UI here accordingly
        if(webView.estimatedProgress>0.7){
            [activityIndicator stopAnimating];
            [storyboardVC dismissViewControllerAnimated:NO completion:^{
                NSLog(@"Storyboard dismissed");
            }];
        }
    }
}

- (void)loadVisitWebUrl:(NSString *) baseUrl magicLink:(NSString*) magicLink caller:(UIViewController*) caller{
    NSLog(@"VisitIosHealthController init called");
//    // Do any additional setup after loading the view.
//      NSBundle* bun = [NSBundle bundleWithIdentifier:@"com.getvisitapp.visitIosHealthKit"];
    NSBundle* podBundle = [NSBundle bundleForClass:[self class]];
    NSURL* bundleUrl = [podBundle URLForResource:@"VisitIosHealthSdk" withExtension:@"bundle"];
    NSBundle* bundle = [NSBundle bundleWithURL:bundleUrl];
    UIStoryboard* storyboard;
    storyboard = [UIStoryboard storyboardWithName:@"Loader" bundle:bundle];
    
    storyboardVC = [storyboard instantiateInitialViewController];
    storyboardVC.modalPresentationStyle = 0;
    if (@available(iOS 13.0, *)) {
        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    } else {
        // Fallback on earlier versions
    }
    activityIndicator.center = storyboardVC.view.center;
    if (@available(iOS 13.0, *)) {
        activityIndicator.color = UIColor.linkColor;
    } else {
        // Fallback on earlier versions
    }
    [storyboardVC.view addSubview:activityIndicator];
    [activityIndicator startAnimating];
    [self presentViewController:storyboardVC animated:false completion:nil];
    NSString *magicUrl = [NSString stringWithFormat:@"%@/%@",baseUrl, magicLink];
    NSLog(@"loadVisitWebUrl is called ===>>> %@", magicUrl);
    NSURL *url = [NSURL URLWithString:magicUrl];
    NSURLRequest* request = [NSURLRequest requestWithURL: url];
    [webView loadRequest:request];
    NSLog(@"Your request of loadVisitUrl is ===>>> %@", request);
}

- (NSString *)readGender
{
    NSError *error;
    HKBiologicalSexObject *gen=[[VisitIosHealthController sharedManager] biologicalSexWithError:&error];
    if (gen.biologicalSex==HKBiologicalSexMale)
    {
        return(@"Male");
    }
    else if (gen.biologicalSex==HKBiologicalSexFemale)
    {
        return (@"Female");
    }
    else if (gen.biologicalSex==HKBiologicalSexOther)
    {
        return (@"Other");
    }
    else{
        return (@"Not Set");
    }
}

- (NSData *) arrayToJSON:(NSArray *) inputArray
{
    NSError *error = nil;
    id result = [NSJSONSerialization dataWithJSONObject:inputArray
                                                options:kNilOptions error:&error];
    if (error != nil) return nil;
    return result;
}

-(void) injectSleepData:(NSString *) javascript{
    NSLog(@"javascript to be injected %@",javascript);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->webView evaluateJavaScript:javascript completionHandler:^(NSString *result, NSError *error) {
            if(error != nil) {
                NSLog(@"SomeFunction Error: %@",error);
                return;
            }
            NSLog(@"SomeFunction Success %@",result);
        }];
    });
}

-(void) injectJavascript:(NSArray *) data type:(NSString *) type frequency:(NSString *) frequency activityTime:(NSString *) activityTime{
    NSString* hoursInDay = @"[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24]";
    NSString* daysInWeek = @"[1,2,3,4,5,6,7]";
    NSString* daysInMonth = @"[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31]";
    NSString* samples;
    NSString *jsonArrayData;
    if([frequency isEqualToString:@"day"]){
        samples=hoursInDay;
    }else if ([frequency isEqualToString:@"week"]){
        samples=daysInWeek;
    }else if ([frequency isEqualToString:@"month"]){
        samples=daysInMonth;
    }
    if([type isEqualToString:@"steps"] || [type isEqualToString:@"calories"]){
        if([type isEqualToString:@"steps"]){
            jsonArrayData = [[data objectAtIndex:0] componentsJoinedByString:@","];
        }else{
            jsonArrayData = [[data objectAtIndex:1] componentsJoinedByString:@","];
        }
    }else{
         jsonArrayData = [data componentsJoinedByString:@","];
    }
    NSString *javascript = [NSString stringWithFormat:@"DetailedGraph.updateData(%@,[%@],'%@','%@','%@')", samples, jsonArrayData, type,frequency, activityTime];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->webView evaluateJavaScript:javascript completionHandler:^(NSString *result, NSError *error) {
            if(error != nil) {
                NSLog(@"injectJavascript Error: %@",error);
                return;
            }
            NSLog(@"injectJavascript Success: %@",javascript);
        }];
    });
}

-(NSMutableArray*) getBlankSleepWeeks:(NSUInteger) currentCount date:(NSDate*) date{
    NSMutableArray *result = [[NSMutableArray alloc]init];
    NSInteger value = 1;
    NSDate *nextDayTime=date;
    NSNumber *nextDayTimeStamp;
    NSDateComponents *dateComponents;
    NSString* day;
    NSLog(@"day is, %@",day);
    int counter =(int) currentCount;
    while(counter<7){
        nextDayTime = [calendar dateByAddingUnit:NSCalendarUnitDay value:value toDate:nextDayTime options:NSCalendarMatchStrictly];
        nextDayTimeStamp = [NSNumber numberWithDouble: [@(floor([nextDayTime timeIntervalSince1970] * 1000)) longLongValue]];
        dateComponents = [calendar components: NSCalendarUnitWeekday fromDate: nextDayTime];
        day =calendar.shortWeekdaySymbols[dateComponents.weekday-1];
        NSDictionary *element = @{
                @"sleepTime" : @0,
                @"wakeupTime" : @0,
                @"day" : day,
                @"startTimestamp" : nextDayTimeStamp,
        };
        NSLog(@"element is %@",element);
        [result addObject:[NSMutableDictionary dictionaryWithDictionary:element]];
        counter++;
    }
    return result;
}

-(void) renderGraphData:(NSString *) type frequency:(NSString *) frequency date:(NSDate *) date{
    if([type isEqualToString:@"steps"] || [type isEqualToString:@"distance"]||[type isEqualToString:@"calories"]){
        dispatch_group_t loadDetailsGroup=dispatch_group_create();
        __block NSArray* stepsOrDistance = 0;
        __block NSString* totalActivityDuration = 0;
        for (int i = 0; i<2; i++) {
            dispatch_group_enter(loadDetailsGroup);
            if(i==0){
                [self getActivityTime:date frequency:frequency callback:^(NSString * result){
                    totalActivityDuration = result;
                    dispatch_group_leave(loadDetailsGroup);
                }];
            }else if(i==1){
                if([type isEqualToString:@"steps"] || [type isEqualToString:@"calories"]){
                    if([frequency isEqualToString:@"day"]){
                        [self fetchHourlySteps:date callback:^(NSArray * result) {
                            stepsOrDistance = result;
                            dispatch_group_leave(loadDetailsGroup);
                        }];
                    }else{
                        [self fetchSteps:frequency endDate: date callback:^(NSArray * result) {
                            stepsOrDistance = result;
                            dispatch_group_leave(loadDetailsGroup);
                        }];
                    }
                }else if ([type isEqualToString:@"distance"]){
                    if([frequency isEqualToString:@"day"]){
                        [self fetchHourlyDistanceWalkingRunning:date callback:^(NSArray * result) {
                            stepsOrDistance = result;
                            dispatch_group_leave(loadDetailsGroup);
                        }];
                    }else{
                        [self fetchDistanceWalkingRunning:frequency endDate: date callback:^(NSArray * result) {
                            stepsOrDistance = result;
                            dispatch_group_leave(loadDetailsGroup);
                        }];
                    }
                }
            }
        }
        dispatch_group_notify(loadDetailsGroup,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
            [self injectJavascript:stepsOrDistance type:type frequency:frequency activityTime:totalActivityDuration];
        });
    }else if([type isEqualToString:@"sleep"]){
            if([frequency isEqualToString:@"day"]){
                [self fetchSleepPattern:date frequency:frequency callback:^(NSArray * results) {
                NSNumber* sleepTime = 0;
                NSNumber* wakeTime = 0;
                int count = 0;
                for (NSDictionary *object in results) {
                    NSString* sleepValue = [object valueForKey:@"value"];
                    if([sleepValue isEqualToString:@"INBED"]||[sleepValue isEqualToString:@"ASLEEP"]){
                        if(count==0){
                            sleepTime =
                            [NSNumber numberWithDouble: [@(floor([[object valueForKey:@"startDate"] timeIntervalSince1970] * 1000)) longLongValue]];
                            
                        }
                        wakeTime =
                        [NSNumber numberWithDouble: [@(floor([[object valueForKey:@"endDate"] timeIntervalSince1970] * 1000)) longLongValue]];
                        count++;
                    }
                }
                NSLog(@"sleepTime and wakeTime data, %@ %@",sleepTime, wakeTime);
                    
                if(sleepTime && wakeTime){
                    NSString *javascript = [NSString stringWithFormat:@"DetailedGraph.updateDailySleep(%@,%@)", sleepTime,wakeTime];
                    [self injectSleepData:javascript];
                }else{
                    NSString *javascript = [NSString stringWithFormat:@"DetailedGraph.updateDailySleep(0,0)"];
                    [self injectSleepData:javascript];
                }
            } ];
            }else{
                [self fetchSleepPattern:date frequency:frequency callback:^(NSArray * results) {
                    NSMutableArray *data = [[NSMutableArray alloc]init];
                    NSLog(@"weekly sleep results, %@", results);
                    for (NSDictionary* item in results) {
                        NSString* sleepValue = [item valueForKey:@"value"];
                        if([sleepValue isEqualToString:@"INBED"]||[sleepValue isEqualToString:@"ASLEEP"]){
                            NSDate* startDate = [item valueForKey:@"startDate"];
                            NSDate* endDate = [item valueForKey:@"endDate"];
                            NSTimeInterval interval;
                            NSNumber* sleepTime =
                            [NSNumber numberWithDouble: [@(floor([startDate timeIntervalSince1970] * 1000)) longLongValue]];
                            NSNumber* wakeupTime =
                            [NSNumber numberWithDouble: [@(floor([endDate timeIntervalSince1970] * 1000)) longLongValue]];
                            NSLog(@"startDate before calendar function ,%@",startDate);
                            [self->calendar rangeOfUnit:NSCalendarUnitDay
                                               startDate:&startDate
                                                interval:&interval
                                                 forDate:endDate];
                            NSLog(@"startDate after calendar function ,%@",startDate);
                            NSNumber* startTimestamp =
                            [NSNumber numberWithDouble: [@(floor([startDate timeIntervalSince1970] * 1000)) longLongValue]];
                            NSDateComponents * dateComponents = [self->calendar components: NSCalendarUnitDay | NSCalendarUnitWeekday fromDate: endDate];
                            NSString* day =self->calendar.shortWeekdaySymbols[dateComponents.weekday - 1];
                            NSLog(@"Day name: %@", day);
                            NSDictionary *element = @{
                                    @"sleepTime" : sleepTime,
                                    @"wakeupTime" : wakeupTime,
                                    @"day" : day,
                                    @"startTimestamp" : startTimestamp,
                            };
                            NSMutableDictionary *elem = [NSMutableDictionary dictionaryWithDictionary:element];

                            NSLog(@"data is, ====>> %@",data);
                            if([data count]>0){
                                for (int i=0;i<[data count]; i++) {
                                    NSMutableDictionary* item = [data objectAtIndex:i];
                                    NSString* itemDay = [item objectForKey:@"day"];
                                    NSString* itemSleepTime = [item objectForKey:@"sleepTime"];
                                    if([itemDay isEqualToString:day]){
                                        [elem setValue:itemSleepTime forKey:@"sleepTime"];
                                        [data removeObjectAtIndex:i];
                                        NSLog(@"removed day is, ====>> %@",itemDay);
                                    }
                                }
                                [data addObject:elem];
                            }else{
                                [data addObject:elem];
                            }
                        }
                    }
                    if([data count]<7){
                        NSMutableDictionary* item = [data objectAtIndex:[data count]-1];
                        NSNumber* startTimeStamp = [item objectForKey:@"startTimestamp"];
                        NSTimeInterval unixTimeStamp = [startTimeStamp doubleValue] / 1000.0;
                        NSMutableArray* newData = [self getBlankSleepWeeks:[data count] date:[NSDate dateWithTimeIntervalSince1970:unixTimeStamp]];
                        [data addObjectsFromArray:newData];
                    }
                    NSLog(@"data is, %@",data);
                    NSData* jsonArray = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:nil ];
                    NSString *jsonString = [[NSString alloc] initWithData:jsonArray encoding:NSUTF8StringEncoding];
                    NSString *javascript = [NSString stringWithFormat:@"DetailedGraph.updateSleepData(JSON.stringify(%@))",  jsonString];
                    [self injectSleepData:javascript];
                }];
           }
        
    }
}

- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    NSData *data = [message.body dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSString *methodName = [json valueForKey:@"method"];
    NSLog(@"new data is, %@",json);
    if([methodName isEqualToString:@"connectToGoogleFit"]) {
        [self canAccessHealthKit:^(BOOL value){
            if(value){
                [self onHealthKitPermissionGranted];
            }else{
                [self requestAuthorization];
            }
        }];
    }else if([methodName isEqualToString:@"getDataToGenerateGraph"]){
        NSString *type = [json valueForKey:@"type"];
        NSString *frequency = [json valueForKey:@"frequency"];
        NSString *timestamp = [json valueForKey:@"timestamp"];
        NSDate *date = [self convertStringToDate:timestamp];
        [self renderGraphData:type frequency:frequency date:date];
    }
}



@end
