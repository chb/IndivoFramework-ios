/*
 IndivoLabResult.m
 IndivoFramework
 
 Created by Indivo Class Generator on 6/26/2012.
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

#import "IndivoLabResult.h"
#import "IndivoDocument.h"


@implementation IndivoLabResult

@synthesize collected_at, collected_by_org, collected_by_name, narrative_result, notes, quantitative_result, collected_by_role, test_name, accession_number, abnormal_interpretation, status;


+ (NSString *)nodeName
{
	return @"LabResult";
}

+ (NSString *)nodeType
{
	return @"indivo:LabResult";
}

+ (void)load
{
	[IndivoDocument registerDocumentClass:self];
}


+ (NSDictionary *)propertyClassMapper
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"INDateTime", @"collected_at",
			@"INOrganization", @"collected_by_org",
			@"IndivoName", @"collected_by_name",
			@"INString", @"narrative_result",
			@"INString", @"notes",
			@"INQuantitativeResult", @"quantitative_result",
			@"INString", @"collected_by_role",
			@"INCodedValue", @"test_name",
			@"INString", @"accession_number",
			@"INCodedValue", @"abnormal_interpretation",
			@"INCodedValue", @"status",
			nil];
}




@end