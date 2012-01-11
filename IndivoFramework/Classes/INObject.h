/*
 INObject.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 9/26/11.
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

#import <Foundation/Foundation.h>
#import "INXMLNode.h"
#import "Indivo.h"


/**
 *	An INObject is a lightweight object representing data in an XML tree. It knows how to read itself from and write
 *	itself to XML, but compared to INXMLNode has no idea about its parent structure.
 *	
 *	Subclasses should override -setFromNode: (to set their properties from an XML node+type (to return their respective
 *	type) and -xml (to return valid XML representations)
 */
@interface INObject : NSObject /*<NSCopying>*/

@property (nonatomic, copy) NSString *nodeName;						///< The object's nodeName
@property (nonatomic, copy) NSString *nodeType;						///< The type, e.g. "indivo:ValueAndUnit" or "xs:date"

+ (id)newWithNodeName:(NSString *)aNodeName;

- (id)initFromNode:(INXMLNode *)node;
+ (id)objectFromNode:(INXMLNode *)aNode forChildNamed:(NSString *)childName;
- (void)setFromNode:(INXMLNode *)node;

- (BOOL)isNull;
- (NSString *)xml;
- (NSString *)innerXML;

+ (NSString *)nodeName;
+ (NSString *)nodeType;


@end
