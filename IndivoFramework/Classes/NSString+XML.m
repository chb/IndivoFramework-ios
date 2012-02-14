//
//  NSString+XML.m
//  IndivoFramework
//
//  Created by Pascal Pfiffner on 1/13/12.
//  Copyright (c) 2012 Harvard Medical School. All rights reserved.
//

#import "NSString+XML.h"
#import "NSCharacterSet+Extension.h"

@implementation NSString (XML)


/**
 *	Escapes XML special chars (see "xmlEscape")
 */
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


/**
 *	Returns only the number-representing part of a string
 */
- (NSString *)numericString
{
	if ([self length] < 1) {
		return self;
	}
	
	NSCharacterSet *numSet = [NSCharacterSet numericCharacterSet];
	if (NSNotFound == [self rangeOfCharacterFromSet:[numSet invertedSet]].location) {
		return self;
	}
	
	// do we even have numbers?
	NSRange numRange = [self rangeOfCharacterFromSet:numSet];
	if (NSNotFound == numRange.location) {
		return @"";
	}
	
	// ok, trim from start
	NSScanner *scanner = [NSScanner scannerWithString:self];
	NSString *newSelf = nil;
	[scanner scanUpToCharactersFromSet:numSet intoString:NULL];
	[scanner scanCharactersFromSet:numSet intoString:&newSelf];
	return newSelf;
}


@end


@implementation NSMutableString (XML)


/**
 *	Escapes these XML special chars: & " ' < >
 */
- (void)xmlEscape
{
	/// @todo 5 iterations over the full string, it's probably possible to do this more effectively. NSScanner!
    [self replaceOccurrencesOfString:@"&"  withString:@"&amp;"  options:NSLiteralSearch range:NSMakeRange(0, [self length])];
    [self replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:NSLiteralSearch range:NSMakeRange(0, [self length])];
    [self replaceOccurrencesOfString:@"'"  withString:@"&#x27;" options:NSLiteralSearch range:NSMakeRange(0, [self length])];
    [self replaceOccurrencesOfString:@">"  withString:@"&gt;"   options:NSLiteralSearch range:NSMakeRange(0, [self length])];
    [self replaceOccurrencesOfString:@"<"  withString:@"&lt;"   options:NSLiteralSearch range:NSMakeRange(0, [self length])];
}


@end
