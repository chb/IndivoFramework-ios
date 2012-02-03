/*
 INDuration.m
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

#import "INDuration.h"

@implementation INDuration

@synthesize duration;


+ (id)newWithDuration:(NSString *)aDuration
{
	INDuration *d = [self new];
	d.duration = aDuration;
	return d;
}

- (void)setFromNode:(INXMLNode *)node
{
	[super setFromNode:node];
	self.duration = node.text;
}

- (void)setWithAttr:(NSString *)attrName fromNode:(INXMLNode *)aNode
{
	self.duration = [aNode attr:attrName];
}


+ (NSString *)nodeType
{
	return @"xs:duration";
}

- (BOOL)isNull
{
	return ([duration length] < 1);
}

- (NSString *)xml
{
	if ([self isNull]) {
		return @"";
	}
	return [NSString stringWithFormat:@"<%@>%@</%@>", [self tagString], (self.duration ? [self.duration xmlSafe] : @""), self.nodeName];
}

- (NSString *)attributeValue
{
	return self.duration ? [self.duration xmlSafe] : @"";
}


@end
