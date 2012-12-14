/*
 IndivoLabResult.h
 IndivoFramework
 
 Created by Indivo Class Generator on 6/26/2012.
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

@class INName;
	

/**
 *	A class representing "indivo:LabResult" objects, generated from /indivo/data_models/core/lab/model.sdml.
 */
@interface IndivoLabResult : IndivoDocument

@property (nonatomic, strong) INDateTime *collected_at;
@property (nonatomic, strong) INOrganization *collected_by_org;
@property (nonatomic, strong) INName *collected_by_name;
@property (nonatomic, strong) INString *narrative_result;
@property (nonatomic, strong) INString *notes;
@property (nonatomic, strong) INQuantitativeResult *quantitative_result;
@property (nonatomic, strong) INString *collected_by_role;
@property (nonatomic, strong) INCodedValue *test_name;
@property (nonatomic, strong) INString *accession_number;
@property (nonatomic, strong) INCodedValue *abnormal_interpretation;
@property (nonatomic, strong) INCodedValue *status;


@end
