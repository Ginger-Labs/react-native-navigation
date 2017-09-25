//
//  SloppySwiper.m
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

#import "SloppySwiper.h"
#import "SSWAnimator.h"
#import "SSWDirectionalPanGestureRecognizer.h"

@interface SloppySwiper() <UIGestureRecognizerDelegate, SSWAnimatorDelegate>
@property (weak, readwrite, nonatomic) UIPanGestureRecognizer *panRecognizer;
@property (weak, nonatomic) IBOutlet UINavigationController *navigationController;
@property (strong, nonatomic) SSWAnimator *animator;
@property (strong, nonatomic) UIPercentDrivenInteractiveTransition *interactionController;
/// A Boolean value that indicates whether the navigation controller is currently animating a push/pop operation.
@property (nonatomic) BOOL duringAnimation;
@end

@implementation RCCSloppySwiper

#pragma mark - Lifecycle

- (void)dealloc
{
    [_panRecognizer removeTarget:self action:@selector(pan:)];
    [_navigationController.view removeGestureRecognizer:_panRecognizer];
}

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController
{
    NSCParameterAssert(!!navigationController);

    self = [super init];
    if (self) {
        _navigationController = navigationController;
        [self commonInit];
    }

    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self commonInit];
}

- (void)commonInit
{
    SSWDirectionalPanGestureRecognizer *panRecognizer = [[SSWDirectionalPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    panRecognizer.direction = SSWPanDirectionRight;
    panRecognizer.maximumNumberOfTouches = 1;
    panRecognizer.delegate = self;
    [_navigationController.view addGestureRecognizer:panRecognizer];
    _panRecognizer = panRecognizer;

    _animator = [[SSWAnimator alloc] init];
    _animator.delegate = self;
}

#pragma mark - SSWAnimatorDelegate

- (BOOL)animatorShouldAnimateTabBar:(SSWAnimator *)animator {
    if ([self.delegate respondsToSelector:@selector(sloppySwiperShouldAnimateTabBar:)]) {
        return [self.delegate sloppySwiperShouldAnimateTabBar:self];
    } else {
        return YES;
    }
}

- (CGFloat)animatorTransitionDimAmount:(SSWAnimator *)animator {
    if ([self.delegate respondsToSelector:@selector(sloppySwiperTransitionDimAmount:)]) {
        return [self.delegate sloppySwiperTransitionDimAmount:self];
    } else {
        return 0.1f;
    }
}

#pragma mark - UIPanGestureRecognizer

- (void)pan:(UIPanGestureRecognizer*)recognizer
{
    UIView *view = self.navigationController.view;
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        if (self.navigationController.viewControllers.count > 1 && !self.duringAnimation) {
            self.interactionController = [[UIPercentDrivenInteractiveTransition alloc] init];
            self.interactionController.completionCurve = UIViewAnimationCurveEaseOut;

            [self.navigationController popViewControllerAnimated:YES];
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [recognizer translationInView:view];
        // Cumulative translation.x can be less than zero because user can pan slightly to the right and then back to the left.
        CGFloat d = translation.x > 0 ? translation.x / CGRectGetWidth(view.bounds) : 0;
        [self.interactionController updateInteractiveTransition:d];
    } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        if ([recognizer velocityInView:view].x > 0) {
            [self.interactionController finishInteractiveTransition];
        } else {
            [self.interactionController cancelInteractiveTransition];
            // When the transition is cancelled, `navigationController:didShowViewController:animated:` isn't called, so we have to maintain `duringAnimation`'s state here too.
            self.duringAnimation = NO;
        }
        self.interactionController = nil;
    }
}

#pragma mark - UIGestureRecognizerDelegate

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (self.navigationController.viewControllers.count > 1) {
        return YES;
    }
    return NO;
}

#pragma mark - UINavigationControllerDelegate

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
    if (operation == UINavigationControllerOperationPop) {
        return self.animator;
    }
    return nil;
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController
{
    return self.interactionController;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (animated) {
        self.duringAnimation = YES;
    }
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    self.duringAnimation = NO;
    
    if (navigationController.viewControllers.count <= 1) {
        self.panRecognizer.enabled = NO;
    }
    else {
        self.panRecognizer.enabled = YES;
    }
}

@end
