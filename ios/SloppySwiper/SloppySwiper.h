//
//  SloppySwiper.h
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

/**
 * `SloppySwiperDelegate` is a protocol for treaking the behavior of the
 * `SloppySwiper` object.
 */

@class SloppySwiper;

@protocol SloppySwiperDelegate <NSObject>

@optional
// Return NO when you don't want the TabBar to animate during swiping. (Default YES)
- (BOOL)sloppySwiperShouldAnimateTabBar:(SloppySwiper *)swiper;

// 0.0 means no dimming, 1.0 means pure black. Default is 0.1
- (CGFloat)sloppySwiperTransitionDimAmount:(SloppySwiper *)swiper;;

@end

/**
 *  `SloppySwiper` is a class conforming to `UINavigationControllerDelegate` protocol that allows pan back gesture to be started from anywhere on the screen (not only from the left edge).
 */
@interface SloppySwiper : NSObject <UINavigationControllerDelegate>

/// Gesture recognizer used to recognize swiping to the right.
@property (weak, readonly, nonatomic) UIPanGestureRecognizer *panRecognizer;

@property (nonatomic, weak) id<SloppySwiperDelegate> delegate;

/// Designated initializer if the class isn't used from the Interface Builder.
- (instancetype)initWithNavigationController:(UINavigationController *)navigationController;

@end
