/*
 INAttr.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 10/16/11.
 Copyright (c) 2011 Children's Hospital Boston
 
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

#import "INAttr.h"

@implementation INAttr

@synthesize attributes;


- (void)setFromNode:(INXMLNode *)node
{
	[super setFromNode:node];
	self.attributes = node.attributes;
}

+ (NSString *)nodeType
{
	return @"xs:complexType";
}

- (BOOL)isNull
{
	return ([attributes count] < 1);
}

- (NSString *)tagString
{
	if ([attributes count] < 1) {
		return [super tagString];
	}
	
	NSMutableString *attrString = [NSMutableString string];
	for (NSString *key in [attributes allKeys]) {
		NSString *value = [attributes objectForKey:key];
		if (value) {
			[attrString appendFormat:@" %@=\"%@\"", key, value];
		}
	}
	return [NSString stringWithFormat:@"%@%@", [super tagString], attrString];
}


@end
