/*
 INQuantitativeResult.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 2/22/12.
 Copyright (c) 2011 Children's Hospital Boston
 
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

#import "INParentObject.h"
#import "INValueRange.h"
#import "INUnitValue.h"


/**
 *	A class representing the "QuantitativeResultField" dummy field
 */
@interface INQuantitativeResult : INParentObject

@property (nonatomic, strong) INValueRange *non_critical_range;			///< The non-critical range for this type of results
@property (nonatomic, strong) INValueRange *normal_range;				///< The normal range for this type of results
@property (nonatomic, strong) INUnitValue *value;						///< The value of the result

@end
