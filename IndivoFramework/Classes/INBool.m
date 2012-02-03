/*
 INBool.m
 IndivoFramework
 
 Created by Pascal Pfiffner on 10/17/11.
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

#import "INBool.h"

@implementation INBool

@synthesize flag;


+ (id)newYes
{
	INBool *b = [self new];
	b.flag = YES;
	return b;
}

+ (id)newNo
{
	INBool *b = [self new];
	b.flag = NO;
	return b;
}


- (void)setFromNode:(INXMLNode *)node
{
	[super setFromNode:node];
	self.flag = [node.text boolValue];
}

- (void)setWithAttr:(NSString *)attrName fromNode:(INXMLNode *)aNode
{
	self.flag = [aNode boolAttr:attrName];
}


+ (NSString *)nodeType
{
	return @"xs:boolean";
}

- (NSString *)xml
{
	return [NSString stringWithFormat:@"<%@>%@</%@>", self.nodeName, (self.flag ? @"true" : @"false"), self.nodeName];
}

- (NSString *)attributeValue
{
	return self.flag ? @"true" : @"false";
}


@end
