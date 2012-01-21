//
//  INClassGenerator.h
//  IndivoFramework
//
//  Created by Pascal Pfiffner on 1/20/12.
//  Copyright (c) 2012 Harvard Medical School. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const INClassGeneratorDidProduceLogNotification;
extern NSString *const INClassGeneratorLogStringKey;


@interface INClassGenerator : NSObject

- (BOOL)run;
- (BOOL)runFile:(NSString *)path withMappings:(NSMutableDictionary *)mapping;


@end
