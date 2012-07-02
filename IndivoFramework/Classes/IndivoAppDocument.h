/*
 IndivoAppDocument.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 02/29/12.
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

#import "IndivoDocument.h"


/**
 *	An app- and optionally record specific document with any XML structure.
 *	This document holds one "tree" property, which is an INXMLNode. Work with this tree to add/change/remove data to the tree. Only the child nodes
 *	of the tree will make it into the document, so don't set attributes on "tree" itself, they will be ignored.
 *	Working with the tree directly is rather cumbersome, but gives you the most freedom.
 */
@interface IndivoAppDocument : IndivoDocument

@property (nonatomic, strong) INXMLNode *tree;

+ (id)newOnServer:(IndivoServer *)aServer;

- (void)delete:(INCancelErrorBlock)callback;


@end
