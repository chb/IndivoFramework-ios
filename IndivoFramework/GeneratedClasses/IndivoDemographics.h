/*
 IndivoDemographics.h
 IndivoFramework
 
 Created by Indivo Class Generator on 2/22/2012.
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


	

/**
 *	A class representing "indivo:Demographics" objects, generated from demographics.xsd.
 */
@interface IndivoDemographics : IndivoDocument

@property (nonatomic, strong) INDate *dateOfBirth;
@property (nonatomic, strong) INDate *dateOfDeath;
@property (nonatomic, strong) INString *gender;
@property (nonatomic, strong) NSArray *ethnicity;					///< An array containing INString objects
@property (nonatomic, strong) NSArray *language;					///< An array containing INString objects
@property (nonatomic, strong) INString *maritalStatus;
@property (nonatomic, strong) INString *employmentStatus;
@property (nonatomic, strong) INString *employmentIndustry;
@property (nonatomic, strong) INString *occupation;
@property (nonatomic, strong) INString *religion;
@property (nonatomic, strong) INString *income;
@property (nonatomic, strong) INString *highestEducation;
@property (nonatomic, strong) INBool *organDonor;


@end