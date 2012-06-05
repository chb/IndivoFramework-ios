/*
 IndivoDemographics+Special.m
 IndivoFramework
 
 Created by Pascal Pfiffner on 6/4/12.
 Copyright (c) 2012 Boston Children's Hospital
 
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

#import "IndivoDemographics+Special.h"


@implementation IndivoDemographics (Special)


/**
 *	Since this is a special document, we also need a different path to put it.
 */
- (NSString *)basePostPath
{
	if (self.record.uuid) {
		return [NSString stringWithFormat:@"/records/%@/demographics", self.record.uuid];
	}
	return nil;
}

/**
 *	When we push this document, it needs to be a PUT call because no new document gets created. We override the push: method, which maybe is not the cleanest
 *	way to achieve this...
 */
- (void)push:(INCancelErrorBlock)callback
{
	NSString *path = [self basePostPath];
	if (!path) {
		SUCCESS_RETVAL_CALLBACK_OR_LOG_ERR_STRING(callback, @"Can't push document because we're missing the record-id", 0)
		return;
	}
	
	NSString *xml = [self documentXML];
	//DLog(@"Pushing XML:  %@", xml);
	
	[self put:path
		 body:xml
	 callback:^(BOOL success, NSDictionary *userInfo) {
		  if (success) {
			  CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(callback, NO, userInfo)
			  POST_DOCUMENTS_DID_CHANGE_FOR_RECORD_NOTIFICATION(self.record)
		  }
		  else {
			  BOOL didCancel = NO;
			  if (![userInfo objectForKey:INErrorKey]) {
				  didCancel = YES;
			  }
			  else {
				  // we log the XML if push fails because most likely, it didn't validate, so here's your chance to take a look
				  DLog(@"PUSH FAILED BECAUSE %@:\n%@", [[userInfo objectForKey:INErrorKey] localizedDescription], xml);
			  }
			  CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(callback, didCancel, userInfo)
		  }
	  }];
}


@end
