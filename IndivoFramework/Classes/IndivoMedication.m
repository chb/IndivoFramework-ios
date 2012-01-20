/*
 IndivoMedication.m
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

#import "IndivoMedication.h"
#import "IndivoRecord.h"
#import "INXMLNode.h"
#import "INObjects.h"

#import "INURLLoader.h"
#import "INXMLParser.h"
#import "IndivoConfig.h"

@implementation IndivoMedication

@synthesize dateStarted, dateStopped, reasonStopped;
@synthesize name, brandName;
@synthesize dose, route, strength, frequency;
@synthesize prescription, details;
@synthesize pillImage;


#pragma mark - Convenience Methods
/**
 *	Tries to find the best name to display, in this order:
 *		- brandName abbrev
 *		- brandName full
 *		- name abbrev
 *		- name full
 */
- (NSString *)displayName
{
	if ([brandName.abbrev length] > 0) {
		return brandName.abbrev;
	}
	if ([brandName.text length] > 0) {
		return brandName.text;
	}
	if ([name.abbrev length] > 0) {
		return name.abbrev;
	}
	return name.text;
}

/**
 *	Creates a string containing the medication's coded value's type, value and text (but not abbrev).
 *	@return A string or nil if the medication name is not coded
 */
- (NSString *)medicationCodedName
{
	if ([name.type length] > 0) {
		NSString *system = [@"http://rxnav.nlm.nih.gov/REST/rxcui/" isEqualToString:name.type] ? @"RxNorm" : name.type;
		NSString *ident = ([name.value length] > 0) ? name.value : @"?";
		NSString *desc = ([name.text length] > 0) ? name.text : @"unknown";
		return [NSString stringWithFormat:@"%@: %@ • %@", system, ident, desc];
	}
	return nil;
}

/**
 *	Creates a string containing the prescription's coded value's type, value and text (but not abbrev).
 *	@return A string or nil if the medication name is not coded
 */
- (NSString *)prescriptionCodedName
{
	if ([brandName.type length] > 0) {
		NSString *system = [@"http://rxnav.nlm.nih.gov/REST/rxcui/" isEqualToString:brandName.type] ? @"RxNorm" : brandName.type;
		NSString *ident = ([brandName.value length] > 0) ? brandName.value : @"?";
		NSString *desc = ([brandName.text length] > 0) ? brandName.text : @"unknown";
		return [NSString stringWithFormat:@"%@: %@ • %@", system, ident, desc];
	}
	return nil;
}


/**
 *	This method checks whether the passed name may refer to the receiver.
 *	Specifically, it is being checked whether:
 *		- aName is contained in brandName abbrev
 *		- aName is contained in brandName full
 *		- aName is contained in name abbrev
 *		- aName is contained in name full
 *	@param aName A string to check
 */
- (BOOL)matchesName:(NSString *)aName
{
	int options = NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch;
	if ([brandName.abbrev rangeOfString:aName options:options].location != NSNotFound) {
		return YES;
	}
	if ([brandName.text rangeOfString:aName options:options].location != NSNotFound) {
		return YES;
	}
	if ([name.abbrev rangeOfString:aName options:options].location != NSNotFound) {
		return YES;
	}
	return ([name.text rangeOfString:aName options:options].location != NSNotFound);
}



#pragma mark - Pill Image
/**
 *	This method tries to load an image of the medication, caching it automatically (once implemented)
 */
- (void)loadPillImageBypassingCache:(BOOL)bypass callback:(INCancelErrorBlock)callback
{
	/// @todo search in cache
	BOOL inCache = NO;
	if (!inCache || bypass) {
		NSString *apiKey = kPillboxAPIKey;			/// @attention You will need your personal API key for the server to respond
		
		// load all pills with our ingredient
		NSString *url = [NSString stringWithFormat:@"http://pillbox.nlm.nih.gov/PHP/pillboxAPIService.php?key=%@&ingredient=%@&has_image=1", apiKey, [name.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		
		DLog(@"->  %@", url);
		INURLLoader *loader = [INURLLoader loaderWithURL:[NSURL URLWithString:url]];
		[loader getWithCallback:^(BOOL userDidCancel, NSString *__autoreleasing errorMessage) {
			if (errorMessage) {
				CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, errorMessage)
			}
			else if (!userDidCancel) {
				
				// only try to parse XML
				if ([loader.responseString length] > 5 && [@"<?xml" isEqualToString:[loader.responseString substringToIndex:5]]) {
					NSError *error = nil;
					INXMLNode *root = [INXMLParser parseXML:loader.responseString error:&error];
					if (!root) {
						CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, [error localizedDescription])
					}
					
					// got pills matching the ingredient, find our rxcui
					else {
						NSString *want = name.value;
						NSMutableArray *found = [NSMutableArray array];
						NSArray *pills = [root childrenNamed:@"pill"];
						for (INXMLNode *pill in pills) {
							if ([want isEqualToString:[[pill childNamed:@"RXCUI"] text]]) {
								DLog(@"Image URL: http://pillbox.nlm.nih.gov/assets/small/%@sm.jpg", [[pill childNamed:@"image_id"] text]);
								[found addObject:pill];
							}
						}
						
						// found exact rxcui matches
						if ([found count] > 0) {
							for (INXMLNode *node in found) {
								NSString *imageId = [[node childNamed:@"image_id"] text];
								
								// has an image!
								if ([imageId length] > 0) {
									NSString *imgURL = [NSString stringWithFormat:@"http://pillbox.nlm.nih.gov/assets/small/%@sm.jpg", imageId];
									DLog(@"Image URL: %@", imgURL);
									
									INURLLoader *imgLoader = [INURLLoader loaderWithURL:[NSURL URLWithString:imgURL]];
									imgLoader.expectBinaryData = YES;
									[imgLoader getWithCallback:^(BOOL userDidCancel, NSString *__autoreleasing errorMessage) {
										if (!errorMessage && !userDidCancel) {
											self.pillImage = [UIImage imageWithData:imgLoader.responseData];
											
											/// @todo cache!!
										}
										CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, errorMessage)
									}];
									return;
								}
							}
						}
					}
				}		// end if (XML)
				
				CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, nil)
			}
		}];
	}
}



#pragma mark - IndivoDocument
+ (NSString *)nodeName
{
	return @"Medication";
}

+ (NSString *)type
{
	return @"Medication";
}

+ (NSString *)fetchReportPathForRecord:(IndivoRecord *)aRecord
{
	return [NSString stringWithFormat:@"/records/%@/reports/minimal/medications/", aRecord.udid];
}


@end
