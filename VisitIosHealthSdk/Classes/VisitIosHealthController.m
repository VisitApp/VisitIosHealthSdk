//
//  VisitIosHealthController.m
//  ios-health
//
//  Created by Yash on 18/01/22.
//

#import "VisitIosHealthController.h"
#import "VisitVideoCallDelegate.h"

API_AVAILABLE(ios(11.0))
@implementation VisitIosHealthController

- (instancetype)initWithFrame:(CGRect)frame{
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.preferences.javaScriptEnabled = YES;
    config.allowsInlineMediaPlayback = YES;
    [config.userContentController
              addScriptMessageHandler:self name:@"visitIosView"];
    self = [super initWithFrame:CGRectZero configuration:config];
    [self.scrollView setScrollEnabled:NO];
    [self.scrollView setMultipleTouchEnabled:NO];
    gender = @"Not Set";
    syncingEnabled = YES;
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder{
    return [super initWithCoder:coder];
}

+ (HKHealthStore *)sharedManager {
    __strong static HKHealthStore *store = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[HKHealthStore alloc] init];
    });

    return store;
}

-(void)initialParams:(NSDictionary *)params {
        NSLog(@"initWithParams params %@",params);
        NSString* tataAIG_base_url = [params valueForKey:@"tataAIG_base_url"];
        NSString* tataAIG_auth_token = [params valueForKey:@"tataAIG_auth_token"];
        self->tataAIG_base_url = tataAIG_base_url;
        self->tataAIG_auth_token = tataAIG_auth_token;
    
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSString *memberId = [prefs stringForKey:@"memberId"];
        self->memberId = memberId;
        NSString *uatLastSyncTime = [params valueForKey:@"uatLastSyncTime"] ? [params valueForKey:@"uatLastSyncTime"]: [prefs stringForKey:@"uatLastSyncTime"];
        NSLog(@"initWithParams memberId and uatLastSyncTime obtained, %@ and %@", memberId, uatLastSyncTime);
        [VisitIosHealthController canAccessHealthKit:^(BOOL value){
            if(value && memberId!= NULL && uatLastSyncTime!= NULL){
                NSTimeInterval gfHourlyLastSync = [uatLastSyncTime doubleValue];
                NSDate* hourlyDataSyncTime = [NSDate dateWithTimeIntervalSince1970: gfHourlyLastSync/1000];
                [self getDateRanges:hourlyDataSyncTime callback:^(NSMutableArray * dates) {
                   if([dates count]>0){
                       [self callUatApi:dates];
                   }
                }];
            }
        }];
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
//        NSLog(@"requestAuthorizationToShareTypes executed");
        [VisitIosHealthController canAccessHealthKit:^(BOOL value){
            if(value){
                [self postNotification:@"FitnessPermissionGranted"];
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
                        if (@available(iOS 10.0, *)) {
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                        } else {
                            // Fallback on earlier versions
                        }
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
                    
//                    [self presentViewController:alert animated:false completion:nil];
                });
            }
        }];
    }];
}

-(void) onHealthKitPermissionGranted{
    self->gender= [self readGender];
    if([self->gender isEqualToString:@"Male"]){
        self->bmrCaloriesPerHour = 1662 / 24;
    }else{
        self->bmrCaloriesPerHour = 1493 / 24;
    }
    NSString *javascript = [NSString stringWithFormat:@"googleFitnessConnectedSuccessfully(true)"];
    [self injectJavascript:javascript];
}

-(void) insertDataToCard{
    dispatch_group_t loadDetailsGroup=dispatch_group_create();
    __block NSString* numberOfSteps = 0;
    __block NSTimeInterval totalSleepTime = 0;
    NSLog(@"gender is, %@",gender);
    for (int i = 0; i<2; i++) {
        dispatch_group_enter(loadDetailsGroup);
        if(i==0){
            //  getting steps for current day
            [self fetchSteps:@"day" endDate:[NSDate date] days:0 callback:^(NSArray * result) {
                if([[result objectAtIndex:0] count]>0){
                    numberOfSteps = [[result objectAtIndex:0] objectAtIndex:0];
                }
                dispatch_group_leave(loadDetailsGroup);
            }];
        }else if (i==1){
            //  getting sleep pattern for the day past
            [self fetchSleepPattern:[NSDate date] frequency:@"day" days:0 callback:^(NSArray * result) {
              NSLog(@"Sleep result is, %@",result);
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
    
    dispatch_group_notify(loadDetailsGroup,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        NSLog(@"the steps result is, %@",numberOfSteps);
        NSLog(@"total sleep time is %f",totalSleepTime);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *javascript = [NSString stringWithFormat:@"updateFitnessPermissions(true,'%@','%f')",numberOfSteps, totalSleepTime];
                [self injectJavascript:javascript];
            });
    });
    
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


-(void) fetchDistanceWalkingRunning:(NSString*) frequency endDate:(NSDate*) endDate days:(NSInteger) days callback:(void(^)(NSArray*))callback{
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
    }else if([frequency isEqualToString:@"custom"]){
        endDatePeriod = endDate;
        startDate = [calendar dateByAddingUnit:NSCalendarUnitDay
                                                 value:1-days
                                                toDate:endDatePeriod
                                               options:0];
//        NSLog(@"startDate and endDate in custom fetchDistanceWalkingRunning is, %@, %@",startDate,endDatePeriod);
    }
//    NSLog(@"startDate and endDate in fetchDistanceWalkingRunning is, %@, %@",startDate,endDatePeriod);
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
//                                           NSLog(@"in fetchDistanceWalkingRunning %d", value);
                                           
                                           [data addObject:[NSNumber numberWithInt:value]];
                                       }else{
                                           [data addObject:[NSNumber numberWithInt:0]];
                                       }
                                   }];
        callback(data);
    };

    [[VisitIosHealthController sharedManager] executeQuery:query];
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
                NSLog(@"*** An error occurred while calculating the statistics: %@ ***", error.localizedDescription);
                return;
            }
            
            NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];
            [result enumerateStatisticsFromDate:startDate toDate:endDate withBlock:^(HKStatistics * _Nonnull result, BOOL * _Nonnull stop) {
                HKQuantity *quantity = result.sumQuantity;
                if (quantity) {
                    int value =(int) [quantity doubleValueForUnit:distanceUnit];
                    [data addObject:[NSNumber numberWithInt:value]];
                } else {
                    [data addObject:[NSNumber numberWithInt:0]];
                }
            }];
            callback(data);
