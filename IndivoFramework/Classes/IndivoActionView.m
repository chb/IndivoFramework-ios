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

#import "IndivoActionView.h"
#import <QuartzCore/QuartzCore.h>


@interface IndivoActionView ()

@property (nonatomic, strong) UIActivityIndicatorView *activityView;		//< The activity spinner
@property (nonatomic, strong) UILabel *mainLabel;							//< Main text label
@property (nonatomic, strong) UILabel *hintLabel;							//< Text below main text OR the spinner, a little more subtle

- (void)layoutSubviewsAnimated:(BOOL)animated;

@end


@implementation IndivoActionView

@synthesize activityView, mainLabel, hintLabel;


- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.opaque = NO;
		self.layer.opacity = 0.f;
		self.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.8f];
	}
	return self;
}



#pragma mark - Main Actions
/**
 *	Adds the view displaying a spinner
 */
- (void)showActivityIn:(UIView *)aParent animated:(BOOL)animated
{
	if (aParent != [self superview]) {
		self.frame = aParent.bounds;
		self.layer.opacity = 0.f;
		[aParent addSubview:self];
	}
	
	// fade in
	[UIView animateWithDuration:(animated ? 0.2 : 0.0)
					 animations:^{
						 self.layer.opacity = 1.f;
					 }
					 completion:^(BOOL finished) {
						 if (finished && [[self subviews] count] < 1) {
							 [self showSpinnerAnimated:animated];
						 }
					 }];
}

/**
 *	Adds the view with given main and hint text (both are optional)
 */
- (void)showIn:(UIView *)aParent mainText:(NSString *)mainText hintText:(NSString *)hintText animated:(BOOL)animated;
{
	if (aParent != [self superview]) {
		self.frame = aParent.bounds;
		self.layer.opacity = 0.f;
		[aParent addSubview:self];
	}
	
	// fade in
	[UIView animateWithDuration:(animated ? 0.2 : 0.0)
					 animations:^{
						 self.layer.opacity = 1.f;
						 
						 if ([mainText length] > 0) {
							 [self showMainText:mainText animated:NO];
						 }
						 if ([hintText length] > 0) {
							 [self showHintText:hintText animated:NO];
						 }
					 }];
}



#pragma mark - Changing Content
- (void)showSpinnerAnimated:(BOOL)animated
{
	if (self == [activityView superview]) {
		return;
	}
	
	[self hideMainTextAnimated:animated];
	
	[self addSubview:self.activityView];
	[activityView startAnimating];
	
	animateNextLayout = animateNextLayout || animated;
	[self setNeedsLayout];
}

- (void)hideSpinnerAnimated:(BOOL)animated
{
	[activityView stopAnimating];
	[activityView removeFromSuperview];
	
	animateNextLayout = animateNextLayout || animated;
	[self setNeedsLayout];
}

- (void)showMainText:(NSString *)mainText animated:(BOOL)animated
{
	if (self == [mainLabel superview]) {
		mainLabel.text = mainText;
		return;
	}
	
	[self hideSpinnerAnimated:animated];
	
	self.mainLabel.text = mainText;
	[self addSubview:mainLabel];
	
	animateNextLayout = animateNextLayout || animated;
	[self setNeedsLayout];
}

- (void)hideMainTextAnimated:(BOOL)animated
{
	[mainLabel removeFromSuperview];
	
	animateNextLayout = animateNextLayout || animated;
	[self setNeedsLayout];
}

- (void)showHintText:(NSString *)hintText animated:(BOOL)animated
{
	if (self == [hintLabel superview]) {
		hintLabel.text = hintText;
		return;
	}
	
	self.hintLabel.text = hintText;
	[self addSubview:hintLabel];
	
	animateNextLayout = animateNextLayout || animated;
	[self setNeedsLayout];
}

- (void)hideHintTextAnimated:(BOOL)animated
{
	[hintLabel removeFromSuperview];
	
	animateNextLayout = animateNextLayout || animated;
	[self setNeedsLayout];
}



#pragma mark - View Actions
- (void)layoutSubviews
{
	[self layoutSubviewsAnimated:animateNextLayout];
	animateNextLayout = NO;
}

