/*
 IndivoMedication.m
 IndivoFramework
 
 Created by Indivo Class Generator on 6/17/2012.
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

#import "IndivoMedication.h"
#import "IndivoDocument.h"


@implementation IndivoMedication

@synthesize frequency, endDate, instructions, quantity, startDate, drugName, provenance;


+ (NSString *)nodeName
{
	return @"Medication";
}

+ (NSString *)nodeType
{
	return @"indivo:Medication";
}

+ (void)load
{
	[IndivoDocument registerDocumentClass:self];
}


+ (NSDictionary *)propertyClassMapper
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"INUnitValue", @"frequency",
			@"INDateTime", @"endDate",
			@"INString", @"instructions",
			@"INUnitValue", @"quantity",
			@"INDateTime", @"startDate",
			@"INCodedValue", @"drugName",
			@"INCodedValue", @"provenance",
			nil];
}


+ (NSArray *)nonNilPropertyNames
{
	return [NSArray arrayWithObjects:@"frequency", @"endDate", @"instructions", @"quantity", @"startDate", @"drugName", @"provenance", nil];
	/*
	static NSArray *nonNilPropertyNames = nil;
	if (!nonNilPropertyNames) {
		nonNilPropertyNames = [[NSArray alloc] initWithObjects:@"frequency", @"endDate", @"instructions", @"quantity", @"startDate", @"drugName", @"provenance", nil];
	}
	
	return nonNilPropertyNames;	*/
}



@end