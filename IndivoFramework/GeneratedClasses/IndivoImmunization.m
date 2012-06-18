/*
 IndivoImmunization.m
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

#import "IndivoImmunization.h"
#import "IndivoDocument.h"


@implementation IndivoImmunization

@synthesize product_class, date, administration_status, refusal_reason, product_class_2, product_name;


+ (NSString *)nodeName
{
	return @"Immunization";
}

+ (NSString *)nodeType
{
	return @"indivo:Immunization";
}

+ (void)load
{
	[IndivoDocument registerDocumentClass:self];
}


+ (NSDictionary *)propertyClassMapper
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"INCodedValue", @"product_class",
			@"INDateTime", @"date",
			@"INCodedValue", @"administration_status",
			@"INCodedValue", @"refusal_reason",
			@"INCodedValue", @"product_class_2",
			@"INCodedValue", @"product_name",
			nil];
}


+ (NSArray *)nonNilPropertyNames
{
	return [NSArray arrayWithObjects:@"product_class", @"date", @"administration_status", @"refusal_reason", @"product_class_2", @"product_name", nil];
	/*
	static NSArray *nonNilPropertyNames = nil;
	if (!nonNilPropertyNames) {
		nonNilPropertyNames = [[NSArray alloc] initWithObjects:@"product_class", @"date", @"administration_status", @"refusal_reason", @"product_class_2", @"product_name", nil];
	}
	
	return nonNilPropertyNames;	*/
}



@end