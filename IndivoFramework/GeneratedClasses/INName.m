/*
 INName.m
 IndivoFramework
 
 Created by Indivo Class Generator on 6/22/2012.
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

#import "INName.h"


@implementation INName

@synthesize familyName, givenName, middleName, prefix, suffix;


/**
 *	We need to overwrite this method because the mapping is not 1:1 with ivar names for this model
 */
- (void)setFromFlatParent:(INXMLNode *)parent prefix:(NSString *)nodePrefix
{
	if (parent) {
		BOOL hasPrefix = ([nodePrefix length] > 0);
		NSString *familyNameFull = hasPrefix ? [NSString stringWithFormat:@"%@_%@", nodePrefix, @"family"] : @"family";
		NSString *givenNameFull = hasPrefix ? [NSString stringWithFormat:@"%@_%@", nodePrefix, @"given"] : @"given";
		NSString *middleNameFull = hasPrefix ? [NSString stringWithFormat:@"%@_%@", nodePrefix, @"middle"] : @"middle";
		NSString *prefixFull = hasPrefix ? [NSString stringWithFormat:@"%@_%@", nodePrefix, @"prefix"] : @"prefix";
		NSString *suffixFull = hasPrefix ? [NSString stringWithFormat:@"%@_%@", nodePrefix, @"suffix"] : @"suffix";
		
		// look for these nodes
		for (INXMLNode *child in [parent children]) {
			NSString *childName = [child attr:@"name"];
			if ([familyNameFull isEqualToString:childName]) {
				self.familyName = child.text;
			}
			else if ([givenNameFull isEqualToString:childName]) {
				self.givenName = child.text;
			}
			else if ([middleNameFull isEqualToString:childName]) {
				self.middleName = child.text;
			}
			else if ([prefixFull isEqualToString:childName]) {
				self.prefix = child.text;
			}
			else if ([suffixFull isEqualToString:childName]) {
				self.suffix = child.text;
			}
		}
	}
}


@end