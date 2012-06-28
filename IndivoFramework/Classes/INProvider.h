/*
 INProvider.h
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


#import "INParentObject.h"
#import "INAddress.h"
#import "INDate.h"
#import "INName.h"
#import "INTelephone.h"
#import "INNormalizedString.h"

@class INName;
@class INTelephone;


/**
 *	Representing a "Provider" dummy field
 */
@interface INProvider : INParentObject

@property (nonatomic, copy) NSString *dea_number;
@property (nonatomic, copy) NSString *ethnicity;
@property (nonatomic, copy) NSString *race;
@property (nonatomic, copy) NSString *npi_number;
@property (nonatomic, copy) NSString *preferred_language;
@property (nonatomic, strong) INAddress *adr;
@property (nonatomic, strong) INDate *bday;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, strong) INName *name;
@property (nonatomic, strong) INTelephone *tel_1;
@property (nonatomic, strong) INTelephone *tel_2;
@property (nonatomic, strong) INNormalizedString *gender;


@end
