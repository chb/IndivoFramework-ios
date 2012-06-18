/*
 IndivoVitalSigns+Report.m
 IndivoFramework
 
 Created by Pascal Pfiffner on 2/15/12.
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

#import "IndivoVitalSigns+Report.h"


@implementation IndivoVitalSigns (Report)


+ (NSString *)reportType
{
	return @"VitalSigns";
}

+ (NSString *)reportTypeOfCategory:(NSString *)aCategory
{
	if ([aCategory length] > 0) {
		return [NSString stringWithFormat:@"%@/%@", [self reportType], aCategory];
	}
	return [self reportType];
}

+ (BOOL)useFlatXMLFormat
{
	return YES;
}


@end
