/*
 IndivoDemographics.h
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

@class INName;
	

/**
 *	A class representing "indivo:Demographics" objects, generated from /indivo/schemas/data/core/demographics/schema.xsd.
 */
@interface IndivoDemographics : IndivoDocument

@property (nonatomic, strong) INDate *dateOfBirth;					///< minOccurs = 1
@property (nonatomic, strong) INGenderType *gender;					///< minOccurs = 1
@property (nonatomic, strong) INString *email;
@property (nonatomic, strong) INString *ethnicity;
@property (nonatomic, strong) INString *preferredLanguage;
@property (nonatomic, strong) INString *race;
@property (nonatomic, strong) INName *Name;					///< minOccurs = 1
@property (nonatomic, strong) NSArray *Telephone;					///< An array containing INTelephone objects
@property (nonatomic, strong) INAddress *Address;


@end
