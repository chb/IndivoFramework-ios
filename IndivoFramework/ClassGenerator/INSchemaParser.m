//
//  INParser.m
//  IndivoFramework
//
//  Created by Pascal Pfiffner on 6/5/12.
//  Copyright (c) 2012 Harvard Medical School. All rights reserved.
//

#import "INSchemaParser.h"

@implementation INSchemaParser

@synthesize delegate;


+ (id)newWithDelegate:(id <INSchemaParserDelegate>)aDelegate
{
	if (!aDelegate) {
		DLog(@"You must supply a delegate");
		return nil;
	}
	
	INSchemaParser *p = [self new];
	p.delegate = aDelegate;
	
	return p;
}



#pragma mark - File Handling
- (BOOL)runFileAtPath:(NSString *)path error:(NSError **)error
{
	if (NULL != error) {
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Method \"runFile:withMapping:error:\" not implemented" forKey:NSLocalizedDescriptionKey];
		*error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:userInfo];
	}
	return NO;
}


@end
