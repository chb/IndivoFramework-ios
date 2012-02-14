//
//  NSCharacterSet+Extension.m
//  IndivoFramework
//
//  Created by Pascal Pfiffner on 2/14/12.
//  Copyright (c) 2012 Harvard Medical School. All rights reserved.
//

#import "NSCharacterSet+Extension.h"

@implementation NSCharacterSet (Extension)

/**
 *	Returns a union between decimalDigitCharacteSet and "."
 */
+ (NSCharacterSet *)numericCharacterSet
{
	static NSCharacterSet *NSCharacterSet_numericCharacterSet = nil;
	if (!NSCharacterSet_numericCharacterSet) {
		NSMutableCharacterSet *numSet = [[NSCharacterSet decimalDigitCharacterSet] mutableCopy];
		[numSet addCharactersInString:@"."];
		NSCharacterSet_numericCharacterSet = [numSet copy];
	}
	return NSCharacterSet_numericCharacterSet;
}


@end
