/*
 IndivoSimpleClinicalNote.m
 IndivoFramework
 
 Created by Indivo Class Generator on 7/2/2012.
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

#import "IndivoSimpleClinicalNote.h"
#import "IndivoDocument.h"


@implementation IndivoSimpleClinicalNote

@synthesize visit_type_abbrev, visit_type_type, provider_name, visit_location, date_of_visit, finalized_at, visit_type_value, visit_type, specialty, specialty_value, signed_at, provider_institution, chief_complaint, specialty_type, specialty_abbrev, content;


+ (NSString *)nodeName
{
	return @"SimpleClinicalNote";
}

+ (NSString *)nodeType
{
	return @"indivo:SimpleClinicalNote";
}

+ (void)load
{
	[IndivoDocument registerDocumentClass:self];
}


+ (NSDictionary *)propertyClassMapper
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"INString", @"visit_type_abbrev",
			@"INString", @"visit_type_type",
			@"INString", @"provider_name",
			@"INString", @"visit_location",
			@"INDateTime", @"date_of_visit",
			@"INDateTime", @"finalized_at",
			@"INString", @"visit_type_value",
			@"INString", @"visit_type",
			@"INString", @"specialty",
			@"INString", @"specialty_value",
			@"INDateTime", @"signed_at",
			@"INString", @"provider_institution",
			@"INString", @"chief_complaint",
			@"INString", @"specialty_type",
			@"INString", @"specialty_abbrev",
			@"INString", @"content",
			nil];
}




@end