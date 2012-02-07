/*
 IndivoDemographics.m
 IndivoFramework
 
 Created by Indivo Class Generator on 2/6/2012.
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

#import "IndivoDemographics.h"


@implementation IndivoDemographics

@synthesize dateOfBirth, dateOfDeath, gender, ethnicity, language, maritalStatus, employmentStatus, employmentIndustry, occupation, religion, income, highestEducation, organDonor;


+ (NSString *)nodeName
{
	return @"Demographics";
}

+ (NSString *)nodeType
{
	return @"indivo:Demographics";
}

+ (NSDictionary *)propertyClassMapper
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"INDate", @"dateOfBirth",
			@"INDate", @"dateOfDeath",
			@"INString", @"gender",
			@"INString", @"ethnicity",
			@"INString", @"language",
			@"INString", @"maritalStatus",
			@"INString", @"employmentStatus",
			@"INString", @"employmentIndustry",
			@"INString", @"occupation",
			@"INString", @"religion",
			@"INString", @"income",
			@"INString", @"highestEducation",
			@"INBool", @"organDonor",
			nil];
}

+ (NSArray *)nonNilPropertyNames
{
	return [NSArray arrayWithObjects:nil, nil];
	/*
	static NSArray *nonNilPropertyNames = nil;
	if (!nonNilPropertyNames) {
		nonNilPropertyNames = [[NSArray alloc] initWithObjects:nil, nil];
	}
	
	return nonNilPropertyNames;	*/
}

+ (NSArray *)attributeNames
{
	NSArray *myAttributes = [NSArray arrayWithObjects:nil, nil];
	NSArray *superAttr = [super attributeNames];
	if (superAttr) {
		myAttributes = [superAttr arrayByAddingObjectsFromArray:myAttributes];
	}
	return myAttributes;
}


@end