//
//  NSString+XML.m
//  IndivoFramework
//
//  Created by Pascal Pfiffner on 1/13/12.
//  Copyright (c) 2012 Harvard Medical School. All rights reserved.
//

#import "NSString+XML.h"

@implementation NSString (XML)

- (NSString *)xmlSafe
{
	if ([self length] < 1) {
		return self;
	}
	
	/// @todo Maybe it's performance-wise wise to only copy if we actually contain escapeable chars?
	NSMutableString *mutable = [self mutableCopy];
	[mutable xmlEscape];
	return mutable;
}


@end


@implementation NSMutableString (XML)

- (void)xmlEscape
{
	/// @todo 5 iterations over the full string, it's probably possible to do this more effective. NSScanner!
    [self replaceOccurrencesOfString:@"&"  withString:@"&amp;"  options:NSLiteralSearch range:NSMakeRange(0, [self length])];
    [self replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:NSLiteralSearch range:NSMakeRange(0, [self length])];
    [self replaceOccurrencesOfString:@"'"  withString:@"&#x27;" options:NSLiteralSearch range:NSMakeRange(0, [self length])];
    [self replaceOccurrencesOfString:@">"  withString:@"&gt;"   options:NSLiteralSearch range:NSMakeRange(0, [self length])];
    [self replaceOccurrencesOfString:@"<"  withString:@"&lt;"   options:NSLiteralSearch range:NSMakeRange(0, [self length])];
}


@end
