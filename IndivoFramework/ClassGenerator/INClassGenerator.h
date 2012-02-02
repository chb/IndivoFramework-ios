//
//  INClassGenerator.h
//  IndivoFramework
//
//  Created by Pascal Pfiffner on 1/20/12.
//  Copyright (c) 2012 Harvard Medical School. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Indivo.h"

#define SKIP_ID_ATTRIBUTES 1				///< If set to 1, attributes named "id" will be skipped (it's in our superclass anyway, so we always skip it)


extern NSString *const INClassGeneratorDidProduceLogNotification;
extern NSString *const INClassGeneratorLogStringKey;
extern NSString *const INClassGeneratorBaseClass;
extern NSString *const INClassGeneratorClassPrefix;
extern NSString *const INClassGeneratorTypePrefix;

void runOnMainQueue(dispatch_block_t block);


/**
 *	A class that can generate Objective-C classes from Indivo XML schemas
 */
@interface INClassGenerator : NSObject

@property (nonatomic, assign) NSUInteger numSchemasParsed;
@property (nonatomic, assign) NSUInteger numClassesGenerated;

- (void)runFrom:(NSString *)inputPath into:(NSString *)outDirectory callback:(INCancelErrorBlock)aCallback;
- (BOOL)runFile:(NSString *)path withMapping:(NSMutableDictionary *)mapping error:(NSError **)error;

+ (NSString *)applySubstitutions:(NSDictionary *)substitutions toTemplate:(NSString *)aTemplate;
+ (NSString *)applyToHeaderTemplate:(NSDictionary *)substitutions;
+ (NSString *)applyToBodyTemplate:(NSDictionary *)substitutions;


@end
