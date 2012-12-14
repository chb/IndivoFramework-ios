/*
 IndivoMedication.h
 IndivoFramework
 
 Created by Indivo Class Generator on 6/22/2012.
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
 *	A class representing "indivo:Medication" objects, generated from /indivo/data_models/core/medication/model.sdml.
 */
@interface IndivoMedication : IndivoDocument

@property (nonatomic, strong) INUnitValue *frequency;
@property (nonatomic, strong) INDateTime *endDate;
@property (nonatomic, strong) INString *instructions;
@property (nonatomic, strong) INUnitValue *quantity;
@property (nonatomic, strong) INDateTime *startDate;
@property (nonatomic, strong) INCodedValue *drugName;
@property (nonatomic, strong) INCodedValue *provenance;
@property (nonatomic, strong) NSArray *fulfillments;


@end
