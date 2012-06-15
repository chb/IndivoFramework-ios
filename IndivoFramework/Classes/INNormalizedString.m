/*
 INNormalizedString.m
 IndivoFramework
 
 Created by Pascal Pfiffner on 6/4/12.
 Copyright (c) 2012 Boston Children's Hospital
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

#import "INNormalizedString.h"

@implementation INNormalizedString


+ (NSString *)nodeType
{
	return @"xs:normalizedString";
}


/**
 *	We override the setter to replace any whitespace character with a space, as required for normalized strings.
 */
- (void)setString:(NSString *)aString
{
	if (aString != self.string) {
		NSString *trimmed = [[aString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsJoinedByString:@" "];
		
		// are we restricted to specific values?
		NSArray *restricted = [[self class] restrictedTo];
		if (restricted && ![restricted containsObject:trimmed]) {
			DLog(@"The string \"%@\" is not a possible value for an instance of \"%@\", discarding", trimmed, NSStringFromClass([self class]));
			trimmed = nil;
		}
		
		[super setString:trimmed];
	}
}


/**
 *	Subclasses can be restricted to certain possible strings. If so, the subclass can return a non-nil array from this class method and the string is then
 *	guaranteed to always have a valid value.
 */
+ (NSArray *)restrictedTo
{
	return nil;
}


@end
