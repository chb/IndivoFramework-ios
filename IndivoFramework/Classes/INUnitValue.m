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
#import "INCodedValue.h"
#import "NSString+XML.h"

@implementation INUnitValue

@synthesize value, textValue, unit;


- (void)setFromNode:(INXMLNode *)node
{
	[super setFromNode:node];
	
	NSString *valText = [[node childNamed:@"value"] text];
	if ([valText length] > 0) {
		self.value = [NSDecimalNumber decimalNumberWithString:valText];
	}
	self.textValue = [[node childNamed:@"textValue"] text];
	self.unit = [INCodedValue objectFromNode:[node childNamed:@"unit"]];
}

- (INCodedValue *)unit
{
	if (!unit) {
		self.unit = [INCodedValue newWithNodeName:@"unit"];
	}
	return unit;
}


+ (NSString *)nodeType
{
	return @"indivo:ValueAndUnit";
}

- (BOOL)isNull
{
	return (!value && [textValue length] < 1 && [unit isNull]);
}

- (NSString *)xml
{
	if ([self isNull]) {
		return [NSString stringWithFormat:@"<%@ />", [self tagString]];
	}
#ifdef INDIVO_XML_PRETTY_FORMAT
	return [NSString stringWithFormat:@"<%@>%@%@\n\t%@\n</%@>",
			[self tagString],
			self.value ? [NSString stringWithFormat:@"\n\t<value>%@</value>", self.value] : @"",
			self.textValue ? [NSString stringWithFormat:@"\n\t<textValue>%@</textValue>", [self.textValue xmlSafe]] : @"",
			[self.unit xml],
			self.nodeName];
#else
	return [NSString stringWithFormat:@"<%@>%@%@%@</%@>",
			[self tagString],
			self.value ? [NSString stringWithFormat:@"<value>%@</value>", self.value] : @"",
			self.textValue ? [NSString stringWithFormat:@"<textValue>%@</textValue>", [self.textValue xmlSafe]] : @"",
			[self.unit xml],
			self.nodeName];
#endif
}


@end
