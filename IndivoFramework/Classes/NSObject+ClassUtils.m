/*
 NSObject+ClassUtils.m
 IndivoFramework
 
 Created by Pascal Pfiffner on 6/22/12.
 Copyright (c) 2012 Harvard Medical School
 
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

#import "NSObject+ClassUtils.h"

@implementation NSObject (ClassUtils)

@end


NSString *ivarNameFromIvar(Ivar ivar) {
	const char *ivar_name = ivar_getName(ivar);
	return [NSString stringWithCString:ivar_name encoding:NSUTF8StringEncoding];
}


/**
 *	Returns the name of the class, parsed from the name from the ivar.
 *	Ivar type encodings usually encode the class, if they are not of the privitive type, in the form "#{NSString}"
 */
Class classFromIvar(Ivar ivar) {
	const char *ivar_type = ivar_getTypeEncoding(ivar);
	NSString *ivarType = [NSString stringWithUTF8String:ivar_type];
	Class ivarClass = NULL;
	
	// is the type encoded?
	if ([ivarType length] > 3) {
		NSString *className = [ivarType substringWithRange:NSMakeRange(2, [ivarType length]-3)];
		ivarClass = NSClassFromString(className);
	}
	if (!ivarClass && 0 != strcmp("#", ivar_type)) {
		NSLog(@"WARNING: Class for ivar not loaded: \"%s\"", ivar_type);
	}
	
	return ivarClass;
}


