//
//  INSDMLParser.h
//  IndivoFramework
//
//  Created by Pascal Pfiffner on 6/5/12.
//  Copyright (c) 2012 Harvard Medical School. All rights reserved.
//

#import "INSchemaParser.h"

extern NSString *const INClassGeneratorSDMLModelnameKey;


/**
 *	Tries to create Obj-C classes from the Indivo-specific SDML files.
 *	
 *	SDML is an Indivo specific format to describe objects in a JSON-like fashion.
 */
@interface INSDMLParser : INSchemaParser

@end
