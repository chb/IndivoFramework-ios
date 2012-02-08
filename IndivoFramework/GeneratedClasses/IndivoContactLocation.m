/*
 IndivoContactLocation.m
 IndivoFramework
 
 Created by Indivo Class Generator on 2/7/2012.
 Copyright (c) 2012 Children's Hospital Boston
 
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

#import "IndivoContactLocation.h"


@implementation IndivoContactLocation

@synthesize type, latitude, longitude;


+ (NSString *)nodeName
{
	return @"ContactLocation";
}

+ (NSString *)nodeType
{
	return @"indivo:ContactLocation";
}

+ (NSDictionary *)propertyClassMapper
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"INString", @"type",
			@"INString", @"latitude",
			@"INString", @"longitude",
			nil];
}



+ (NSArray *)attributeNames
{
	NSArray *myAttributes = [NSArray arrayWithObjects:@"type", nil];
	NSArray *superAttr = [super attributeNames];
	if (superAttr) {
		myAttributes = [superAttr arrayByAddingObjectsFromArray:myAttributes];
	}
	return myAttributes;
}


@end