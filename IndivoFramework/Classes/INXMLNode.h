/*
 INXMLNode.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 9/23/11.
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


/**
 *	A class to represent one node in an XML document
 */
@interface INXMLNode : NSObject

@property (nonatomic, assign) INXMLNode *parent;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSMutableDictionary *attributes;
@property (nonatomic, strong) NSMutableArray *children;
@property (nonatomic, copy) NSString *text;

+ (INXMLNode *)nodeWithName:(NSString *)aName;
+ (INXMLNode *)nodeWithName:(NSString *)aName attributes:(NSDictionary *)attributes;

// child nodes
- (void)addChild:(INXMLNode *)aNode;
- (INXMLNode *)firstChild;
- (INXMLNode *)childNamed:(NSString *)childName;
- (NSArray *)childrenNamed:(NSString *)childName;

- (BOOL)boolValue;

// attributes
- (id)attr:(NSString *)attributeName;
- (NSNumber *)numAttr:(NSString *)attributeName;
- (BOOL)boolAttr:(NSString *)attributeName;

- (void)setAttr:(NSString *)attrValue forKey:(NSString *)attrKey;

// getting XML back
- (NSString *)xml;
- (NSString *)childXML;


@end