//            NSLog(@"fetchDistanceWalkingRunning is,%@",data);
        };
        
        [[VisitIosHealthController sharedManager] executeQuery:query];
}

-(void) fetchSleepPattern:(NSDate *) endDate frequency:(NSString*) frequency days:(NSInteger) days callback:(void(^)(NSArray*))callback{
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
    }else if([frequency isEqualToString:@"custom"]){
        endDatePeriod = endDate;
        startDate = [calendar dateByAddingUnit:NSCalendarUnitDay
                                                 value:-days
                                                toDate:endDatePeriod
                                               options:0];
//        NSLog(@"startDate and endDate in custom fetchSleepPattern is, %@, %@",startDate,endDatePeriod);
    }
//    NSLog(@"startDate and endDate in fetchSleepPattern is, %@ %@",startDate,endDatePeriod);
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDatePeriod options:HKQueryOptionStrictStartDate];
    [self fetchSleepCategorySamplesForPredicate:predicate
                                              limit:HKObjectQueryNoLimit
                                         completion:^(NSArray *results, NSError *error) {
                                             if(results){
//                                                 NSLog(@"fetchSleepCategorySamplesForPredicate result, %@",results);
                                                 callback(results);
                                                 return;
                                             } else {
//                                                 NSLog(@"error getting sleep samples: %@", error);
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
            NSMutableArray *dataByFrequency = [NSMutableArray new];
            dispatch_async(dispatch_get_main_queue(), ^{
                for (HKQuantitySample *sample in results) {
                    HKQuantity *quantity = sample.quantity;
                    double value = [quantity doubleValueForUnit:unit];
                    if(value){
//                        NSLog(@"startDate and endDate for fetchQuantitySamplesOfType is %@ & %@", sample.startDate,sample.endDate);
                        NSNumber* val = [NSNumber numberWithDouble:[sample.endDate timeIntervalSinceDate:sample.startDate]/60];
                        NSDictionary *element = @{
                            @"date" : sample.endDate,
                            @"value" : val,
                        };
                        NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithDictionary:element];
                        
                        if([dataByFrequency count]>0){
                            NSMutableDictionary* ele = [dataByFrequency objectAtIndex:[dataByFrequency count]-1];
                            if([[NSCalendar currentCalendar] isDate:sample.endDate inSameDayAsDate:[ele valueForKey:@"date"]]){
                                double myValue = [[ele valueForKey:@"value"] doubleValue];
                                myValue+=[val doubleValue];
                                [ele setObject:sample.endDate forKey:@"date" ];
                                [ele setObject: [NSNumber numberWithDouble:myValue] forKey:@"value" ];
                            }else{
                                [dataByFrequency addObject:dict];
                            }
                        }
                        else{
                            [dataByFrequency addObject:dict];
                        }
                        
                        NSTimeInterval duration = [sample.endDate timeIntervalSinceDate:sample.startDate];
                        totalActivityDuration+=duration;
//                        NSLog(@"fetchQuantitySamplesOfType dict is %@",dict);
                    }
                }
//                NSLog(@"fetchQuantitySamplesOfType dataByFrequency %@ ",dataByFrequency);
                [data addObject:[NSString stringWithFormat:@"%f",totalActivityDuration/60]];
                [data addObject:dataByFrequency];
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


- (void) getActivityTime:(NSDate*) endDate frequency:(NSString*) frequency days:(NSInteger) days callback:(void(^)(NSMutableArray*))callback{
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
    }else if([frequency isEqualToString:@"custom"]){
        endDatePeriod = endDate;
        startDate = [calendar dateByAddingUnit:NSCalendarUnitDay
                                                 value:1-days
                                                toDate:endDatePeriod
                                               options:0];
    }
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDatePeriod options:HKQueryOptionStrictStartDate];
    NSPredicate *userEnteredValuePredicate = [HKQuery predicateForObjectsWithMetadataKey:HKMetadataKeyWasUserEntered operatorType: NSNotEqualToPredicateOperatorType value: @YES];
    
    NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, userEnteredValuePredicate]];
    [self fetchQuantitySamplesOfType:stepCountType unit:[HKUnit countUnit] predicate:compoundPredicate ascending:true limit:HKObjectQueryNoLimit completion:^(NSArray *results, NSError *error) {
            if (results) {
//                NSLog(@"the results of getActivityTime %@",results);
                callback([NSMutableArray arrayWithArray:results]);
                return;
            } else {
//                NSLog(@"error getting step count samples: %@", error);
                return;
            }
        }];
}

