//
//  KYDrawerController.m
//  KYDrawerController
//
//  Created by Yifei Zhou on 1/8/16.
//  Copyright © 2016 Yifei Zhou. All rights reserved.
//

#import "KYDrawerController.h"

static CGFloat const kContainerViewMaxAlpha = 0.2;
static NSTimeInterval const kDrawerAnimationDuration = 0.25;

@interface KYDrawerController () <UIGestureRecognizerDelegate>

@property (strong, nonatomic) NSLayoutConstraint *drawerConstraint;

@property (strong, nonatomic) NSLayoutConstraint *drawerWidthConstraint;

@property (assign, nonatomic) CGPoint panStartLocation;

@property (assign, nonatomic) CGFloat panDelta;

@property (strong, nonatomic) UIView *containerView;

@property (assign, nonatomic, getter=isScreenEdgePanGestreEnabled) BOOL screenEdgePanGestreEnabled;

@property (strong, nonatomic) UIScreenEdgePanGestureRecognizer *screenEdgePanGesture;

@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;

@end

@implementation KYDrawerController

@synthesize screenEdgePanGesture = _screenEdgePanGesture;
@synthesize panGesture = _panGesture;

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self _commonInit];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithDrawerDirection:(KYDrawerControllerDrawerDirection)drawerDirection drawerWidth:(CGFloat)drawerWidth
{
    self = [super init];
    if (self) {
        [self _commonInit];
        self.drawerDirection = drawerDirection;
        self.drawerWidth = drawerWidth;
    }
    return self;
}

- (void)_commonInit
{
    _drawerWidth = 280.0f;
    _screenEdgePanGestreEnabled = YES;
    _drawerDirection = KYDrawerControllerDrawerDirectionLeft;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSDictionary *viewDictionary = @{ @"_containerView" : self.containerView };

    [self.view addGestureRecognizer:self.screenEdgePanGesture];
    [self.view addGestureRecognizer:self.panGesture];
    [self.view addSubview:self.containerView];
    [self.view
        addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_containerView]-0-|" options:kNilOptions metrics:nil views:viewDictionary]];
    [self.view
        addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_containerView]-0-|" options:kNilOptions metrics:nil views:viewDictionary]];

    self.containerView.hidden = YES;
}

- (void)setDrawerState:(KYDrawerControllerDrawerState)drawerState animated:(BOOL)animated
{
    self.containerView.hidden = NO;

    NSTimeInterval duration = animated ? kDrawerAnimationDuration : 0;

    [UIView animateWithDuration:duration
        delay:0
        options:UIViewAnimationOptionCurveEaseOut
        animations:^{
          if (drawerState == KYDrawerControllerDrawerStateClosed) {
              self.drawerConstraint.constant = 0;
              self.containerView.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
          }
          else if (drawerState == KYDrawerControllerDrawerStateOpened) {
              CGFloat constant;
              if (self.drawerDirection == KYDrawerControllerDrawerDirectionLeft) {
                  constant = self.drawerWidth;
              }
              else if (self.drawerDirection == KYDrawerControllerDrawerDirectionRight) {
                  constant = -self.drawerWidth;
              }
              self.drawerConstraint.constant = constant;
              self.containerView.backgroundColor = [UIColor colorWithWhite:0 alpha:kContainerViewMaxAlpha];
              [self.containerView layoutIfNeeded];
          }
        }
        completion:^(BOOL finished) {
          if (drawerState == KYDrawerControllerDrawerStateClosed) {
              self.containerView.hidden = YES;
          }
          if ([self.delegate respondsToSelector:@selector(drawerController:stateDidChange:)]) {
              [self.delegate drawerController:self stateDidChange:drawerState];
          }
        }];
}

#pragma mark - Actions

- (IBAction)didTapContainerView:(id)sender
{
    [self setDrawerState:KYDrawerControllerDrawerStateClosed animated:YES];
}

