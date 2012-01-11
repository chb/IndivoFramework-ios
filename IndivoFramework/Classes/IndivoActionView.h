/*
 IndivoActionView.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 12/5/11.
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

#import <UIKit/UIKit.h>


/**
 *	A semi-transparent view that can be overlaid over existing views and display text, a hint or a spinner
 */
@interface IndivoActionView : UIControl {
	BOOL animateNextLayout;
}

- (void)showActivityIn:(UIView *)aParent animated:(BOOL)animated;
- (void)showIn:(UIView *)aParent mainText:(NSString *)mainText hintText:(NSString *)hintText animated:(BOOL)animated;

- (void)showSpinnerAnimated:(BOOL)animated;
- (void)hideSpinnerAnimated:(BOOL)animated;
- (void)showMainText:(NSString *)mainText animated:(BOOL)animated;
- (void)hideMainTextAnimated:(BOOL)animated;
- (void)showHintText:(NSString *)hintText animated:(BOOL)animated;
- (void)hideHintTextAnimated:(BOOL)animated;


@end
