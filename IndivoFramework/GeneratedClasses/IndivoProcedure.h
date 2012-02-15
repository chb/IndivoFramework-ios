/*
 IndivoProcedure.h
 IndivoFramework
 
 Created by Indivo Class Generator on 2/14/2012.
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

#import "IndivoDocument.h"
#import "INObjects.h"

@class IndivoProvider;
	

/**
 *	A class representing "indivo:Procedure" objects, generated from procedure.xsd.
 */
@interface IndivoProcedure : IndivoDocument

@property (nonatomic, strong) INDateTime *datePerformed;
@property (nonatomic, strong) INCodedValue *name;					///< minOccurs = 1
@property (nonatomic, strong) IndivoProvider *provider;
@property (nonatomic, strong) INString *location;
@property (nonatomic, strong) INString *comments;


@end