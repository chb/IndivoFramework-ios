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
 *	This method takes a dictionary, array or string that describes a property type, handles the object and returns a dictionary with the class name and, if
 *	it's a container, the class for objects in the container
 *	@return An NSDictionary with "className" and maybe "containedClassName"
 */
- (NSDictionary *)processProperty:(id)object
{
	if (!object) {
		return nil;
	}
	
	// dictionary, which is an inline class definition
	if ([object isKindOfClass:[NSDictionary class]]) {
		NSError *error = nil;
		NSDictionary *nested = [self process:object error:&error];
		if (nested) {
			return [NSDictionary dictionaryWithObject:[nested objectForKey:@"name"] forKey:@"className"];
		}
		DLog(@"Error processing dictionary: %@", [error localizedDescription]);
	}
	
	// it's an array - we use the first element only
	else if ([object isKindOfClass:[NSArray class]]) {
		id child = ([(NSArray *)object count] > 0) ? [(NSArray *)object objectAtIndex:0] : nil;
		NSDictionary *childDict = [self processProperty:child];
		if (childDict) {
			return [NSDictionary dictionaryWithObjectsAndKeys:
					@"NSArray", @"className",
					[childDict objectForKey:@"className"], @"containedClassName", nil];
		}
	}
	
	// if it's a string, it points to a class
	else if ([object isKindOfClass:[NSString class]]) {
		NSString *elemClass = [self.delegate schemaParser:self existingClassNameForType:object];
		if (elemClass) {
			return [NSDictionary dictionaryWithObject:elemClass forKey:@"className"];
		}
	}
	
	return nil;
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
		
		// get the class
		id elem = [dict objectForKey:key];
		NSDictionary *propDict = [self processProperty:elem];
		NSString *elemClass = [propDict objectForKey:@"className"];
		NSString *containedElemClass = [propDict objectForKey:@"containedClassName"];
		if ([elemClass length] < 1) {
			NSString *message = [NSString stringWithFormat:@"No class for property %@ (type: %@), omitting", key, elem];
			[self.delegate schemaParser:self sendsMessage:message ofType:INSchemaParserMessageTypeNotification];
			continue;
		}
		
		// add to property array
		NSDictionary *elemDict = [NSDictionary dictionaryWithObjectsAndKeys:key, @"name", elemClass, @"class", containedElemClass, @"itemClass", nil];
		if (elemDict) {
			[properties addObject:elemDict];
		}
	}
	
	// tell the delegate
	[self.delegate schemaParser:self didParseClass:className forName:modelName superclass:nil forType:usedType properties:properties];
	
	// return ourselves
	return [NSDictionary dictionaryWithObjectsAndKeys:modelName, @"name", className, @"class", nil];
}


@end