-(void)PostJson:(NSString*) endPoint body:(NSDictionary*) body authToken:(NSString*) authToken{
    NSString *downloadUrl = endPoint;
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString: downloadUrl]];
    if([NSJSONSerialization isValidJSONObject:body])
        {
            // Convert the JSON object to NSData
            NSData * httpBodyData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
//            NSLog(@"hitting api %@ with body=%@",downloadUrl, httpBodyData);
            // set the http body
            [request setHTTPBody:httpBodyData];
            [request setHTTPMethod:@"POST"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [request setValue:authToken forHTTPHeaderField:@"Authorization"];
            NSURLSessionDataTask * task= [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (error) {
                    NSLog(@"Download Error:%@ for endpoint=%@",error.description,downloadUrl);
                }
                if (data) {

                    //
                    // THIS CODE IS FOR PRINTING THE RESPONSE
                    //
                    NSString *returnString = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
                    NSLog(@"Response:%@ for endpoint=%@",returnString,downloadUrl);
                    if ([returnString rangeOfString:@"SUCCESS"].location == NSNotFound &&
                        [endPoint rangeOfString:@"uat"].location == NSNotFound) {
                      NSLog(@"not the uat api");
                    } else {
                        NSNumber *timeInSeconds = [NSNumber numberWithDouble: [@(floor([[NSDate date] timeIntervalSince1970] * 1000)) longLongValue]];
                        NSString* currentTimeStamp = [timeInSeconds stringValue];
                        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                        [prefs setObject:currentTimeStamp forKey:@"uatLastSyncTime"];
                        NSLog(@"uat api called successfully,%@",currentTimeStamp);
                    }

                    //PARSE JSON RESPONSE
                    NSDictionary *json_response = [NSJSONSerialization JSONObjectWithData:data
                                                                                  options:0
                                                                                    error:NULL];

                    if ( json_response ) {
                        if ( [json_response isKindOfClass:[NSDictionary class]] ) {
                            // do dictionary things
                            for ( NSString *key in [json_response allKeys] ) {
                                NSLog(@"json_response %@: %@", key, json_response[key]);
                            }
                        }
                        else if ( [json_response isKindOfClass:[NSArray class]] ) {
                            NSLog(@"%@",json_response);
                        }
                    }
                    else {
                        NSLog(@"Error serializing JSON: %@", error);
                        NSLog(@"RAW RESPONSE: %@",data);
                        NSString *returnString2 = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
                        NSLog(@"Response:%@  for endpoint=%@ where data is=%@",returnString2, downloadUrl,[body description]);
                    }
                }
            }];
            [task resume];
        }
}

-(void)PutJson:(NSString*) endPoint body:(NSDictionary*) body authToken:(NSString*) authToken{
    NSString *downloadUrl = endPoint;
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString: downloadUrl]];
    if([NSJSONSerialization isValidJSONObject:body])
        {
            // Convert the JSON object to NSData
            NSData * httpBodyData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
//            NSLog(@"hitting api %@ with body=%@",downloadUrl, httpBodyData);
            // set the http body
            [request setHTTPBody:httpBodyData];
            [request setHTTPMethod:@"PUT"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [request setValue:authToken forHTTPHeaderField:@"Authorization"];
            NSURLSessionDataTask * task= [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (error) {
                    NSLog(@"Download Error:%@ for endpoint=%@",error.description,downloadUrl);
                }
                if (data) {

                    //
                    // THIS CODE IS FOR PRINTING THE RESPONSE
                    //
                    NSString *returnString = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
                    NSLog(@"Response:%@ for endpoint=%@",returnString,downloadUrl);
                    if ([returnString rangeOfString:@"SUCCESS"].location == NSNotFound &&
                        [endPoint rangeOfString:@"uat"].location == NSNotFound) {
                      NSLog(@"not the uat api");
                    } else {
                        NSNumber *timeInSeconds = [NSNumber numberWithDouble: [@(floor([[NSDate date] timeIntervalSince1970] * 1000)) longLongValue]];
                        NSString* currentTimeStamp = [timeInSeconds stringValue];
                        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                        [prefs setObject:currentTimeStamp forKey:@"uatLastSyncTime"];
                        NSLog(@"uat api called successfully,%@",currentTimeStamp);
                    }

                    //PARSE JSON RESPONSE
                    NSDictionary *json_response = [NSJSONSerialization JSONObjectWithData:data
                                                                                  options:0
                                                                                    error:NULL];

                    if ( json_response ) {
                        if ( [json_response isKindOfClass:[NSDictionary class]] ) {
                            // do dictionary things
                            for ( NSString *key in [json_response allKeys] ) {
                                NSLog(@"json_response %@: %@", key, json_response[key]);
                            }
                        }
                        else if ( [json_response isKindOfClass:[NSArray class]] ) {
                            NSLog(@"%@",json_response);
                        }
                    }
                    else {
                        NSLog(@"Error serializing JSON: %@", error);
                        NSLog(@"RAW RESPONSE: %@",data);
                        NSString *returnString2 = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
                        NSLog(@"Response:%@  for endpoint=%@ where data is=%@",returnString2, downloadUrl,[body description]);
                    }
                }
            }];
            [task resume];
        }
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
            NSLog(@"*** An error occurred while calculating the statistics: %@ ***", error.localizedDescription);
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

