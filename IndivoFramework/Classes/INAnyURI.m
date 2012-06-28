/*
 INAnyURI.m
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

#import "INAnyURI.h"

@implementation INAnyURI

@synthesize uri;


+ (id)newWithURIString:(NSString *)aString
{
	INAnyURI *u = [self new];
	u.uri = aString;
	return u;
}

- (void)setFromNode:(INXMLNode *)node
{
	[super setFromNode:node];
	self.uri = node.text;
}

- (void)setWithAttr:(NSString *)attrName fromNode:(INXMLNode *)aNode
{
	self.uri = [aNode attr:attrName];
}


+ (NSString *)nodeType
{
	return @"xs:anyURI";
}

- (BOOL)isNull
{
	return ([uri length] < 1);
}

- (NSString *)innerXML
{
	return self.uri ? [self.uri xmlSafe] : @"";
}

- (NSString *)attributeValue
{
	return self.uri ? [self.uri xmlSafe] : @"";
}

- (NSArray *)flatXMLPartsWithPrefix:(NSString *)prefix
{
	NSString *xmlString = [NSString stringWithFormat:@"<Field name=\"%@\">%@</Field>", (prefix ? prefix : @"uri"), (self.uri ? [self.uri xmlSafe] : @"")];
	return [NSArray arrayWithObject:xmlString];
}


@end
