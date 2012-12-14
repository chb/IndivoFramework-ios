/*
 IndivoSimpleClinicalNote.h
 IndivoFramework
 
 Created by Indivo Class Generator on 7/2/2012.
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
 *	A class representing "indivo:SimpleClinicalNote" objects, generated from /indivo/data_models/core/simple_clinical_note/model.sdml.
 */
@interface IndivoSimpleClinicalNote : IndivoDocument

@property (nonatomic, strong) INString *visit_type_abbrev;
@property (nonatomic, strong) INString *visit_type_type;
@property (nonatomic, strong) INString *provider_name;
@property (nonatomic, strong) INString *visit_location;
@property (nonatomic, strong) INDateTime *date_of_visit;
@property (nonatomic, strong) INDateTime *finalized_at;
@property (nonatomic, strong) INString *visit_type_value;
@property (nonatomic, strong) INString *visit_type;
@property (nonatomic, strong) INString *specialty;
@property (nonatomic, strong) INString *specialty_value;
@property (nonatomic, strong) INDateTime *signed_at;
@property (nonatomic, strong) INString *provider_institution;
@property (nonatomic, strong) INString *chief_complaint;
@property (nonatomic, strong) INString *specialty_type;
@property (nonatomic, strong) INString *specialty_abbrev;
@property (nonatomic, strong) INString *content;


@end
