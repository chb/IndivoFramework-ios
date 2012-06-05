//
//  INParser.h
//  IndivoFramework
//
//  Created by Pascal Pfiffner on 6/5/12.
//  Copyright (c) 2012 Harvard Medical School. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Indivo.h"							// so we have access to some macros

@class INSchemaParser;


typedef enum {
	INSchemaParserMessageTypeUnknown = 0,
	INSchemaParserMessageTypeLog,
	INSchemaParserMessageTypeNotification,
	INSchemaParserMessageTypeWarning,
	INSchemaParserMessageTypeError
} INSchemaParserMessageType;

@protocol INSchemaParserDelegate <NSObject>

- (NSString *)schemaParser:(INSchemaParser *)parser classNameForType:(NSString *)aType effectiveType:(NSString **)effectiveType isNew:(BOOL *)isNew;
- (void)schemaParser:(INSchemaParser *)parser didParseClass:(NSString *)className forName:(NSString *)name superclass:(NSString *)superclass forType:(NSString *)type properties:(NSArray *)properties;

- (void)schemaParser:(INSchemaParser *)parser isProcessingFileAtPath:(NSString *)filePath;
- (void)schemaParser:(INSchemaParser *)parser sendsMessage:(NSString *)message ofType:(INSchemaParserMessageType)type;

@end


/**
 *	An abstract schema parser class
 */
@interface INSchemaParser : NSObject

@property (nonatomic, weak) id <INSchemaParserDelegate> delegate;

+ (id)newWithDelegate:(id <INSchemaParserDelegate>)aDelegate;

- (BOOL)runFileAtPath:(NSString *)path error:(NSError **)error;

@end
