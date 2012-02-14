/*
 IndivoImmunization.m
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

#import "IndivoImmunization.h"


@implementation IndivoImmunization

@synthesize dateAdministered, administeredBy, vaccine, sequence, anatomicSurface, adverseEvent;


+ (NSString *)nodeName
{
	return @"Immunization";
}

+ (NSString *)nodeType
{
	return @"indivo:Immunization";
}

+ (NSDictionary *)propertyClassMapper
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"INDateTime", @"dateAdministered",
			@"INString", @"administeredBy",
			@"IndivoImmunizationVaccine", @"vaccine",
			@"INInteger", @"sequence",
			@"INCodedValue", @"anatomicSurface",
			@"INString", @"adverseEvent",
			nil];
}


+ (NSArray *)nonNilPropertyNames
{
	return [NSArray arrayWithObjects:@"sequence", nil];
	/*
	static NSArray *nonNilPropertyNames = nil;
	if (!nonNilPropertyNames) {
		nonNilPropertyNames = [[NSArray alloc] initWithObjects:@"sequence", nil];
	}
	
	return nonNilPropertyNames;	*/
}



@end