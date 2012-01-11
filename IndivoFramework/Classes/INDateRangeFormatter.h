/*
 IndivoConfig.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 12/8/11.
 Copyright (c) 2011 Harvard Medical School
 
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

#import <UIKit/UIKit.h>


/**
 *	This class tries to find the best display format for a date range
 */
@interface INDateRangeFormatter : UIViewController

@property (nonatomic, strong) NSDate *from;					///< The range start date, may be nil
@property (nonatomic, strong) NSDate *to;					///< The range end date, may be nil

@property (nonatomic, copy) NSString *sinceString;			///< Defaults to "Since", used if no "to" date is given
@property (nonatomic, copy) NSString *untilString;			///< Defaults to "Until", used if no "from" date is given

@property (nonatomic, strong) NSLocale *locale;				///< Defaults to current locale

+ (id)rangeFormatterFrom:(NSDate *)fromDate to:(NSDate *)toDate;

- (NSString *)formattedRange;
- (NSString *)formattedRangeForLabel:(UILabel *)aLabel;
- (NSString *)formattedRangeForMaxWidth:(CGFloat)maxWidth withFont:(UIFont *)aFont;


@end
