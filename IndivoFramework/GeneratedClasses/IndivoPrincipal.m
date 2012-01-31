/*
 IndivoPrincipal.m
 IndivoFramework
 
 Created by Indivo Class Generator on 1/31/2012.
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

#import "IndivoPrincipal.h"


@implementation IndivoPrincipal

@synthesize type, fullname;


+ (NSString *)nodeName
{
	return @"Principal";
}

+ (NSString *)type
{
	return @"indivo:Principal";
}

+ (NSArray *)nonNilPropertyNames
{
	return [NSArray arrayWithObjects:@"type", @"fullname", nil];
	/*
	static NSArray *nonNilPropertyNames = nil;
	if (!nonNilPropertyNames) {
		nonNilPropertyNames = [[NSArray alloc] initWithObjects:@"type", @"fullname", nil];
	}
	
	return nonNilPropertyNames;	*/
}


@end