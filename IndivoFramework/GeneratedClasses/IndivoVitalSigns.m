/*
 IndivoVitalSigns.m
 IndivoFramework
 
 Created by Indivo Class Generator on 6/15/2012.
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

#import "IndivoVitalSigns.h"
#import "IndivoDocument.h"


@implementation IndivoVitalSigns

@synthesize heart_rate, height, respiratory_rate, weight, encounter, date, temperature, oxygen_saturation, bmi, bp;


+ (NSString *)nodeName
{
	return @"VitalSigns";
}

+ (NSString *)nodeType
{
	return @"indivo:VitalSigns";
}

+ (void)load
{
	[IndivoDocument registerDocumentClass:self];
}

+ (NSDictionary *)propertyClassMapper
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"INVitalSign", @"heart_rate",
			@"INVitalSign", @"height",
			@"INVitalSign", @"respiratory_rate",
			@"INVitalSign", @"weight",
			@"IndivoEncounter", @"encounter",
			@"INDateTime", @"date",
			@"INVitalSign", @"temperature",
			@"INVitalSign", @"oxygen_saturation",
			@"INVitalSign", @"bmi",
			@"INBloodPressure", @"bp",
			nil];
}


+ (NSArray *)nonNilPropertyNames
{
	return [NSArray arrayWithObjects:@"heart_rate", @"height", @"respiratory_rate", @"weight", @"encounter", @"date", @"temperature", @"oxygen_saturation", @"bmi", @"bp", nil];
	/*
	static NSArray *nonNilPropertyNames = nil;
	if (!nonNilPropertyNames) {
		nonNilPropertyNames = [[NSArray alloc] initWithObjects:@"heart_rate", @"height", @"respiratory_rate", @"weight", @"encounter", @"date", @"temperature", @"oxygen_saturation", @"bmi", @"bp", nil];
	}
	
	return nonNilPropertyNames;	*/
}



@end