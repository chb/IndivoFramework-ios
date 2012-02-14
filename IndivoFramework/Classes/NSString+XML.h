//
//  NSString+XML.h
//  IndivoFramework
//
//  Created by Pascal Pfiffner on 1/13/12.
//  Copyright (c) 2012 Harvard Medical School. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (XML)

- (NSString *)xmlSafe;
- (NSString *)numericString;

@end


@interface NSMutableString (XML)

- (void)xmlEscape;

@end