- (void)layoutSubviewsAnimated:(BOOL)animated
{
	CGRect myBounds = self.bounds;
	CGSize maxSize = CGSizeMake(myBounds.size.width - 40.f, CGFLOAT_MAX);
	CGFloat padding = 8.f;
	
	BOOL setTop = NO;
	BOOL setHint = NO;
	UIView *topView = nil;
	CGRect topFrame = CGRectZero;			// either the frame of activityView or mainLabel
	CGRect hintFrame = CGRectZero;
	
	// has an activity view
	if (self == [activityView superview]) {
		setTop = YES;
		padding *= 2;
		topView = activityView;
		topFrame = activityView.frame;
	}
	
	// has a main text
	else if (self == [mainLabel superview]) {
		setTop = YES;
		topView = mainLabel;
		topFrame = mainLabel.frame;
		topFrame.size = [mainLabel.text sizeWithFont:mainLabel.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
	}
	
	// has the hint text
	if (self == [hintLabel superview]) {
		setHint = YES;
		hintFrame = hintLabel.frame;
		hintFrame.size = [hintLabel.text sizeWithFont:hintLabel.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
	}
	
	// distribute slightly above center
	CGFloat totalHeight = topFrame.size.height + hintFrame.size.height;
	if (topFrame.size.height > 0.f && hintFrame.size.height > 0.f) {
		totalHeight += padding;
	}
	
	CGFloat y = roundf(0.9 * (myBounds.size.height - totalHeight) / 2);
	
	// top view
	if (setTop) {
		BOOL dontAnimate = CGPointEqualToPoint(CGPointZero, topFrame.origin);
		CGFloat x = roundf((myBounds.size.width - topFrame.size.width) / 2);
		topFrame.origin.x = x;
		topFrame.origin.y = y;
		if (dontAnimate) {
			topView.frame = topFrame;
		}
		
		y += totalHeight - hintFrame.size.height;
	}
	
	// bottom view
	if (setHint) {
		BOOL dontAnimate = CGPointEqualToPoint(CGPointZero, hintFrame.origin);
		CGFloat x = roundf((myBounds.size.width - hintFrame.size.width) / 2);
		hintFrame.origin.x = x;
		hintFrame.origin.y = y;
		if (dontAnimate) {
			hintLabel.frame = hintFrame;
		}
	}
	
	// apply
	if (setTop || setHint) {
		[UIView animateWithDuration:(animated ? 0.2 : 0.0)
						 animations:^{
							 if (setTop) {
								 topView.frame = topFrame;
							 }
							 if (setHint) {
								 hintLabel.frame = hintFrame;
							 }
						 }];
	}
}



#pragma mark - KVC
- (UIActivityIndicatorView *)activityView
{
	if (!activityView) {
		self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	}
	return activityView;
}

- (UILabel *)mainLabel
{
	if (!mainLabel) {
		self.mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.f, 0.f, 320.f, 27.f)];
		mainLabel.opaque = NO;
		mainLabel.backgroundColor = [UIColor clearColor];
		mainLabel.numberOfLines = 0;
		mainLabel.textColor = [UIColor whiteColor];
		mainLabel.textAlignment = UITextAlignmentCenter;
		mainLabel.font = [UIFont systemFontOfSize:17.f];
		mainLabel.minimumFontSize = 10.f;
		mainLabel.adjustsFontSizeToFitWidth = YES;
	}
	return mainLabel;
}

- (UILabel *)hintLabel
{
	if (!hintLabel) {
		self.hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.f, 0.f, 320.f, 24.f)];
		hintLabel.opaque = NO;
		hintLabel.backgroundColor = [UIColor clearColor];
		hintLabel.numberOfLines = 0;
		hintLabel.textColor = [UIColor lightGrayColor];
		hintLabel.textAlignment = UITextAlignmentCenter;
		hintLabel.font = [UIFont systemFontOfSize:15.f];
		hintLabel.minimumFontSize = 10.f;
		hintLabel.adjustsFontSizeToFitWidth = YES;
	}
	return hintLabel;
}


@end