-(void) getDateRanges:(NSDate*) startDate callback:(void(^)(NSMutableArray*))callback{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    dispatch_group_t loadDetailsGroup = dispatch_group_create();
    NSDate *startOfToday = [[NSCalendar calendarWithIdentifier:NSCalendarIdentifierISO8601] startOfDayForDate:[NSDate date]];
    NSDate *startOfNextDay = [[NSCalendar calendarWithIdentifier:NSCalendarIdentifierISO8601] dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startOfToday options:0];
    NSDate *endOfToday = [[NSCalendar calendarWithIdentifier:NSCalendarIdentifierISO8601] dateByAddingUnit:NSCalendarUnitSecond value:-1 toDate:startOfNextDay options:0];
//    NSLog(@"startOfNextDay is %@, while endOfToday is,%@",startOfNextDay,endOfToday);
    NSDateComponents *days = [[NSDateComponents alloc] init];
    NSInteger dayCount = 0;
    NSMutableArray *dates=[NSMutableArray new];
    NSDate* startingDate = startDate;
    NSDateComponents *component = [calendar components:NSCalendarUnitDay
                                                        fromDate:startingDate
                                                          toDate:endOfToday
                                                         options:0];
    
    NSInteger numberOfDays =[component day];
    if(numberOfDays>30){
        [component setDay:-30];
        startingDate =[calendar dateByAddingComponents:component toDate:endOfToday options:0];
        numberOfDays=30;
    }else{
        [component setDay:-numberOfDays-1];
        startingDate =[calendar dateByAddingComponents:component toDate:endOfToday options:0];
    }
//    NSLog(@"numberOfDays are ,%ld, while startingDate is,%@",(long)numberOfDays,startDate);

    for (NSInteger i=numberOfDays; i>0; i--) {
        dispatch_group_enter(loadDetailsGroup);
        [days setDay: ++dayCount];
        NSDate *date = [calendar dateByAddingComponents: days toDate: startingDate options: 0];
        [dates addObject:date];
        dispatch_group_leave(loadDetailsGroup);
    }

    dispatch_group_notify(loadDetailsGroup,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
//        NSLog(@"dispatch_group_notify called %@",dates);
            callback(dates);
    });
}

-(void) fetchSteps:(NSString*) frequency endDate:(NSDate*) endDate days:(NSInteger) days callback:(void(^)(NSArray*))callback{
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
    }else if([frequency isEqualToString:@"custom"]){
        endDatePeriod = endDate;
        startDate = [calendar dateByAddingUnit:NSCalendarUnitDay
                                                 value:1-days
                                                toDate:endDatePeriod
                                               options:0];
//        NSLog(@"startDate and endDate in custom fetchSteps is, %@, %@",startDate,endDatePeriod);
    }
//    NSLog(@"startDate and endDate in fetchSteps is, %@, %@",startDate,endDatePeriod);
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
                                       }else{
                                           [data addObject:[NSNumber numberWithInt:0]];
                                           [calorieData addObject:[NSNumber numberWithInt:0]];
                                       }
                                   }];
//        NSLog(@"in stepsData and calorieData is %@,%@", data, calorieData);
        NSArray* finalData = @[data, calorieData];
        callback(finalData);
    };

    [[VisitIosHealthController sharedManager] executeQuery:query];
}

