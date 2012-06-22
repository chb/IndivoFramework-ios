/*
 INAddress.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 6/22/12.
 Copyright (c) 2012 Harvard Medical School. All rights reserved.
 
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


#import "INObjects.h"


/**
 *	A generic address object
 */
@interface INAddress : INObject

@property (nonatomic, strong) INString *country;
@property (nonatomic, strong) INString *city;
@property (nonatomic, strong) INString *postalCode;
@property (nonatomic, strong) INString *region;
@property (nonatomic, strong) INString *street;

@end
