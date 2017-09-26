//  Portions of this file were copied from SloppySwiper by Arkadiusz Holko.
//  Attribution as follows:
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

#import "RCCAnimator.h"

UIViewAnimationOptions const RCCNavigationTransitionCurve = 7 << 16;


@implementation UIView (TransitionShadow)
- (void)addLeftSideShadowWithFading
{
    CGFloat shadowWidth = 4.0f;
    CGFloat shadowVerticalPadding = -20.0f; // negative padding, so the shadow isn't rounded near the top and the bottom
    CGFloat shadowHeight = CGRectGetHeight(self.frame) - 2 * shadowVerticalPadding;
    CGRect shadowRect = CGRectMake(-shadowWidth, shadowVerticalPadding, shadowWidth, shadowHeight);
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:shadowRect];
    self.layer.shadowPath = [shadowPath CGPath];
    self.layer.shadowOpacity = 0.2f;

    // fade shadow during transition
    CGFloat toValue = 0.0f;
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    animation.fromValue = @(self.layer.shadowOpacity);
    animation.toValue = @(toValue);
    [self.layer addAnimation:animation forKey:nil];
    self.layer.shadowOpacity = toValue;
}
@end


@interface RCCAnimator()
@property (weak, nonatomic) UIViewController *toViewController;
@end

@implementation RCCAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    // Approximated lengths of the default animations.
    return [transitionContext isInteractive] ? 0.25f : 0.5f;
}

// Tries to animate a pop transition similarly to the default iOS' pop transition.
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    [[transitionContext containerView] insertSubview:toViewController.view belowSubview:fromViewController.view];

    // parallax effect; the offset matches the one used in the pop animation in iOS 7.1
    CGFloat toViewControllerXTranslation = - CGRectGetWidth([transitionContext containerView].bounds) * 0.3f;
    toViewController.view.bounds = [transitionContext containerView].bounds;
    toViewController.view.center = [transitionContext containerView].center;
    toViewController.view.transform = CGAffineTransformMakeTranslation(toViewControllerXTranslation, 0);

    // add a shadow on the left side of the frontmost view controller
    [fromViewController.view addLeftSideShadowWithFading];
    BOOL previousClipsToBounds = fromViewController.view.clipsToBounds;
    fromViewController.view.clipsToBounds = NO;

    // in the default transition the view controller below is a little dimmer than the frontmost one
    UIView *dimmingView = [[UIView alloc] initWithFrame:toViewController.view.bounds];
    CGFloat dimAmount = 0.1f;
    dimmingView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:dimAmount];
    [toViewController.view addSubview:dimmingView];

    // fix hidesBottomBarWhenPushed not animated properly
    UITabBarController *tabBarController = toViewController.tabBarController;
    UINavigationController *navController = toViewController.navigationController;
    UITabBar *tabBar = tabBarController.tabBar;
    BOOL shouldAddTabBarBackToTabBarController = NO;

    BOOL tabBarControllerContainsToViewController = [tabBarController.viewControllers containsObject:toViewController];
    BOOL tabBarControllerContainsNavController = [tabBarController.viewControllers containsObject:navController];
    BOOL isToViewControllerFirstInNavController = [navController.viewControllers firstObject] == toViewController;
    BOOL shouldAnimateTabBar = YES;
    if (shouldAnimateTabBar && tabBar && (tabBarControllerContainsToViewController || (isToViewControllerFirstInNavController && tabBarControllerContainsNavController))) {
        [tabBar.layer removeAllAnimations];
        
        CGRect tabBarRect = tabBar.frame;
        tabBarRect.origin.x = toViewController.view.bounds.origin.x;
        tabBar.frame = tabBarRect;
        
        [toViewController.view addSubview:tabBar];
        shouldAddTabBarBackToTabBarController = YES;
    }

    // Uses linear curve for an interactive transition, so the view follows the finger. Otherwise, uses a navigation transition curve.
    UIViewAnimationOptions curveOption = [transitionContext isInteractive] ? UIViewAnimationOptionCurveLinear : RCCNavigationTransitionCurve;

    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:UIViewAnimationOptionTransitionNone | curveOption animations:^{
        toViewController.view.transform = CGAffineTransformIdentity;
        fromViewController.view.transform = CGAffineTransformMakeTranslation(toViewController.view.frame.size.width, 0);
        dimmingView.alpha = 0.0f;

    } completion:^(BOOL finished) {
        if (shouldAddTabBarBackToTabBarController) {
            [tabBarController.view addSubview:tabBar];
            
            CGRect tabBarRect = tabBar.frame;
            tabBarRect.origin.x = tabBarController.view.bounds.origin.x;
            tabBar.frame = tabBarRect;
        }

        [dimmingView removeFromSuperview];
        fromViewController.view.transform = CGAffineTransformIdentity;
        fromViewController.view.clipsToBounds = previousClipsToBounds;
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];

    self.toViewController = toViewController;
}

- (void)animationEnded:(BOOL)transitionCompleted
{
    // restore the toViewController's transform if the animation was cancelled
    if (!transitionCompleted) {
        self.toViewController.view.transform = CGAffineTransformIdentity;
    }
}

@end
