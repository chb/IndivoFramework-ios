/*
 IndivoSingleResultLabTest.h
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

#import "IndivoLabTest.h"
#import "INObjects.h"

@class IndivoResult;
	

/**
 *	A class representing "indivo:SingleResultLabTest" objects, generated from lab.xsd.
 */
@interface IndivoSingleResultLabTest : IndivoLabTest

@property (nonatomic, strong) IndivoResult *result;					///< Must not be nil nor return YES on isNull (minOccurs = 1)


@end