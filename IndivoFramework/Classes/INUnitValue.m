/*
 INUnitValue.m
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

#import "INUnitValue.h"
#import "NSString+XML.h"

@implementation INUnitValue

@synthesize value, unit;


+ (NSString *)nodeType
{
	return @"indivo:ValueAndUnit";
}

- (BOOL)isNull
{
	return (!value && [unit length] < 1);
}

- (NSString *)xml
{
	if ([self isNull]) {
		return [NSString stringWithFormat:@"<%@ />", [self tagString]];
	}
#ifdef INDIVO_XML_PRETTY_FORMAT
	return [NSString stringWithFormat:@"<%@>%@%@\n</%@>",
			[self tagString],
			self.value ? [NSString stringWithFormat:@"\n\t<value>%@</value>", self.value] : @"",
			self.unit ? [NSString stringWithFormat:@"\n\t<unit>%@</unit>", [self.unit xmlSafe]] : @"",
			self.nodeName];
#else
	return [NSString stringWithFormat:@"<%@>%@%@</%@>",
			[self tagString],
			self.value ? [NSString stringWithFormat:@"<value>%@</value>", self.value] : @"",
			self.unit ? [NSString stringWithFormat:@"<unit>%@</unit>", [self.unit xmlSafe]] : @"",
			self.nodeName];
#endif
}


@end
