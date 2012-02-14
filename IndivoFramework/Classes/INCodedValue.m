/*
 INCodedValue.m
 IndivoFramework
 
 Created by Pascal Pfiffner on 9/26/11.
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

#import "INCodedValue.h"

@implementation INCodedValue

@synthesize type, value, abbrev, text;


- (void)setFromNode:(INXMLNode *)node
{
	[super setFromNode:node];
	
	self.type = [node attr:@"type"];
	self.value = [node attr:@"value"];
	self.abbrev = [node attr:@"abbrev"];
	self.text = node.text;
}

+ (NSString *)nodeType
{
	return @"indivo:CodedValue";
}

- (BOOL)isNull
{
	return ([value length] < 1 && [abbrev length] < 1 && [text length] < 1);
}

- (NSString *)xml
{
	if ([self isNull]) {
		return [NSString stringWithFormat:@"<%@ />", [self tagString]];
	}
	if ([text length] > 0) {
		return [NSString stringWithFormat:@"<%@%@%@%@>%@</%@>",
				[self tagString],
				(self.type ? [NSString stringWithFormat:@" type=\"%@\"", [self.type xmlSafe]] : @""),
				(self.abbrev ? [NSString stringWithFormat:@" abbrev=\"%@\"", [self.abbrev xmlSafe]] : @""),
				(self.value ? [NSString stringWithFormat:@" value=\"%@\"", [self.value xmlSafe]] : @""),
				[self.text xmlSafe],
				self.nodeName];
	}
	return [NSString stringWithFormat:@"<%@%@%@%@ />",
			[self tagString],
			(self.type ? [NSString stringWithFormat:@" type=\"%@\"", [self.type xmlSafe]] : @""),
			(self.abbrev ? [NSString stringWithFormat:@" abbrev=\"%@\"", [self.abbrev xmlSafe]] : @""),
			(self.value ? [NSString stringWithFormat:@" value=\"%@\"", [self.value xmlSafe]] : @"")];
}


@end