- (IBAction)handlePanGesture:(id)sender
{
    self.containerView.hidden = NO;

    if (![sender isKindOfClass:[UIGestureRecognizer class]]) {
        return;
    }

    UIGestureRecognizer *gesture = sender;
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.panStartLocation = [gesture locationInView:self.view];
    }

    CGFloat delta = [gesture locationInView:self.view].x - self.panStartLocation.x;
    CGFloat constant;
    CGFloat backGroundAlpha;
    KYDrawerControllerDrawerState drawerState = KYDrawerControllerDrawerStateOpened;

    if (self.drawerDirection == KYDrawerControllerDrawerDirectionLeft) {
        drawerState = self.panDelta < 0 ? KYDrawerControllerDrawerStateClosed : KYDrawerControllerDrawerStateOpened;
        constant = fmin(self.drawerConstraint.constant + delta, self.drawerWidth);
        backGroundAlpha = fmin(kContainerViewMaxAlpha, kContainerViewMaxAlpha * fabs(constant) / self.drawerWidth);
    }
    else if (self.drawerDirection == KYDrawerControllerDrawerDirectionRight) {
        drawerState = self.panDelta > 0 ? KYDrawerControllerDrawerStateClosed : KYDrawerControllerDrawerStateOpened;
        constant = fmax(self.drawerConstraint.constant + delta, -self.drawerWidth);
        backGroundAlpha = fmin(kContainerViewMaxAlpha, kContainerViewMaxAlpha * fabs(constant) / self.drawerWidth);
    }

    self.drawerConstraint.constant = constant;
    self.containerView.backgroundColor = [UIColor colorWithWhite:0 alpha:backGroundAlpha];

    if (gesture.state == UIGestureRecognizerStateChanged) {
        self.panStartLocation = [gesture locationInView:self.view];
        self.panDelta = delta;
    }
    else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        [self setDrawerState:drawerState animated:YES];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer == self.panGesture) {
        return self.drawerState == KYDrawerControllerDrawerStateOpened;
    }
    else if (gestureRecognizer == self.screenEdgePanGesture) {
        return self.screenEdgePanGestreEnabled ? (self.drawerState == KYDrawerControllerDrawerStateClosed) : NO;
    }
    else {
        return touch.view == gestureRecognizer.view;
    }
}

#pragma mark - Getters & Setters

- (void)setMainViewController:(UIViewController *)mainViewController
{
    UIViewController *oldController = _mainViewController;

    {
        [oldController willMoveToParentViewController:nil];
        [oldController.view removeFromSuperview];
        [oldController removeFromParentViewController];
    }

    _mainViewController = mainViewController;

    if (!_mainViewController) {
        return;
    }

    _mainViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

    [self addChildViewController:_mainViewController];
    [self.view insertSubview:_mainViewController.view atIndex:0];

    NSDictionary *viewDictionary = @{ @"mainView" : _mainViewController.view };

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[mainView]-0-|" options:kNilOptions metrics:nil views:viewDictionary]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[mainView]-0-|" options:kNilOptions metrics:nil views:viewDictionary]];

    [_mainViewController didMoveToParentViewController:self];
}

- (void)setDrawerDirection:(KYDrawerControllerDrawerDirection)drawerDirection
{
    _drawerDirection = drawerDirection;

    if (_drawerDirection == KYDrawerControllerDrawerDirectionLeft) {
        self.screenEdgePanGesture.edges = UIRectEdgeLeft;
    }
    else if (_drawerDirection == KYDrawerControllerDrawerDirectionRight) {
        self.screenEdgePanGesture.edges = UIRectEdgeRight;
    }

    self.drawerViewController = _drawerViewController;
}

