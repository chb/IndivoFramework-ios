/*
 IndivoProcedure.m
 IndivoFramework
 
 Created by Indivo Class Generator on 6/28/2012.
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

#import "IndivoProcedure.h"
#import "IndivoDocument.h"


@implementation IndivoProcedure

@synthesize location, name_value, provider_name, name_abbrev, comments, provider_institution, name_type, date_performed, name;


+ (NSString *)nodeName
{
	return @"Procedure";
}

+ (NSString *)nodeType
{
	return @"indivo:Procedure";
}

+ (void)load
{
	[IndivoDocument registerDocumentClass:self];
}


+ (NSDictionary *)propertyClassMapper
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"INString", @"location",
			@"INString", @"name_value",
			@"INString", @"provider_name",
			@"INString", @"name_abbrev",
			@"INString", @"comments",
			@"INString", @"provider_institution",
			@"INString", @"name_type",
			@"INDateTime", @"date_performed",
			@"INString", @"name",
			nil];
}




@end