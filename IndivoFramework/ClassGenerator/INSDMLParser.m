//
//  INSDMLParser.m
//  IndivoFramework
//
//  Created by Pascal Pfiffner on 6/5/12.
//  Copyright (c) 2012 Harvard Medical School. All rights reserved.
//

#import "INSDMLParser.h"

NSString *const INClassGeneratorSDMLModelnameKey = @"__modelname__";


@interface INSDMLParser ()

- (NSDictionary *)process:(NSDictionary *)dict error:(NSError **)error;

@end


@implementation INSDMLParser


- (BOOL)runFileAtPath:(NSString *)path error:(NSError **)error
{
	if (!path) {
		return NO;
	}
	[self.delegate schemaParser:self isProcessingFileAtPath:path];
	
	// read JSON
	NSData *jsonData = [NSData dataWithContentsOfFile:path options:0 error:error];
	if (!jsonData) {
		return NO;
	}
	
	// parse JSON
	id json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:error];
	if (!json) {
		return NO;
	}
	
	// process
	if ([json isKindOfClass:[NSArray class]]) {
		for (NSDictionary *dict in json) {
			if (![self process:dict error:error]) {
				return NO;
			}
		}
	}
	else if (![self process:json error:error]) {
		return NO;
	}
	return YES;
}


/**
 *	Process a dictionary that represents a class
 */
- (NSDictionary *)process:(NSDictionary *)dict error:(NSError **)error
{
	if (![dict isKindOfClass:[NSDictionary class]]) {
		ERR(error, @"Not a dictionary, cannot process SDML", 0)
		return nil;
	}
	
	// main properties
	NSString *modelName = [dict objectForKey:INClassGeneratorSDMLModelnameKey];
	NSString *usedType = modelName;
	NSString *className = [self.delegate schemaParser:self classNameForType:modelName effectiveType:&usedType];
	
	// loop elements
	NSMutableArray *properties = [NSMutableArray arrayWithCapacity:[dict count]-1];
	for (NSString *key in [dict allKeys]) {
		if (![key isKindOfClass:[NSString class]]) {
			NSString *errMsg = [NSString stringWithFormat:@"Key %@ is not a string!", key];
			ERR(error, errMsg, 0)
			return nil;
		}
		
		if ([INClassGeneratorSDMLModelnameKey isEqualToString:key]) {
			continue;
		}
		
		// element is a dictionary, i.e. a nested class description
		id elem = [dict objectForKey:key];
		if ([elem isKindOfClass:[NSDictionary class]]) {
			NSDictionary *nested = [self process:elem error:error];
			if (nested) {
				[properties addObject:nested];
			}
		}
		
		// if it's a string, it points to a class
		else if ([elem isKindOfClass:[NSString class]]) {
			NSString *elemClass = [self.delegate schemaParser:self existingClassNameForType:elem];
			if (!elemClass) {
				NSString *message = [NSString stringWithFormat:@"No class for property %@ (type: %@), omitting", key, elem];
				[self.delegate schemaParser:self sendsMessage:message ofType:INSchemaParserMessageTypeNotification];
			}
			else {
				NSDictionary *elemDict = [NSDictionary dictionaryWithObjectsAndKeys:key, @"name", elemClass, @"class", nil];
				if (elemDict) {
					[properties addObject:elemDict];
				}
			}
		}
	}
	
	// tell the delegate
	[self.delegate schemaParser:self didParseClass:className forName:modelName superclass:nil forType:usedType properties:properties];
	
	// return ourselves
	return [NSDictionary dictionaryWithObjectsAndKeys:modelName, @"name", className, @"class", nil];
}


@end