+(void) canAccessHealthKit: (void(^)(BOOL))callback {
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

- (void)closeAddDependentView:(UIButton*)button
   {
       [addDependentViewController dismissViewControllerAnimated:NO completion:^{
           NSLog(@"dependent view dismissed");
       }];
  }

- (UIViewController *)currentTopViewController {
    UIViewController *topVC = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}

- (void)loadVisitWebUrl:(NSString*) magicLink{
    currentTopVC = [self currentTopViewController];
    calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierISO8601];
    calendar.timeZone = [NSTimeZone timeZoneWithName:@"IST"];


    NSLog(@"loadVisitWebUrl is called ===>>> %@", magicLink);
    NSURL *url = [NSURL URLWithString:magicLink];
    NSURLRequest* request = [NSURLRequest requestWithURL: url];
    [super loadRequest:request];
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
        [self evaluateJavaScript:javascript completionHandler:^(NSString *result, NSError *error) {
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
        [self evaluateJavaScript:javascript completionHandler:^(NSString *result, NSError *error) {
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
                [self getActivityTime:date frequency:frequency days:0 callback:^(NSMutableArray * result){
                    totalActivityDuration = [result objectAtIndex:0];
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
                        [self fetchSteps:frequency endDate: date days:0 callback:^(NSArray * result) {
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
                        [self fetchDistanceWalkingRunning:frequency endDate: date days:0 callback:^(NSArray * result) {
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
                [self fetchSleepPattern:date frequency:frequency days:0 callback:^(NSArray * results) {
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
                [self fetchSleepPattern:date frequency:frequency days:0 callback:^(NSArray * results) {
                    NSMutableArray *data = [[NSMutableArray alloc]init];
                    NSLog(@"weekly sleep results, %@", results);
                    if([results count]){
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
                    }
                    if([data count]<7 && [data count]>0){
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


-(void) injectJavascript:(NSString *) javascript{
//    NSLog(@"javascript to be injected %@",javascript);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self evaluateJavaScript:javascript completionHandler:^(NSString *result, NSError *error) {
            if(error != nil) {
                NSLog(@"injectJavascript Error: %@",error);
                return;
            }
//            NSLog(@"SomeFunction Success %@",result);
        }];
    });
}

-(void) openDependentLink:(NSURL *) url{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *btnImage = [UIImage systemImageNamed:@"chevron.left"];
    [button setImage:btnImage forState:UIControlStateNormal];
    [button addTarget:self action:@selector(closeAddDependentView:)
    forControlEvents:UIControlEventTouchUpInside];
    [button setTintColor: UIColor.blackColor];
    button.frame = CGRectMake(0.0, 60.0, 50.0, 40.0);
    
    addDependentViewController = [[UIViewController alloc] init];
    addDependentViewController.modalPresentationStyle = 0;
    [addDependentViewController.view addSubview:button];
    addDependentViewController.view.frame = CGRectMake(0.0, 100.0, self.frame.size.width, self.frame.size.height-100.0);
    [currentTopVC presentViewController:addDependentViewController animated:false completion:nil];

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    WKWebView *addDependentView = [[WKWebView alloc] initWithFrame:addDependentViewController.view.frame configuration:config];
    NSURLRequest* request = [NSURLRequest requestWithURL: url];
    [addDependentView loadRequest:request];
    [addDependentViewController.view addSubview:addDependentView];
}

-(void) preprocessEmbellishRequest:(NSArray*) steps calories:(NSArray*) calories distance:(NSArray*) distance date:(NSDate*) date {
//    NSLog(@"steps=%@, calories=%@, distance=%@, date=%@",steps, calories, distance, date);
                NSMutableArray* embellishData = [NSMutableArray new];
                int count=0;
                for (NSNumber* step in steps) {
                    NSDictionary *dict = @{
                            @"st" : step,
                            @"c" : [calories objectAtIndex:count],
                            @"d" : [distance objectAtIndex:count],
                            @"h" : [NSNumber numberWithInt:count],
                            @"s" : @"",
                    };
                    count++;
                    [embellishData addObject:dict];
                }
//                NSLog(@"the httpBody is, %lu",(unsigned long)[embellishData count]);
                NSTimeInterval unixDate = [date timeIntervalSince1970]*1000;
                NSInteger finalDate = unixDate;
                NSDictionary *httpBody = @{
                        @"data" : embellishData,
                        @"dt" : [NSNumber numberWithLong:finalDate],
                        @"platform" : @"IOS",
                };
                
                [self PostJson:[NSString stringWithFormat:@"%@/users/embellish-sync?isPWA=yes",baseUrl] body:httpBody authToken:token];
                NSLog(@"embellish-sync data is, %@",httpBody.description);
}

-(void) preprocessUatRequest:(NSArray*) steps calories:(NSArray*) calories date:(NSDate*) date callback:(void(^)(NSDictionary*))callback {
//    NSLog(@"steps=%@, calories=%@, date=%@",steps, calories, date);
                NSMutableArray* embellishData = [NSMutableArray new];
                int count=0;
                for (NSNumber* step in steps) {
                    NSDictionary *dict = @{
                            @"hour" : [NSNumber numberWithInt:count],
                            @"steps" : step,
                            @"calories" : [calories objectAtIndex:count],
                    };
                    count++;
                    [embellishData addObject:dict];
                }
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                dateFormatter.dateFormat = @"yyyy-MM-dd";
                NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];


                NSDictionary *httpBody = @{
                        @"activity_data" : embellishData,
                        @"activity_date" : dateString,
                };
                callback(httpBody);
}

-(void)callUatApi:(NSMutableArray*) dates{
    __block NSMutableArray *uatData = [NSMutableArray new];
    dispatch_group_t loadUatData=dispatch_group_create();
    dispatch_group_enter(loadUatData);
    for (NSDate* date in dates) {
        dispatch_group_t loadDetailsGroup=dispatch_group_create();
        __block NSArray* steps;
        __block NSArray* calories;
        dispatch_group_enter(loadDetailsGroup);
        [self fetchHourlySteps:date callback:^(NSArray * data) {
            steps = [data objectAtIndex:0];
            calories = [data objectAtIndex:1];
            dispatch_group_leave(loadDetailsGroup);
        }];
        dispatch_group_notify(loadDetailsGroup,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
            if([steps count]>0 && [calories count] > 0){
            [self preprocessUatRequest:steps calories:calories date:date callback:^(NSDictionary * data) {
//                NSLog(@"the preprocessUatRequest data is==================>>> %@ <<<==================",[data description]);
                [uatData addObject:data];
                if([uatData count] == [dates count]){
                    dispatch_group_leave(loadUatData);
                }
             }];
            }
        });
        
    }
    dispatch_group_notify(loadUatData,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        NSLog(@"the uat data in dispatch_group_notify is, %@",[uatData description]);
        NSString *endpoint = [NSString stringWithFormat: @"%@/fitness-activity", self->tataAIG_base_url];
        NSDictionary *httpBody = @{
                @"data" : uatData,
                @"member_id" : self->memberId,
        };
        [self PostJson:endpoint body:httpBody authToken:self->tataAIG_auth_token];
    });

}

-(void)callEmbellishApi:(NSMutableArray*) dates{
    for (NSDate* date in dates) {
        dispatch_group_t loadDetailsGroup=dispatch_group_create();
        __block NSArray* steps;
        __block NSArray* calories;
        __block NSArray* distance;
        for(int i = 0; i<2;i++){
            dispatch_group_enter(loadDetailsGroup);
            if(i==0){
                [self fetchHourlySteps:date callback:^(NSArray * data) {
                    steps = [data objectAtIndex:0];
                    calories = [data objectAtIndex:1];
                    dispatch_group_leave(loadDetailsGroup);
                }];
            }else if(i==1){
                [self fetchHourlyDistanceWalkingRunning:date callback:^(NSArray * dist) {
                    distance = dist;
                    dispatch_group_leave(loadDetailsGroup);
                }];
            }
        }
        dispatch_group_notify(loadDetailsGroup,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
            if([steps count]>0 && [calories count] > 0 && [distance count]>0){
            [self preprocessEmbellishRequest:steps calories:calories distance:distance date:date];
            }
        });
    }
}

- (void) urlOpened:(NSURL*) url{
//    NSLog(@"urlOpened triggered %@ %hhd",url.absoluteString,fitbitConnectionTriggered);

    if(fitbitConnectionTriggered){
        if ([url.absoluteString rangeOfString:@"fitbit"].location == NSNotFound) {
            NSLog(@"url not matched");
        } else {
            NSLog(@"url matched");
            NSString *javascript = [NSString stringWithFormat:@"fitbitConnectSuccessfully(true)"];
            [self postNotification:@"FitbitPermissionGranted"];
            [self injectJavascript:javascript];
            fitbitConnectionTriggered = FALSE;
        }
    }
}

-(void)callSyncData:(NSInteger) days dates:(NSMutableArray*)dates{
    dispatch_group_t syncDataGroup=dispatch_group_create();
    __block NSArray* steps;
    __block NSArray* calorie;
    __block NSArray* distanceData;
    __block NSArray* activityData;
    __block NSArray* sleep;
//    NSLog(@"days are %ld",(long)days);
    for (int i = 0; i<4; i++) {
        dispatch_group_enter(syncDataGroup);
        if(i==0){
            [self fetchSteps:@"custom" endDate:[NSDate date] days:days callback:^(NSArray * data) {
//                NSLog(@"steps data for custom range is, %@ length %lu",[data objectAtIndex:0],[[data objectAtIndex:0] count]);
                steps = [data objectAtIndex:0];
                calorie = [data objectAtIndex:1];
                dispatch_group_leave(syncDataGroup);
            }];
        }else if(i==1){
            [self fetchDistanceWalkingRunning:@"custom" endDate:[NSDate date] days:days callback:^(NSArray * distance) {
//                NSLog(@"distance data for custom range is, %@ length %lu",distance, [distance count]);
                distanceData=distance;
                dispatch_group_leave(syncDataGroup);
            }];
        }else if(i==2){
            [self getActivityTime:[NSDate date] frequency:@"custom" days:days callback:^(NSMutableArray * activity) {
                NSMutableArray* arr = [activity objectAtIndex:1];
//                NSLog(@"activity data for custom range is, %@ length %lu",activity, [arr count]);
                activityData = arr;
                dispatch_group_leave(syncDataGroup);
            }];
        }else if(i==3){
            [self fetchSleepPattern:[NSDate date] frequency:@"custom" days:days callback:^(NSArray * sleepData) {
                NSMutableArray *data = [[NSMutableArray alloc]init];
                for (NSDictionary* item in sleepData) {
                    NSString* sleepValue = [item valueForKey:@"value"];
                    if([sleepValue isEqualToString:@"INBED"]||[sleepValue isEqualToString:@"ASLEEP"]){
                        NSDate* startDate = [item valueForKey:@"startDate"];
                        NSDate* endDate = [item valueForKey:@"endDate"];
                        NSTimeInterval interval;
                        NSNumber* sleepTime =
                        [NSNumber numberWithDouble: [@(floor([startDate timeIntervalSince1970] * 1000)) longLongValue]];
                        NSNumber* wakeupTime =
                        [NSNumber numberWithDouble: [@(floor([endDate timeIntervalSince1970] * 1000)) longLongValue]];
//                        NSLog(@"startDate before calendar function ,%@",startDate);
                        [self->calendar rangeOfUnit:NSCalendarUnitDay
                                           startDate:&startDate
                                            interval:&interval
                                             forDate:endDate];
//                        NSLog(@"startDate after calendar function ,%@",startDate);
                        NSNumber* startTimestamp =
                        [NSNumber numberWithDouble: [@(floor([startDate timeIntervalSince1970] * 1000)) longLongValue]];
                        NSDictionary *element = @{
                                @"sleepTime" : sleepTime,
                                @"wakeupTime" : wakeupTime,
                                @"endDate" : endDate,
                                @"startTimestamp" : startTimestamp,
                        };
                        NSMutableDictionary *elem = [NSMutableDictionary dictionaryWithDictionary:element];

                        if([data count]>0){
                            for (int i=0;i<[data count]; i++) {
                                NSMutableDictionary* item = [data objectAtIndex:i];
                                NSDate* itemEndDate = [item objectForKey:@"endDate"];
                                NSString* itemSleepTime = [item objectForKey:@"sleepTime"];
                                if([[NSCalendar currentCalendar] isDate:itemEndDate inSameDayAsDate:endDate]){
                                    [elem setValue:itemSleepTime forKey:@"sleepTime"];
                                    [data removeObjectAtIndex:i];
//                                    NSLog(@"removed date is, ====>> %@",endDate);
                                }
                            }
                            [data addObject:elem];
                        }else{
                            [data addObject:elem];
                        }
                    }
                }
                sleep = data;
//                NSLog(@"fetchSleepPattern data is, ====>> %lu %@",(unsigned long)[data count],data);
                dispatch_group_leave(syncDataGroup);
            }];
        }
    }

    dispatch_group_notify(syncDataGroup,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
    if([steps count]>0 && [distanceData count]>0 && [activityData count]>0 && [sleep count]>0)
       {
           NSMutableArray* dailySyncData =[NSMutableArray new];
        int count = 0;
        for (NSDate* date in dates) {
            NSDictionary* dict = @{
                @"steps":[steps objectAtIndex:count],
                @"calories":[calorie objectAtIndex:count],
                @"distance":[distanceData objectAtIndex:count],
                @"date":date
            };
            [dailySyncData addObject:[NSMutableDictionary dictionaryWithDictionary:dict]];
            count++;
        }
        for (NSMutableDictionary* dict in dailySyncData) {
            for(NSMutableDictionary* sleepData in sleep){
                if([[NSCalendar currentCalendar] isDate:[sleepData objectForKey:@"endDate"] inSameDayAsDate:[dict objectForKey:@"date"]]){
                    NSString* sleepTime = [sleepData objectForKey:@"sleepTime"];
                    NSString* wakeupTime = [sleepData objectForKey:@"wakeupTime"];
                    [dict setObject:[NSString stringWithFormat:@"%@-%@",sleepTime,wakeupTime] forKey:@"sleep"];
                }
            }
            
            for(NSMutableDictionary* activity in activityData){
                if([[NSCalendar currentCalendar] isDate:[activity objectForKey:@"date"] inSameDayAsDate:[dict objectForKey:@"date"]]){
                    NSString* activityValue = [activity objectForKey:@"value"];
                    [dict setObject:activityValue forKey:@"activity"];
                }
            }
            
            [dict setObject: [NSNumber numberWithDouble: [@(floor([[dict objectForKey:@"date"] timeIntervalSince1970] * 1000)) longLongValue]]
              forKey:@"date"];
        }
        NSDictionary *httpBody = @{
                @"fitnessData" : dailySyncData,
                @"platform" : @"IOS",
        };
           [self PostJson:[NSString stringWithFormat:@"%@/users/data-sync?isPWA=yes",self->baseUrl] body:httpBody authToken:self->token];
        NSLog(@"dailySyncData is, %@",httpBody);
           
       }
    });
}

-(void) closePWA{
    [self postNotification:@"ClosePWAEvent"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"VisitEventType" object:nil];
    [self.videoCallDelegate.navigationController popViewControllerAnimated:YES];
    [self.configuration.userContentController removeAllUserScripts];
    [self removeFromSuperview];
    self.navigationDelegate = nil;
    self.scrollView.delegate = nil;
    [self stopLoading];
}

-(void) postNotification:(NSString *) event{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VisitEventType" object:nil userInfo:@{
        @"event":event
    }];
}

-(void) postNotification:(NSString *) event value:(NSString*)value{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VisitEventType" object:nil userInfo:@{
        @"event":event,
        @"value1":value
    }];
}

-(void) postHraQuestionAnsweredNotification:(NSString*)value total:(NSString*)total{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VisitEventType" object:nil userInfo:@{
        @"event":@"HRAQuestionAnswered",
        @"current":value,
        @"total":total
    }];
}

- (void)setSyncingEnabled:(BOOL)value {
    syncingEnabled = value;
}

- (void) callHraApi{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *isIncomplete = [prefs stringForKey:@"isIncomplete"];
    if(isIncomplete && (long)[isIncomplete integerValue]==0){
        NSString *data = [prefs stringForKey:@"data"];
        NSError *jsonError;
        NSData *objectData = [data dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                              options:NSJSONReadingMutableContainers
                                                error:&jsonError];
        
        NSLog(@"the hra-fitness-details req, %@",json);
        [self PutJson:[NSString stringWithFormat:@"%@/hra-fitness-details",self->tataAIG_base_url] body:json authToken:self->tataAIG_auth_token];
    }
}

- (NSDate *)convertStringToDate:(NSString *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    NSLocale *posix = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [formatter setLocale:posix];
    return [formatter dateFromString:date];
}

- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    NSData *data = [message.body dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSString *methodName = [json valueForKey:@"method"];
    NSLog(@"methodName is %@",methodName);
    if([methodName isEqualToString:@"disconnectFromFitbit"]){
        [self postNotification:@"FibitDisconnected"];
    }else if([methodName isEqualToString:@"connectToGoogleFit"]) {
        [VisitIosHealthController canAccessHealthKit:^(BOOL value){
            if(value){
                // [self postNotification:@"FitnessPermissionGranted"];
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
    }else if([methodName isEqualToString:@"connectToFitbit"]) {
        NSString *urlString = [json valueForKey:@"url"];
        NSURL *url = [NSURL URLWithString:urlString];
        if([[UIApplication sharedApplication] canOpenURL:url]){
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                fitbitConnectionTriggered = TRUE;
        }else{
            NSLog(@"Cannot open url");
        }
    }else if([methodName isEqualToString:@"inHraEndPage"]){
        NSString *javascript = [NSString stringWithFormat:@"isIosUser(true)"];
        [self injectJavascript:javascript];
        [VisitIosHealthController canAccessHealthKit:^(BOOL value){
            if(value){
                // [self postNotification:@"FitnessPermissionGranted"];
                NSString *javascript = [NSString stringWithFormat:@"showConnectToGoogleFit(false)"];
                [self injectJavascript:javascript];
            }else{
                NSString *javascript = [NSString stringWithFormat:@"showConnectToGoogleFit(true)"];
                [self injectJavascript:javascript];
            }
        }];
    }else if([methodName isEqualToString:@"hraQuestionAnswered"]){
        NSString* current = [json valueForKey:@"current"];
        NSString* total = [json valueForKey:@"total"];
        [self postHraQuestionAnsweredNotification:current total:total];
    }else if([methodName isEqualToString:@"hraCompleted"]){
        [self postNotification:@"HRA_Completed"];
    }else if([methodName isEqualToString:@"googleFitConnectedAndSavedInPWA"]){
        [self postNotification:@"HealthKitConnectedAndSavedInPWA"];
        [self closePWA];
    }else if([methodName isEqualToString:@"inFitSelectScreen"]){
        NSString *javascript = [NSString stringWithFormat:@"isIosUser(true)"];
        [self injectJavascript:javascript];
        [VisitIosHealthController canAccessHealthKit:^(BOOL value){
            if(value){
                // [self postNotification:@"FitnessPermissionGranted"];
                NSString *javascript = [NSString stringWithFormat:@"googleFitStatus(true)"];
                [self injectJavascript:javascript];
            }else{
                NSString *javascript = [NSString stringWithFormat:@"googleFitStatus(false)"];
                [self injectJavascript:javascript];
            }
        }];
    }else if([methodName isEqualToString:@"updateApiBaseUrl"]){
        baseUrl = [json valueForKey:@"apiBaseUrl"];
        token = [json valueForKey:@"authtoken"];
        NSTimeInterval gfHourlyLastSync = [[json valueForKey:@"gfHourlyLastSync"] doubleValue];
        NSTimeInterval googleFitLastSync = [[json valueForKey:@"googleFitLastSync"] doubleValue];
        NSDate* hourlyDataSyncTime = [NSDate dateWithTimeIntervalSince1970: gfHourlyLastSync/1000];
        NSDate* dailyDataSyncTime = [NSDate dateWithTimeIntervalSince1970: googleFitLastSync/1000];
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        if(![[json valueForKey:@"memberId"] isEqual:@"<null>"]){
            memberId = [json valueForKey:@"memberId"];
        }
        [prefs setObject:[json valueForKey:@"gfHourlyLastSync"] forKey:@"uatLastSyncTime"];
        
        if(syncingEnabled){
            [VisitIosHealthController canAccessHealthKit:^(BOOL value){
                if(value){
                    // [self postNotification:@"FitnessPermissionGranted"];
                    NSString *javascript = [NSString stringWithFormat:@"showConnectToGoogleFit(false)"];
                    [self injectJavascript:javascript];
                    [self getDateRanges:hourlyDataSyncTime callback:^(NSMutableArray * dates) {
                       if([dates count]>0){
                           [self callEmbellishApi:dates];
                           if(![self->memberId isEqual:@"<null>"]){
                               [self callUatApi:dates];
                           }
                       }
                    }];
                    [self getDateRanges:dailyDataSyncTime callback:^(NSMutableArray * dates) {
                        if([dates count]>0){
                            [self callSyncData:[dates count] dates:dates];
                        }
                    }];
                }else{
                    NSString *javascript = [NSString stringWithFormat:@"showConnectToGoogleFit(true)"];
                    [self injectJavascript:javascript];
                }
            }];
        }
        
    }else if([methodName isEqualToString:@"closeView"]){
        [self closePWA];
    }else if([methodName isEqualToString:@"startVideoCall"]){
        [self postNotification:@"StartVideoCall"];
        NSString *doctorName = [json valueForKey:@"doctorName"];
        NSString *profileImg = [json valueForKey:@"profileImg"];
        NSString *roomName = [json valueForKey:@"roomName"];
        NSString *token = [json valueForKey:@"token"];
        NSLog(@"doctorName=%@, profileImg=%@, roomName=%@, token=%@",doctorName,profileImg,roomName, token);
        [_videoCallDelegate segueToVideoCall:token roomName:roomName doctorName:doctorName doctorProfileImg:profileImg];
    }else if([methodName isEqualToString:@"openPDF"]){
        NSString *link = [json valueForKey:@"url"];
        NSURL *url = [NSURL URLWithString:link];
        NSData *pdfData = [NSData dataWithContentsOfURL:url];
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[pdfData] applicationActivities:nil];
        activityViewController.excludedActivityTypes = @[
            UIActivityTypeCopyToPasteboard,
            UIActivityTypePrint,
            UIActivityTypeMarkupAsPDF,
        ];
        [currentTopVC presentViewController:activityViewController animated:YES completion:nil];
    }else if([methodName isEqualToString:@"mailTo"]){
        NSString *email = [json valueForKey:@"email"];
        NSString *subject = [json valueForKey:@"subject"];
        NSString *mail = [NSString stringWithFormat: @"mailto:%@?subject=%@", email, subject];
        mail = [mail stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSURL *url = [NSURL URLWithString:mail];
        if([[UIApplication sharedApplication] canOpenURL:url]){
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }else{
            NSLog(@"Cannot open url");
        }
    }else if([methodName isEqualToString:@"openDependentLink"]){
        NSString* link = [[json valueForKey:@"link"] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSURL *url = [NSURL URLWithString:link];
        [self openDependentLink:url];
    }else if([methodName isEqualToString:@"pendingHraUpdation"]){
        NSString *javascript = [NSString stringWithFormat:@"updateHraToAig()"];
        [self injectJavascript:javascript];
    }else if([methodName isEqualToString:@"hraInComplete"]){
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSString *apiData = [json valueForKey:@"data"];
        NSString *isIncomplete = [json valueForKey:@"flag"];
        [prefs setObject:apiData forKey:@"data"];
        [prefs setObject:isIncomplete forKey:@"isIncomplete"];
        [self postNotification:@"hraInComplete"];
    }else if([methodName isEqualToString:@"askForGoogleFitGraphData"]){
        [self insertDataToCard];
    }else if([methodName isEqualToString:@"navigateToSettings"]){
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
    }else if([methodName isEqualToString:@"couponRedeemed"]){
        [self postNotification:@"couponRedeemed"];
    }else if([methodName isEqualToString:@"openLink"]){
        NSString* link = [[json valueForKey:@"link"] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSURL *url = [NSURL URLWithString:link];
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
    
}

@end
