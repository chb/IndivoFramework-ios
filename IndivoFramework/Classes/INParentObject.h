/*
 INParentObject.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 6/26/12.
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

#import "INObject.h"


/**
 *	This class is designed as abstract superclass for objects that have a few child elements.
 *	
 *	This class is designed as abstract superclass for objects that have a few child elements of simple type (NSString, NSDecimalNumber, ...) or INObject
 *	subclasses. The child elements can NOT be arrays. It extends INObject in that XML deserialization and serialization walk the instance's ivars and composes
 *	the XML automatically.
 */
@interface INParentObject : INObject

@end