- (void)setDrawerViewController:(UIViewController *)drawerViewController
{
    UIViewController *oldController = _drawerViewController;

    {
        [oldController willMoveToParentViewController:nil];
        [oldController.view removeFromSuperview];
        [oldController removeFromParentViewController];
    }

    _drawerViewController = drawerViewController;

    if (!_drawerViewController) {
        return;
    }

    NSDictionary *viewDictionary = @{ @"drawerView" : _drawerViewController.view };

    NSLayoutAttribute itemAttribute;
    NSLayoutAttribute toItemAttribute;

    if (self.drawerDirection == KYDrawerControllerDrawerDirectionLeft) {
        itemAttribute = NSLayoutAttributeRight;
        toItemAttribute = NSLayoutAttributeLeft;
    }
    else if (self.drawerDirection == KYDrawerControllerDrawerDirectionRight) {
        itemAttribute = NSLayoutAttributeLeft;
        toItemAttribute = NSLayoutAttributeRight;
    }

    _drawerViewController.view.layer.shadowColor = [UIColor blackColor].CGColor;
    _drawerViewController.view.layer.shadowOpacity = 0.4f;
    _drawerViewController.view.layer.shadowRadius = 5.0f;
    _drawerViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

    [self addChildViewController:_drawerViewController];
    [self.containerView addSubview:_drawerViewController.view];

    self.drawerWidthConstraint = [NSLayoutConstraint constraintWithItem:_drawerViewController.view
                                                              attribute:NSLayoutAttributeWidth
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:nil
                                                              attribute:NSLayoutAttributeWidth
                                                             multiplier:1
                                                               constant:self.drawerWidth];

    [_drawerViewController.view addConstraint:self.drawerWidthConstraint];

    self.drawerConstraint = [NSLayoutConstraint constraintWithItem:_drawerViewController.view
                                                         attribute:itemAttribute
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.containerView
                                                         attribute:toItemAttribute
                                                        multiplier:1
                                                          constant:0];

    [self.containerView addConstraint:_drawerConstraint];
    [self.containerView
        addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[drawerView]-0-|" options:kNilOptions metrics:nil views:viewDictionary]];
    [self.containerView updateConstraints];

    [_drawerViewController updateViewConstraints];
    [_drawerViewController didMoveToParentViewController:self];
}

- (KYDrawerControllerDrawerState)drawerState
{
    return self.containerView.hidden ? KYDrawerControllerDrawerStateClosed : KYDrawerControllerDrawerStateOpened;
}

- (void)setDrawerState:(KYDrawerControllerDrawerState)drawerState
{
    [self setDrawerState:drawerState animated:NO];
}

- (void)setDrawerWidth:(CGFloat)drawerWidth
{
    _drawerWidth = drawerWidth;
    self.drawerWidthConstraint.constant = drawerWidth;
}

#pragma mark - Lazy initializer

- (UIView *)containerView
{
    if (!_containerView) {
        UIView *view = [[UIView alloc] initWithFrame:self.view.frame];

        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapContainerView:)];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.backgroundColor = [UIColor clearColor];
        [view addGestureRecognizer:tapGesture];
        tapGesture.delegate = self;

        _containerView = view;
    }
    return _containerView;
}

- (UIScreenEdgePanGestureRecognizer *)screenEdgePanGesture
{
    if (!_screenEdgePanGesture) {
        UIScreenEdgePanGestureRecognizer *gesture = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        if (self.drawerDirection == KYDrawerControllerDrawerDirectionLeft) {
            gesture.edges = UIRectEdgeLeft;
        }
        else if (self.drawerDirection == KYDrawerControllerDrawerDirectionRight) {
            gesture.edges = UIRectEdgeRight;
        }
        gesture.delegate = self;

        _screenEdgePanGesture = gesture;
    }
    return _screenEdgePanGesture;
}

- (UIPanGestureRecognizer *)panGesture
{
    if (!_panGesture) {
        UIPanGestureRecognizer *gesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        gesture.delegate = self;

        _panGesture = gesture;
    }
    return _panGesture;
}

@end
