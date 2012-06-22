/*
 INString.m
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

#import "INString.h"

@implementation INString

@synthesize string;


+ (id)newWithString:(NSString *)aString
{
	INString *s = [self new];
	s.string = aString;
	return s;
}

- (void)setFromNode:(INXMLNode *)node
{
	[super setFromNode:node];
	self.string = node.text;
}

- (void)setWithAttr:(NSString *)attrName fromNode:(INXMLNode *)aNode
{
	self.string = [aNode attr:attrName];
}


+ (NSString *)nodeType
{
	return @"xs:string";
}

- (BOOL)isNull
{
	return ([string length] < 1);
}

- (NSString *)xml
{
	return [NSString stringWithFormat:@"<%@>%@</%@>", [self tagString], (self.string ? [self.string xmlSafe] : @""), self.nodeName];
}

- (NSString *)attributeValue
{
	return self.string ? [self.string xmlSafe] : @"";
}

- (NSArray *)flatXMLPartsWithPrefix:(NSString *)prefix
{
	NSString *xmlString = [NSString stringWithFormat:@"<Field name=\"%@\">%@</Field>", (prefix ? prefix : @"string"), (self.string ? [self.string xmlSafe] : @"")];
	return [NSArray arrayWithObject:xmlString];
}

- (void)setFromFlatParent:(INXMLNode *)parent prefix:(NSString *)prefix
{
	INXMLNode *myNode = nil;
	for (INXMLNode *child in [parent children]) {
		if ([prefix isEqualToString:[child attr:@"name"]]) {
			myNode = child;
			break;
		}
	}
	
	if (myNode) {
		self.string = myNode.text;
	}
}


@end
