//
//  SSWDirectionalPanGestureRecognizer.m
//
//  Created by Arkadiusz Holko http://holko.pl on 01-06-14.
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

#import "SSWDirectionalPanGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@interface SSWDirectionalPanGestureRecognizer()
@property (nonatomic) BOOL dragging;
@end

@implementation SSWDirectionalPanGestureRecognizer

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];

    if (self.state == UIGestureRecognizerStateFailed) return;

    CGPoint velocity = [self velocityInView:self.view];

    // check direction only on the first move
    if (!self.dragging && !CGPointEqualToPoint(velocity, CGPointZero)) {
        NSDictionary *velocities = @{
                                     @(SSWPanDirectionRight) : @(velocity.x),
                                     @(SSWPanDirectionDown) : @(velocity.y),
                                     @(SSWPanDirectionLeft) : @(-velocity.x),
                                     @(SSWPanDirectionUp) : @(-velocity.y)
                                     };
        NSArray *keysSorted = [velocities keysSortedByValueUsingSelector:@selector(compare:)];

        // Fails the gesture if the highest velocity isn't in the same direction as `direction` property.
        if ([[keysSorted lastObject] integerValue] != self.direction) {
            self.state = UIGestureRecognizerStateFailed;
        }

        self.dragging = YES;
    }
}

- (void)reset
{
    [super reset];

    self.dragging = NO;
}

@end
