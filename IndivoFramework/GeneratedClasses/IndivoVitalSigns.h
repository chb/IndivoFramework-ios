/*
 IndivoVitalSigns.h
 IndivoFramework
 
 Created by Indivo Class Generator on 6/5/2012.
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

@class IndivoEncounter;
	

/**
 *	A class representing "indivo:VitalSigns" objects, generated from /indivo/data_models/core/vitals/model.sdml.
 */
@interface IndivoVitalSigns : IndivoDocument

@property (nonatomic, strong) INVitalSign *heart_rate;
@property (nonatomic, strong) INVitalSign *height;
@property (nonatomic, strong) INVitalSign *respiratory_rate;
@property (nonatomic, strong) INVitalSign *weight;
@property (nonatomic, strong) IndivoEncounter *Encounter;
@property (nonatomic, strong) INDate *date;
@property (nonatomic, strong) INVitalSign *temperature;
@property (nonatomic, strong) INVitalSign *oxygen_saturation;
@property (nonatomic, strong) INVitalSign *bmi;
@property (nonatomic, strong) INBloodPressure *bp;


@end