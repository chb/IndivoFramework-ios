/*
 INObjects.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 1/30/12.
 Copyright (c) 2011 Children's Hospital Boston
 
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


/**
 *	@file IndivoDocuments.h
 *	This header file includes all our IndivoDocument subclasses. Include this header where you use these classes.
 */

#import "IndivoDocument.h"
#import "IndivoMetaDocument.h"
#import "IndivoAppDocument.h"

// Medication
#import "IndivoMedication+Report.h"
#import "IndivoFill.h"

// Allergy
#import "IndivoAllergy+Report.h"

// Immunization
#import "IndivoImmunization+Report.h"

// Clinical
#import "IndivoEncounter.h"
#import "IndivoProblem+Report.h"
#import "IndivoVitalSigns+Report.h"
#import "IndivoSimpleClinicalNote+Report.h"
#import "IndivoProcedure+Report.h"

// Labs
#import "IndivoLabResult.h"
#import "IndivoLabProvider.h"

// Results & Ranges
#import "IndivoResult.h"
#import "IndivoResultInRange.h"
#import "IndivoResultInSet.h"
#import "IndivoResultInSetOption.h"
#import "IndivoRange.h"

// Contact Data
#import "IndivoDemographics.h"
#import "INGenderType.h"
#import "INName.h"
#import "INPhoneType.h"
#import "INTelephone.h"

// Other
#import "IndivoAggregateReport.h"
#import "INQueryParameter.h"
#import "IndivoPrincipal.h"
#import "IndivoProvider.h"
#import "IndivoSignature.h"
#import "IndivoEquipment+Report.h"
#import "IndivoSchoolForm.h"


