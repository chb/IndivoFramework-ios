/*
 IndivoAllergy.m
 IndivoFramework
 
 Created by Indivo Class Generator on 6/5/2012.
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

#import "IndivoAllergy.h"
#import "IndivoDocument.h"


@implementation IndivoAllergy

@synthesize category, allergic_reaction, drug_class_allergen, food_allergen, drug_allergen, severity;


+ (NSString *)nodeName
{
	return @"Allergy";
}

+ (NSString *)nodeType
{
	return @"indivo:Allergy";
}

+ (void)load
{
	[IndivoDocument registerDocumentClass:self];
}


+ (NSDictionary *)propertyClassMapper
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"INCodedValue", @"category",
			@"INCodedValue", @"allergic_reaction",
			@"INCodedValue", @"drug_class_allergen",
			@"INCodedValue", @"food_allergen",
			@"INCodedValue", @"drug_allergen",
			@"INCodedValue", @"severity",
			nil];
}


@end