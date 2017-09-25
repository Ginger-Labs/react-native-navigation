//
//  SSWAnimator.h
//
//  Created by Arkadiusz Holko http://holko.pl on 29-05-14.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2014 Arkadiusz Holko <fastred@fastred.org>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <UIKit/UIKit.h>

// Undocumented animation curve used for the navigation controller's transition.
FOUNDATION_EXPORT UIViewAnimationOptions const SSWNavigationTransitionCurve;

@class SSWAnimator;

@protocol SSWAnimatorDelegate <NSObject>

@required
- (BOOL)animatorShouldAnimateTabBar:(SSWAnimator *)animator;
- (CGFloat)animatorTransitionDimAmount:(SSWAnimator *)animator;

@end

@interface SSWAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, weak) id<SSWAnimatorDelegate> delegate;

@end
