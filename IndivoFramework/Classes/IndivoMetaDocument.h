/*
 IndivoMetaDocument.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 10/16/11.
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

#import "IndivoAbstractDocument.h"
#import "INObjects.h"

@class IndivoDocument;
@class IndivoPrincipal;


/**
 *	Represents metadata relating to a given IndivoDocument
 */
@interface IndivoMetaDocument : IndivoAbstractDocument

@property (nonatomic, readonly, strong) IndivoDocument *document;				///< The represented document
@property (nonatomic, assign) Class documentClass;								///< The class of document we represent. "IndivoDocument" by default

@property (nonatomic, readonly, copy) NSString *digest;							///< Metadata: Digest

@property (nonatomic, strong) INDate *createdAt;
@property (nonatomic, strong) IndivoPrincipal *creator;
@property (nonatomic, strong) INDate *suppressedAt;
@property (nonatomic, strong) IndivoPrincipal *suppressor;
@property (nonatomic, strong) INAttr *replacedBy;
@property (nonatomic, strong) INAttr *replaces;
@property (nonatomic, strong) INAttr *original;
@property (nonatomic, strong) INAttr *latest;
@property (nonatomic, strong) INString *status;
@property (nonatomic, strong) INBool *nevershare;
//@property (nonatomic, strong) INRelation *relatesTo;
//@property (nonatomic, strong) INRelation *isRelatedFrom;

- (id)initFromNode:(INXMLNode *)node forRecord:(IndivoRecord *)aRecord representingClass:(Class)aClass;


@end
