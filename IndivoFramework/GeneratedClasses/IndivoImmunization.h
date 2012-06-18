/*
 IndivoImmunization.h
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

#import "IndivoDocument.h"
#import "INObjects.h"


	

/**
 *	A class representing "indivo:Immunization" objects, generated from /indivo/data_models/core/immunization/model.sdml.
 */
@interface IndivoImmunization : IndivoDocument

@property (nonatomic, strong) INCodedValue *product_class;
@property (nonatomic, strong) INDateTime *date;
@property (nonatomic, strong) INCodedValue *administration_status;
@property (nonatomic, strong) INCodedValue *refusal_reason;
@property (nonatomic, strong) INCodedValue *product_class_2;
@property (nonatomic, strong) INCodedValue *product_name;


@end