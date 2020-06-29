#import <UIKit/UIKit.h>
#import "RNNStackPresenter.h"
#import "UINavigationController+RNNOptions.h"
#import "UINavigationController+RNNCommands.h"
#import "UIViewController+LayoutProtocol.h"
#import "SSWAnimator.h"

@interface RNNStackController : UINavigationController <RNNLayoutProtocol, SSWAnimatorDelegate>

@property (nonatomic, retain) RNNStackPresenter* presenter;

@end
